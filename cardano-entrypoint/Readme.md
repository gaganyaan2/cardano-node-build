# Cardano entrypoint

Source - https://github.com/input-output-hk/cardano-node/tree/master/nix/docker

- Added `run-network` from `inputoutput/cardano-node:1.35.3-configs` 
- Modified `run-network` as per `/run-network-config` path
- `cp -a /nix/store/* /run-network-config` and modified
- Get latest config - https://hydra.iohk.io/build/8111119/download/1/index.html