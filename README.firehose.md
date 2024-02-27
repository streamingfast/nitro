# If github fails with 'out of disk space', simply build like this:

```
TAG=v2.3.0-fh1
docker buildx build --platform linux/amd64 --label org.opencontainers.image.version=nitro-$TAG -t ghcr.io/streamingfast/nitro:latest -t ghcr.io/streamingfast/nitro:$TAG .
docker push ghcr.io/streamingfast/nitro:latest
docker push ghcr.io/streamingfast/nitro:$TAG
```
