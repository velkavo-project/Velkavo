# Velkavo Operator Guide

Everything you need to run a node and mine VKV — across macOS, Linux, and Raspberry Pi.

---

## Table of Contents

- [Getting the Binary](#getting-the-binary)
- [Running a Node](#running-a-node)
  - [macOS (M1/M2)](#macos-m1m2)
  - [Linux (Ubuntu/Debian) — x86\_64](#linux-ubuntudebian--x86_64)
  - [Raspberry Pi (ARM64)](#raspberry-pi-arm64)
- [Configuration Reference](#configuration-reference)
- [Checking Node Status](#checking-node-status)
- [Mining](#mining)
- [Network Ports & Firewall](#network-ports--firewall)
- [Fallback Peer Bootstrapping](#fallback-peer-bootstrapping)

---

## Getting the Binary

### Pre-built (recommended)

Download from the [GitHub Releases page](https://github.com/velkavo-project/Velkavo/releases):

| File | Platform |
|------|----------|
| `velkarod-linux-x86_64` | Linux servers, x86_64 desktops |
| `velkarod-linux-arm64` | Raspberry Pi (64-bit OS) |

macOS (M1/M2): build from source (see below) — no pre-built binary yet.

### Build from Source

**Dependencies — Ubuntu/Debian:**
```bash
sudo apt-get install build-essential cmake pkg-config \
  libboost-all-dev libssl-dev libzmq3-dev libunbound-dev \
  libsodium-dev libhidapi-dev liblzma-dev libreadline-dev
```

**Dependencies — macOS (Homebrew):**
```bash
brew install cmake boost openssl zmq unbound libsodium hidapi readline
```

**Build:**
```bash
git clone https://github.com/velkavo-project/Velkavo.git
cd Velkavo
mkdir -p build/release && cd build/release
cmake -DCMAKE_BUILD_TYPE=Release -DMANUAL_SUBMODULES=1 ../..
make daemon -j$(nproc)   # Linux
make daemon -j$(sysctl -n hw.logicalcpu)   # macOS
```

Output: `build/release/bin/velkarod`

---

## Running a Node

### macOS (M1/M2)

**1. Install the binary:**
```bash
sudo cp build/release/bin/velkarod /usr/local/bin/velkarod
sudo chmod +x /usr/local/bin/velkarod
```

**2. Create directories and config:**
```bash
sudo mkdir -p /usr/local/etc/velkavo /usr/local/var/log/velkavo /usr/local/var/lib/velkavo
```

Create `/usr/local/etc/velkavo/velkavo.conf`:
```
data-dir=/usr/local/var/lib/velkavo
log-file=/usr/local/var/log/velkavo/velkarod.log
log-level=1
p2p-bind-port=19080
p2p-external-port=19080
rpc-bind-ip=127.0.0.1
rpc-bind-port=19081
out-peers=64
in-peers=128
```

**3a. Run manually:**
```bash
velkarod --config-file /usr/local/etc/velkavo/velkavo.conf --non-interactive
```

**3b. Run as a background service (launchd):**
```bash
cp /path/to/Velkavo/deploy/com.velkavo.velkarod.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.velkavo.velkarod.plist
launchctl start com.velkavo.velkarod
```

| Action | Command |
|--------|---------|
| Start | `launchctl start com.velkavo.velkarod` |
| Stop | `launchctl stop com.velkavo.velkarod` |
| Disable autostart | `launchctl unload ~/Library/LaunchAgents/com.velkavo.velkarod.plist` |
| View logs | `tail -f /usr/local/var/log/velkavo/velkarod.log` |

---

### Linux (Ubuntu/Debian) — x86_64

**1. Install the binary:**
```bash
sudo cp velkarod-linux-x86_64 /usr/local/bin/velkarod
sudo chmod +x /usr/local/bin/velkarod
```

**2. Create user, directories, and config:**
```bash
sudo useradd -r -s /bin/false velkavo
sudo mkdir -p /etc/velkavo /var/lib/velkavo /var/log/velkavo
sudo chown velkavo:velkavo /var/lib/velkavo /var/log/velkavo
```

Create `/etc/velkavo/velkavo.conf`:
```
data-dir=/var/lib/velkavo
log-file=/var/log/velkavo/velkarod.log
log-level=1
p2p-bind-port=19080
p2p-external-port=19080
rpc-bind-ip=127.0.0.1
rpc-bind-port=19081
out-peers=64
in-peers=128
```

**3. Install and start the systemd service:**
```bash
sudo cp /path/to/Velkavo/deploy/velkarod.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now velkarod
```

| Action | Command |
|--------|---------|
| Start | `sudo systemctl start velkarod` |
| Stop | `sudo systemctl stop velkarod` |
| Status | `sudo systemctl status velkarod` |
| View logs | `sudo journalctl -u velkarod -f` |

---

### Raspberry Pi (ARM64)

Same steps as Linux above, but use the `velkarod-linux-arm64` binary.

```bash
sudo cp velkarod-linux-arm64 /usr/local/bin/velkarod
sudo chmod +x /usr/local/bin/velkarod
```

> **Note:** Initial blockchain sync is slow on a Pi — this is normal. Leave it running overnight. Once synced, it stays in sync easily.

> **Storage:** The blockchain requires several GB of disk space. Use an external SSD or USB drive if your SD card is small — set `data-dir` in the config to point to it.

---

## Configuration Reference

All options go in your `velkavo.conf` file.

| Option | Default | Description |
|--------|---------|-------------|
| `data-dir` | `~/.velkavo` | Blockchain and peer data storage |
| `log-file` | stdout | Path to log file |
| `log-level` | `0` | Log verbosity: 0 (minimal) – 4 (debug) |
| `p2p-bind-port` | `19080` | Port to listen for P2P connections |
| `p2p-external-port` | `19080` | External P2P port (if behind NAT) |
| `rpc-bind-ip` | `127.0.0.1` | IP to bind RPC server (keep localhost unless public node) |
| `rpc-bind-port` | `19081` | RPC port |
| `out-peers` | `8` | Max outbound peer connections |
| `in-peers` | `-1` (unlimited) | Max inbound peer connections |
| `limit-rate-up` | unlimited | Upload bandwidth cap (KB/s) |
| `limit-rate-down` | unlimited | Download bandwidth cap (KB/s) |
| `add-peer` | — | Manually add a peer (can repeat multiple times) |
| `testnet` | — | Run on testnet (ports 29080/29081/29082) |
| `stagenet` | — | Run on stagenet (ports 39080/39081/39082) |

**Example with bandwidth limits:**
```
limit-rate-up=2048
limit-rate-down=8192
```

---

## Checking Node Status

Once the node is running, query it via RPC:

```bash
curl http://127.0.0.1:19081/json_rpc \
  -d '{"method":"get_info"}' \
  -H 'Content-Type: application/json'
```

Key fields in the response:

| Field | What it means |
|-------|---------------|
| `status: "OK"` | Node is healthy |
| `height` | Current block height your node is at |
| `target_height` | Network height (if higher than `height`, still syncing) |
| `outgoing_connections_count` | Peers you're connected to (should be > 0) |
| `synchronized: true` | Fully synced with the network |

---

## Mining

Mining requires a running, synced node. You need a Velkavo wallet address to receive rewards.

### Start Mining

**Via the daemon interactive console:**
```
start_mining <YOUR_VKV_ADDRESS> [threads|auto] [do_background_mining] [ignore_battery]
```

Examples:
```bash
# Mine with 2 threads
start_mining VKVxxx... 2

# Use all CPU cores
start_mining VKVxxx... auto

# Background mining (only when CPU is idle)
start_mining VKVxxx... auto true

# All cores, background, allow on battery
start_mining VKVxxx... auto true true
```

**Via RPC:**
```bash
curl http://127.0.0.1:19081/json_rpc \
  -d '{
    "method": "start_mining",
    "params": {
      "miner_address": "<YOUR_VKV_ADDRESS>",
      "threads_count": 2,
      "do_background_mining": false,
      "ignore_battery": false
    }
  }' \
  -H 'Content-Type: application/json'
```

### Stop Mining

**Console:**
```
stop_mining
```

**RPC:**
```bash
curl http://127.0.0.1:19081/json_rpc \
  -d '{"method":"stop_mining"}' \
  -H 'Content-Type: application/json'
```

### Check Mining Status

**Console:**
```
mining_status
```

**RPC:**
```bash
curl http://127.0.0.1:19081/json_rpc \
  -d '{"method":"mining_status"}' \
  -H 'Content-Type: application/json'
```

### Mining Facts

| Property | Value |
|----------|-------|
| Algorithm | RandomX (CPU-optimised, ASIC-resistant) |
| Block time | 120 seconds |
| Reward unlock | 60 blocks (~2 hours) |
| Final block subsidy | 300 VKV/minute |
| Decimal places | 12 |

> **Tip:** RandomX performs best with at least 2GB RAM per mining thread. On machines with limited RAM, use fewer threads than CPU cores.

---

## Network Ports & Firewall

| Network | P2P | RPC | ZMQ |
|---------|-----|-----|-----|
| Mainnet | 19080 | 19081 | 19082 |
| Testnet | 29080 | 29081 | 29082 |
| Stagenet | 39080 | 39081 | 39082 |

**Firewall rules:**
- **P2P port (19080)** — open inbound so other nodes can connect to you
- **RPC port (19081)** — keep closed / localhost-only unless you're running a public node
- **ZMQ port (19082)** — only needed if using ZMQ subscriptions

**Ubuntu (ufw):**
```bash
sudo ufw allow 19080/tcp
```

**macOS:**
No firewall change needed for outbound connections. To accept inbound P2P, allow port 19080 in System Settings → Network → Firewall.

---

## Fallback Peer Bootstrapping

Nodes discover peers via `seeds.velkavo.com` DNS by default. If DNS is unavailable, add known peers manually in your config:

```
add-peer=80.225.231.55:19080
add-peer=141.148.194.210:19080
```

Once your node connects successfully even once, it saves peer addresses locally (`p2pstate.bin` in your data directory) and uses them automatically on all future restarts — no DNS or manual peers needed after that first connection.
