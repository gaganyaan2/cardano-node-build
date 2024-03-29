# Cardano node build

Build your own cardano node image

```bash
# Build
git clone https://github.com/koolwithk/cardano-node-build.git

cd cardano-node-build

docker build --build-arg git_commit_id='tags/1.35.5' -t cardano-node:<tag> -f Dockerfile .
#update git_commit_id and tag as per your requirement.

# Run
docker run -e NETWORK=preview -it cardano-node:<tag>

# Use already build image
docker run -e NETWORK=preview -it koolwithk/cardano-node:1.35.5

```

### Run using docker compose

```bash
NETWORK=preview docker-compose -f cardano-compose.yml up -d
```

## Cardano node docker image build on Raspberry pi 4

### Prerequisite
- Raspberry pi 4 with 8GB RAM + 8GB SWAP
- 40GB free space (32 GB card won't work)
- Build time around 11 hours

1. Create 8GB of temporary SWAP memory as cardano-node require more than 8GB Memory. It kind of makes total 16GB of RAM but extra 8 GB RAM are very slow.

```bash
dd if=/dev/zero of=/swapfile bs=4096 count=2048k
mkswap /swapfile
chmod 600 /swapfile
swapon /swapfile
sysctl vm.swappiness=60

# Make swap permanent
echo "/swapfile swap swap defaults 0 0" >>  /etc/fstab
```

### Build arm64 cardano-node docker image

```bash
# Build
git clone https://github.com/koolwithk/cardano-node-build.git

cd cardano-node-build

docker build -t cardano-node:<tag> -f arm64.Dockerfile .

docker build --build-arg git_commit_id='tags/1.35.5' -t cardano-node:<tag> -f arm64.Dockerfile .
#update git_commit_id and tag as per your requirement.

# Run
docker run -e NETWORK=preview -it cardano-node:<tag>

# Use already build image
docker run -e NETWORK=preview -it koolwithk/cardano-node:1.35.5-arm64

```
**Note :** It took around 11 Hours to build the cardano-node image on Raspberry pi4.

If we do not add 8GB swap it will fail at **test:tx-generator-test** with not enough memory available error

```bash
test:tx-generator-test from tx-generator-2.2, exe:tx-generator from
tx-generator-2.2 and others). The build process was killed (i.e. SIGKILL). The
typical reason for this is that there is not enough memory available (e.g. the
OS killed a process using lots of memory).
```

#### raspberry pi4 cardano node sync status

| Network   |      Status      |  Reason |
|----------|:-------------:|------:|
| mainnet |  Stuck | Stuck at epoc 317. Tried with 16GB swap.| 
| preprod | Test Pending     |    |
| preview | Test Pending |     |

### Refrences:
- https://github.com/input-output-hk/cardano-node/blob/master/doc/getting-started/install.md/
- https://developers.cardano.org/docs/get-started/installing-cardano-node/
- https://www.coincashew.com/coins/overview-ada/guide-how-to-build-a-haskell-stakepool-node

### Alternatives:
- https://github.com/jterrier84/Cardano-node-docker
- https://github.com/armada-alliance/cardano-node-binaries/tree/main/static-binaries