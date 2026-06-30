#!/usr/bin/env bash
#
# build-on-mac.sh — build nitro on macOS (Apple Silicon / Intel).
#
# Handles the two macOS friction points:
#   1. Go toolchain: this branch's go.mod pins an old Go (e.g. 1.20) that a
#      modern system Go (1.24+) refuses to build ("updates to go.mod needed").
#      This script fetches the exact pinned Go into ~/sdk and builds with it,
#      asking for confirmation first.
#   2. Foundry's solar linter rejects the Yul `object {}` syntax during
#      `forge build`, breaking `make build`. We ensure lint-on-build is off in
#      contracts/foundry.toml (a submodule file; `git submodule update` resets
#      it, so this guard is idempotent and re-applies it each run).
#
# Note: the matching fix in solgen/gen.go (skipping foundry build-info JSON)
# lives in the main repo and is assumed already committed on this branch.
#
# Usage:
#   ./build-on-mac.sh           # interactive
#   ./build-on-mac.sh --yes     # assume yes to all prompts (CI / non-tty)
#   GO_VERSION=1.20.14 ./build-on-mac.sh   # override pinned patch version

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

ASSUME_YES=0
[ "${1:-}" = "--yes" ] || [ "${1:-}" = "-y" ] && ASSUME_YES=1

c_red=$'\033[0;31m'; c_grn=$'\033[0;32m'; c_yel=$'\033[0;33m'; c_rst=$'\033[0m'
info()  { printf "%s==>%s %s\n" "$c_grn" "$c_rst" "$*"; }
warn()  { printf "%s!! %s%s\n" "$c_yel" "$*" "$c_rst"; }
die()   { printf "%sxx %s%s\n" "$c_red" "$*" "$c_rst" >&2; exit 1; }

ask() { # ask "question" -> returns 0 for yes
  local q="$1"
  if [ "$ASSUME_YES" = "1" ] || [ ! -t 0 ]; then return 0; fi
  local a; read -r -p "$q [Y/n] " a
  case "$a" in n|N|no|NO) return 1;; *) return 0;; esac
}

# --- 0. sanity --------------------------------------------------------------
[ "$(uname -s)" = "Darwin" ] || die "this script is for macOS only"
case "$(uname -m)" in
  arm64)  GOARCH=arm64 ;;
  x86_64) GOARCH=amd64 ;;
  *) die "unsupported arch $(uname -m)" ;;
esac

# --- 1. preflight: non-Go build deps ---------------------------------------
missing=()
for t in cargo rustup forge yarn node cmake; do
  command -v "$t" >/dev/null 2>&1 || missing+=("$t")
done
if [ "${#missing[@]}" -gt 0 ]; then
  warn "missing build tools: ${missing[*]}"
  warn "install them first (brew install cmake yarn node; rustup-init; foundryup), then re-run."
  ask "continue anyway?" || exit 1
fi

# --- 2. determine required Go version ---------------------------------------
GO_MM="$(awk '/^go [0-9]+\.[0-9]+/ {print $2; exit}' go.mod)"   # e.g. 1.20
[ -n "$GO_MM" ] || die "could not read 'go' directive from go.mod"

# Pinned patch release. Default tracks the go.mod minor; override via env.
case "$GO_MM" in
  1.20) DEFAULT_PATCH=1.20.14 ;;
  1.21) DEFAULT_PATCH=1.21.13 ;;
  1.22) DEFAULT_PATCH=1.22.12 ;;
  1.23) DEFAULT_PATCH=1.23.12 ;;
  *)    DEFAULT_PATCH="${GO_MM}.0" ;;
esac
GO_VERSION="${GO_VERSION:-$DEFAULT_PATCH}"

info "go.mod requires Go $GO_MM — will build with Go $GO_VERSION (darwin-$GOARCH)"
ask "proceed with Go $GO_VERSION?" || die "aborted by user"

# --- 3. ensure the toolchain is available ----------------------------------
SDK_DIR="$HOME/sdk/go${GO_VERSION}"
GO_BIN="$SDK_DIR/bin/go"

if [ -x "$GO_BIN" ]; then
  info "found existing toolchain at $SDK_DIR"
else
  TARBALL="go${GO_VERSION}.darwin-${GOARCH}.tar.gz"
  URL="https://go.dev/dl/${TARBALL}"
  info "Go $GO_VERSION not installed."
  ask "download $URL into ~/sdk?" || die "aborted: cannot build without Go $GO_VERSION"
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  info "downloading $URL ..."
  curl -fL --progress-bar "$URL" -o "$tmp/$TARBALL" || die "download failed"
  info "extracting to $SDK_DIR ..."
  mkdir -p "$SDK_DIR"
  tar -C "$tmp" -xzf "$tmp/$TARBALL"
  # tarball unpacks to ./go ; move its contents into SDK_DIR
  rm -rf "$SDK_DIR"
  mv "$tmp/go" "$SDK_DIR"
  [ -x "$GO_BIN" ] || die "extraction did not produce $GO_BIN"
fi

GOT_VER="$("$GO_BIN" version | awk '{print $3}')"   # e.g. go1.20.14
info "using $GOT_VER"
[ "$GOT_VER" = "go${GO_VERSION}" ] || warn "version mismatch: wanted go${GO_VERSION}, got $GOT_VER"

# --- 4. ensure foundry lint-on-build is disabled (submodule guard) ---------
FOUNDRY_TOML="contracts/foundry.toml"
if [ -f "$FOUNDRY_TOML" ] && ! grep -q "lint_on_build" "$FOUNDRY_TOML"; then
  info "disabling foundry solar lint in $FOUNDRY_TOML"
  printf '\n[lint]\nlint_on_build = false\n' >> "$FOUNDRY_TOML"
fi

# --- 5. build ---------------------------------------------------------------
# GOTOOLCHAIN=local pins the on-PATH Go so it does not try to switch versions.
export PATH="$SDK_DIR/bin:$PATH"
export GOTOOLCHAIN=local

info "running: make build"
make build

# --- 6. verify --------------------------------------------------------------
if [ -x target/bin/nitro ]; then
  info "build OK"
  target/bin/nitro --version || true
  echo
  info "binaries in: $REPO_ROOT/target/bin"
  warn "to rebuild manually: PATH=\"$SDK_DIR/bin:\$PATH\" GOTOOLCHAIN=local make build"
else
  die "build finished but target/bin/nitro is missing"
fi
