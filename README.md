# Velkavo

Copyright (c) 2026, The Velkavo Project.

## Table of Contents

- [About](#about)
- [Coin Identity](#coin-identity)
- [Network Ports](#network-ports)
- [Building from Source](#building-from-source)
  - [Dependencies](#dependencies)
  - [Build](#build)
- [Running a Node](#running-a-node)
- [Deployment](#deployment)
- [License](#license)

## About

Velkavo (VKV) is a privacy-focused cryptocurrency.

**New to Velkavo? Start here: [Getting Started Guide](docs/GETTING_STARTED.md)** — covers building, running a node, creating a wallet, mining, and sending VKV in one place.

For operator/server deployment see the **[Operator Guide](docs/GUIDE.md)**. Velkavo inherits proven cryptography, RingCT, and Dandelion++ networking while establishing an independent chain identity, coin supply, and network.

- GitHub: [https://github.com/velkavo-project/Velkavo](https://github.com/velkavo-project/Velkavo)
- DNS Seeds: `seeds.velkavo.com`
- Domain: [velkavo.com](https://velkavo.com)

## Coin Identity

| Property | Value |
|---|---|
| Name | Velkavo |
| Ticker | VKV |
| Address prefix | VKV |

## Network Ports

| Network | P2P | RPC | ZMQ |
|---|---|---|---|
| Mainnet | 19080 | 19081 | 19082 |
| Testnet | 29080 | 29081 | 29082 |
| Stagenet | 39080 | 39081 | 39082 |

## Building from Source

### Dependencies

**Ubuntu / Debian:**
```bash
sudo apt-get install build-essential cmake pkg-config \
  libboost-all-dev libssl-dev libzmq3-dev libunbound-dev \
  libsodium-dev libhidapi-dev liblzma-dev libreadline-dev
```

**macOS (Homebrew):**
```bash
brew install cmake boost openssl zmq unbound libsodium hidapi readline
```

### Build

```bash
git clone --recurse-submodules https://github.com/velkavo-project/Velkavo.git
cd Velkavo
mkdir -p build/release && cd build/release
cmake -DCMAKE_BUILD_TYPE=Release -DMANUAL_SUBMODULES=1 ../..
make daemon -j$(nproc)
```

The binary is output to `build/release/bin/velkarod`.

## Running a Node

**With systemd (recommended):**
```bash
sudo cp deploy/velkarod.service /etc/systemd/system/
sudo cp deploy/velkavo.conf /etc/velkavo/velkavo.conf
sudo systemctl enable --now velkarod
```

**Manually:**
```bash
./velkarod --config-file /etc/velkavo/velkavo.conf --non-interactive
```

Check status:
```bash
sudo journalctl -u velkarod -f
```

## Deployment

The `deploy/` directory contains scripts for deploying to remote servers:

```bash
# Copy VM IPs and SSH keys into .env (see .env.example)
cp .env.example .env

# Deploy to both VMs
./deploy/deploy.sh
```

## License

Copyright (c) 2026, The Velkavo Project

Portions of this software are derived from the Velkavo Project, which is
licensed under the BSD 3-Clause License. See [LICENSE](LICENSE) for details.
