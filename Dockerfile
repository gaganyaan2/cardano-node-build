FROM ubuntu:20.04 AS base
ARG DEBIAN_FRONTEND=noninteractive
ENV BOOTSTRAP_HASKELL_GHC_VERSION=8.10.7
ENV BOOTSTRAP_HASKELL_CABAL_VERSION=3.6.2.0
RUN apt update -y && \
    apt install automake build-essential pkg-config libffi-dev libgmp-dev libssl-dev libtinfo-dev libsystemd-dev zlib1g-dev make g++ tmux git jq wget libncursesw5 libtool autoconf liblmdb-dev curl -y && \
    apt clean -y && \
    rm -rf /var/lib/apt/lists/*
RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | BOOTSTRAP_HASKELL_NONINTERACTIVE=1 BOOTSTRAP_HASKELL_GHC_VERSION=${BOOTSTRAP_HASKELL_GHC_VERSION} BOOTSTRAP_HASKELL_CABAL_VERSION=${BOOTSTRAP_HASKELL_CABAL_VERSION} sh && \
    rm -rf /root/.ghcup/tmp/
RUN ~/.ghcup/bin/ghcup install ghc ${BOOTSTRAP_HASKELL_GHC_VERSION}
RUN ~/.ghcup/bin/ghcup set ghc ${BOOTSTRAP_HASKELL_GHC_VERSION}
RUN ~/.ghcup/bin/ghcup install cabal ${BOOTSTRAP_HASKELL_CABAL_VERSION}
RUN ~/.ghcup/bin/ghcup set cabal ${BOOTSTRAP_HASKELL_CABAL_VERSION}

FROM base AS libsodium
WORKDIR /root/src
RUN git clone https://github.com/input-output-hk/libsodium
WORKDIR /root/src/libsodium
RUN git checkout 66f017f1
RUN ./autogen.sh && ./configure
RUN make && make install && make clean
RUN echo 'export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"' >> ~/.bashrc
RUN echo 'export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"' >> ~/.bashrc
RUN echo 'PATH="$PATH:/root/.ghcup/bin/"' >> ~/.bashrc
RUN apt update -y && apt install libsodium-dev -y
RUN ln -s /usr/local/lib/libsodium.so.23.3.0 /usr/lib/libsodium.so.23

FROM libsodium AS secp256k1
WORKDIR /root/src
RUN git clone https://github.com/bitcoin-core/secp256k1
WORKDIR /root/src/secp256k1
RUN git checkout ac83be33
RUN ./autogen.sh && ./configure --enable-module-schnorrsig --enable-experimental
RUN make && make install && make clean
RUN ldconfig

FROM secp256k1 AS cardano-node
ARG git_commit_id='tags/1.35.4'
WORKDIR /root/src
RUN git clone https://github.com/input-output-hk/cardano-node.git
WORKDIR /root/src/cardano-node
RUN git fetch --all --recurse-submodules --tags
RUN git checkout ${git_commit_id}
RUN echo 'package cardano-crypto-praos' >> cabal.project.local && \
    echo ' flags: -external-libsodium-vrf' >> cabal.project.local && \
    echo "with-compiler: ghc-${BOOTSTRAP_HASKELL_GHC_VERSION}" >> cabal.project.local
RUN export PATH="$PATH:/root/.ghcup/bin/"; cabal update && cabal build all
RUN mkdir -p ~/.local/bin
RUN cp -p "$(./scripts/bin-path.sh cardano-node)" ~/.local/bin/
RUN cp -p "$(./scripts/bin-path.sh cardano-cli)" ~/.local/bin/

FROM ubuntu:20.04 AS cardano-node-slim
ARG DEBIAN_FRONTEND=noninteractive
RUN apt update -y && \
    apt install build-essential libssl-dev libsodium-dev -y && \
    apt clean -y && \
    rm -rf /var/lib/apt/lists/*
RUN echo 'export LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"' >> ~/.bashrc
RUN echo 'export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"' >> ~/.bashrc
RUN ln -s /usr/local/lib/libsodium.so.23.3.0 /usr/lib/libsodium.so.23
RUN mkdir -p /opt/cardano/{config,data,ipc,logs}
COPY --from=cardano-node /usr/local/lib/ /usr/local/lib/
COPY --from=cardano-node /usr/local/lib/pkgconfig/ /usr/local/lib/pkgconfig/
RUN ldconfig
COPY --from=cardano-node /root/.local/bin/cardano-node /usr/local/bin/cardano-node
COPY --from=cardano-node /root/.local/bin/cardano-cli /usr/local/bin/cardano-cli
ADD cardano-entrypoint /usr/local/bin
COPY run-network-config /run-network-config
ENTRYPOINT ["entrypoint"]
