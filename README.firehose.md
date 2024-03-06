## Local Build

First ensure you have the Git submodules properly checked out and initialized:

```bash
git submodule update --init --recursive
```

Then install some required dependencies:

- `rust`
- `cbindgen` (`brew install cbindgen` or see https://github.com/mozilla/cbindgen)
- `Node.js` (unsure minimum version, at time of writing version 20 was working)
- `yarn`

Then ensure you are using Golang 1.20 exactly, newer don't work just yet:

```bash
brew install golang1.20
export PATH="/opt/homebrew/opt/go@1.20/bin:$PATH"
```

Then use their makefile since it performs a bunch of code generation:

```bash
# We use `make build` since it seems `make` alone fails on my system at least
make build
```

## Docker Build

GitHub Actions have a hard time building Arbitrum Nitro, manually build of images can be performed with:

```bash
TAG=v2.3.0-fh1
docker build --platform linux/amd64 --label org.opencontainers.image.version=nitro-$TAG -t ghcr.io/streamingfast/nitro:latest -t ghcr.io/streamingfast/nitro:$TAG --push .
```
