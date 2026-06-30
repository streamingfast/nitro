#!/usr/bin/env bash
#
# clean-repo.sh — reset the working tree and all submodules to a pristine,
# in-sync state.
#
# Does:
#   git submodule sync   --recursive            # refresh submodule URLs
#   git submodule update --init --recursive --force   # pin every submodule to its recorded commit
#   git clean -ffd                              # drop untracked files/dirs (super-project)
#   git submodule foreach --recursive 'git clean -ffd'  # ... and inside every submodule
#
# DESTRUCTIVE: discards uncommitted changes and untracked files everywhere.
# Notably this removes the foundry lint fix in contracts/foundry.toml — that's
# expected; build-on-mac.sh re-applies it on the next build.
#
# The helper scripts themselves (build-on-mac.sh, clean-repo.sh) are preserved
# even while untracked, so cleaning never deletes your way back in.
#
# Usage:
#   ./clean-repo.sh            # interactive confirm
#   ./clean-repo.sh --yes      # no prompt (CI / non-tty)
#   ./clean-repo.sh --dry-run  # show what would be removed, change nothing
#   ./clean-repo.sh --deep     # also remove git-ignored files (target/, node_modules, .make/ ...)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

c_red=$'\033[0;31m'; c_grn=$'\033[0;32m'; c_yel=$'\033[0;33m'; c_rst=$'\033[0m'
info() { printf "%s==>%s %s\n" "$c_grn" "$c_rst" "$*"; }
warn() { printf "%s!! %s%s\n" "$c_yel" "$*" "$c_rst"; }
die()  { printf "%sxx %s%s\n" "$c_red" "$*" "$c_rst" >&2; exit 1; }

ASSUME_YES=0; DRY_RUN=0; DEEP=0
for a in "$@"; do
  case "$a" in
    -y|--yes)     ASSUME_YES=1 ;;
    -n|--dry-run) DRY_RUN=1 ;;
    -x|--deep)    DEEP=1 ;;
    -h|--help)    grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown arg: $a (try --help)" ;;
  esac
done

[ -d .git ] || git rev-parse --git-dir >/dev/null 2>&1 || die "not a git repo"

# Untracked helper scripts to keep even when not yet committed.
KEEP=( -e build-on-mac.sh -e clean-repo.sh )

# Flags for git clean: -ff (force, incl. nested git dirs), -d (dirs).
# -x additionally removes ignored files (deep clean).
CLEAN_FLAGS=( -ff -d )
[ "$DEEP" = "1" ] && CLEAN_FLAGS+=( -x )
[ "$DRY_RUN" = "1" ] && CLEAN_FLAGS+=( -n )

if [ "$DRY_RUN" = "1" ]; then
  info "DRY RUN — nothing will be modified"
  info "super-project would remove:"
  git clean "${CLEAN_FLAGS[@]}" "${KEEP[@]}" || true
  info "submodules would remove:"
  git submodule foreach --recursive "git clean ${CLEAN_FLAGS[*]} || true" || true
  exit 0
fi

warn "this DISCARDS all uncommitted changes and untracked files in the repo and ALL submodules."
[ "$DEEP" = "1" ] && warn "--deep: will ALSO remove git-ignored files (target/, node_modules, caches) — full rebuild after."
if [ "$ASSUME_YES" != "1" ] && [ -t 0 ]; then
  read -r -p "proceed? [y/N] " a
  case "$a" in y|Y|yes|YES) ;; *) die "aborted" ;; esac
fi

info "git submodule sync --recursive"
git submodule sync --recursive

info "git submodule update --init --recursive --force"
git submodule update --init --recursive --force

info "git clean (super-project)"
git clean "${CLEAN_FLAGS[@]}" "${KEEP[@]}"

info "git clean (submodules, recursive)"
git submodule foreach --recursive "git clean ${CLEAN_FLAGS[*]}"

# Re-pin submodule working trees in case the clean above touched checked-out
# files (e.g. generated ABIs) — leaves every submodule exactly at its commit.
info "git submodule update --force (final re-pin)"
git submodule update --recursive --force

echo
info "clean. working tree matches HEAD and every submodule is at its pinned commit."
warn "the contracts/foundry.toml lint fix was reset — build-on-mac.sh re-applies it on next build."
git status --short || true
