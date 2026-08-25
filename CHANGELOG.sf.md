## Unreleased

## v3.11.2-fh3.0-3

* Pinned `firehose-ethereum` to [v2.21.0](https://github.com/streamingfast/firehose-ethereum/releases/tag/v2.21.0), which brings the `--common-merged-blocks-bundle-size` flag.
* Fixed the Docker build failing with `forge: No such file or directory`: the Foundry installer no longer adds its bin directory to `~/.bashrc`, so the `contracts-builder` stage now sets `PATH` itself.
* Added `linux/arm64` support: the published Docker image is now a multi-arch manifest covering `linux/amd64` and `linux/arm64`, and releases ship a `nitro_linux_arm64` binary alongside `nitro_linux_amd64`.
* Changed the Firehose Ethereum base image to be pinned by digest for the whole build, so both architectures in a manifest are guaranteed to embed the same `firehose-ethereum` build.
* Removed the `<version>-fireeth-<fireeth version>` image tag. Releases are identified by their version alone, e.g. `v3.11.2-fh3.0`.
* Fixed the bare commit-sha image tag being published by both the branch run and the tag run when a tag is pushed on a `release/*` branch head, where whichever finished last silently won. Only branch builds publish it now.

## v3.11.2-fh3.0

* Bumped to [3.11.2](https://github.com/OffchainLabs/nitro/releases/tag/v3.11.2).
    * Also contains [3.11.1](https://github.com/OffchainLabs/nitro/releases/tag/v3.11.1).
* `go-ethereum` unchanged at [arbitrum-v3.11.1-fh-2](https://github.com/streamingfast/go-ethereum/tree/arbitrum-v3.11.1-fh-2): upstream nitro keeps the same go-ethereum revision between v3.11.1 and v3.11.2, and no firehose change is required.

## v3.11.0-fh3.0

* Bumped to [3.11.0](https://github.com/OffchainLabs/nitro/releases/tag/v3.11.0).
    * Also contains [3.10.0](https://github.com/OffchainLabs/nitro/releases/tag/v3.10.0) and [3.10.1](https://github.com/OffchainLabs/nitro/releases/tag/v3.10.1).
* Updated `go-ethereum` to [arbitrum-v3.11.0-fh-1](https://github.com/streamingfast/go-ethereum/tree/arbitrum-v3.11.0-fh-1).

## v3.9.3-fh3.0

* Bumped to [3.9.3](https://github.com/OffchainLabs/nitro/releases/tag/v3.9.3).

## v3.9.1-fh3.0

* Bumped to [3.9.1](https://github.com/OffchainLabs/nitro/releases/tag/v3.9.1).

## v3.8.0-fh3.0

* Bumped to [3.8.0](https://github.com/OffchainLabs/nitro/releases/tag/v3.8.0).

## v3.7.6-fh3.0

* Bumped to [3.7.6](https://github.com/OffchainLabs/nitro/releases/tag/v3.7.6).
    * Also contains [3.7.5](https://github.com/OffchainLabs/nitro/releases/tag/v3.7.5).

## v3.7.4-fh3.0

* Bumped to [3.7.4](https://github.com/OffchainLabs/nitro/releases/tag/v3.7.4) leveraging native live tracer now built in in `nitro` codebase directly.

## v3.7.3-fh3.0-5

* This is a re-release of 3.7.3 with build and release notes fixes

### v3.7.3

* Bumped to [3.7.3](https://github.com/OffchainLabs/nitro/releases/tag/v3.7.3).