# Cardano node build

Build your own cardano node image

```bash
# Build
docker build -t cardano-node:<tag> -f Dockerfile .

docker build --build-arg git_tag='tags/1.35.3' -t cardano-node:1.35.3 -f Dockerfile .

# Run
docker run -e NETWORK=preview -it cardano-node:<tag>

```

### Refrences:
- https://github.com/input-output-hk/cardano-node/blob/master/doc/getting-started/install.md/
- https://developers.cardano.org/docs/get-started/installing-cardano-node/
- https://www.coincashew.com/coins/overview-ada/guide-how-to-build-a-haskell-stakepool-node