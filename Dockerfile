ARG UBUNTU=ubuntu:22.04

# The daemon the explorer links: Bitlitas v0.18.3.1, the GitLab
# release-v0.18 / master commit (2023-10-30) — the same source
# the bitlitasd-v2 full node is built from
ARG BITLITAS_REPO=https://gitlab.com/bitlitas-project/bitlitas.git
ARG BITLITAS_COMMIT=d40885fc1d2c2a65af23e5b71c14a7c821384ff6

# Parallel compile jobs
ARG JOBS=6







# -----------------------------------------------------------
# bitlitas-src — the daemon source tree
# -----------------------------------------------------------
#
# With its .git (the daemon's CMake reads its version from
# git) and its submodules (RandomX, miniupnp, supercop …)
FROM scratch AS bitlitas-src
ARG BITLITAS_REPO
ARG BITLITAS_COMMIT
ADD --keep-git-dir=true ${BITLITAS_REPO}#${BITLITAS_COMMIT} /







# -----------------------------------------------------------
# toolchain — compilers and the -dev packages both builds use
# -----------------------------------------------------------
FROM ${UBUNTU} AS toolchain

# Keep downloaded .debs in the cache mounts below, not the image
RUN rm -f /etc/apt/apt.conf.d/docker-clean

# No libhidapi-dev / libprotobuf-dev: the explorer needs no
# hardware-wallet support, and leaving them out keeps the
# runtime image free of USB libraries
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --yes \
        build-essential \
        ca-certificates \
        cmake \
        git \
        pkg-config \
        libboost-chrono-dev \
        libboost-date-time-dev \
        libboost-filesystem-dev \
        libboost-locale-dev \
        libboost-program-options-dev \
        libboost-regex-dev \
        libboost-serialization-dev \
        libboost-system-dev \
        libboost-thread-dev \
        libsodium-dev \
        libssl-dev \
        libunbound-dev \
        libunwind-dev \
        libzmq3-dev

# The explorer links these static libraries into a PIE binary
ENV CFLAGS=-fPIC \
    CXXFLAGS=-fPIC







# -----------------------------------------------------------
# bitlitas-libs — the daemon libraries the explorer links
# -----------------------------------------------------------
#
# The explorer's CMake expects them under
# <MONERO_DIR>/build/release (the Bitlitas tree keeps Monero's
# internal names). ARCH=x86-64 instead of the daemon's default
# "native", so the image runs on any x86-64 CPU, not only the
# build host's. MANUAL_SUBMODULES: the submodules come from the
# ADD above, so skip the daemon's own git submodule check.
FROM toolchain AS bitlitas-libs
ARG JOBS

COPY --from=bitlitas-src / /src/bitlitas
WORKDIR /src/bitlitas/build/release

RUN cmake ../.. \
        -DCMAKE_BUILD_TYPE=Release \
        -DARCH=x86-64 \
        -DBUILD_TESTS=OFF \
        -DBUILD_DOCUMENTATION=OFF \
        -DMANUAL_SUBMODULES=1 \
        -DUSE_DEVICE_TREZOR=OFF \
 && make -j"${JOBS}" \
        blockchain_db blocks checkpoints cncrypto common \
        cryptonote_basic cryptonote_core cryptonote_format_utils_basic \
        cryptonote_protocol daemonizer device easylogging epee hardforks \
        libminiupnpc-static lmdb mnemonics multisig randomx ringct \
        ringct_basic version wallet wallet-crypto







# -----------------------------------------------------------
# explorer-build — the explorer binary
# -----------------------------------------------------------
FROM bitlitas-libs AS explorer-build
ARG JOBS

# The bundled Crow web framework runs on Boost.Asio (see
# CROW_USE_BOOST in CMakeLists.txt), so no standalone Asio
COPY . /src/explorer
WORKDIR /src/explorer/build

RUN cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DMONERO_DIR=/src/bitlitas \
 && make -j"${JOBS}" \
 && strip litblocks







# -----------------------------------------------------------
# runtime — the binary, its templates and its shared libraries
# -----------------------------------------------------------
#
# Exactly what `ldd litblocks` loads; the ldd check below keeps
# this list honest
FROM ${UBUNTU} AS runtime

RUN rm -f /etc/apt/apt.conf.d/docker-clean

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --yes \
        libatomic1 \
        libboost-chrono1.74.0 \
        libboost-filesystem1.74.0 \
        libboost-program-options1.74.0 \
        libboost-regex1.74.0 \
        libboost-serialization1.74.0 \
        libboost-thread1.74.0 \
        libsodium23 \
        libssl3 \
        libunbound8 \
        libunwind8

# The templates are read at runtime from ./templates
WORKDIR /app
COPY --from=explorer-build /src/explorer/build/litblocks /app/litblocks
COPY --from=explorer-build /src/explorer/build/templates /app/templates

# Fail the build here, not at startup, if a shared library is missing
RUN ! ldd /app/litblocks | grep 'not found'

USER 1000:1000
EXPOSE 8081

ENTRYPOINT ["/app/litblocks"]
CMD ["--port=8081", "--bc-path=/data/lmdb", "--daemon-url=127.0.0.1:18281"]
