# How to Run a Velkavo Node

A Velkavo node connects you to the network, validates transactions, and relays blocks. You do not need to mine to run a node.

---

## Requirements

| | Minimum |
|---|---|
| OS | macOS (M1/M2), Ubuntu 20.04+, Raspberry Pi (ARM64) |
| RAM | 2 GB |
| Disk | 50 GB free (chain grows over time) |
| Network | Open port 19080 for incoming peers |

---

## Step 1 — Get the Binary

### Option A: Download a pre-built release

Download `velkarod` for your platform from the [Releases page](https://github.com/velkavo-project/Velkavo/releases).

| File | Platform |
|---|---|
| `velkarod-linux-x86_64` | Linux servers, x86_64 desktops |
| `velkarod-linux-arm64` | Raspberry Pi (64-bit OS) |

macOS: build from source (see below).

### Option B: Build from source

**Ubuntu/Debian dependencies:**
```bash
sudo apt-get install build-essential cmake pkg-config \
  libboost-all-dev libssl-dev libzmq3-dev libunbound-dev \
  libsodium-dev libhidapi-dev liblzma-dev libreadline-dev
```

**macOS (Homebrew) dependencies:**
```bash
brew install cmake boost openssl zmq unbound libsodium hidapi readline
```

**Build:**
```bash
git clone https://github.com/velkavo-project/Velkavo.git
cd Velkavo
mkdir -p build/release && cd build/release
cmake -DCMAKE_BUILD_TYPE=Release -DMANUAL_SUBMODULES=1 ../..
make daemon -j$(nproc)        # Linux
make daemon -j$(sysctl -n hw.logicalcpu)  # macOS
```

Binary output: `build/release/bin/velkarod`

---

## Step 2 — Run the Node

### Quick start (no config file needed)

```bash
./velkarod --non-interactive
```

The node will find peers automatically via `seeds.velkavo.com` and start syncing.

### With a config file (recommended)

Create `velkavo.conf`:

```ini
data-dir=/home/youruser/.velkavo
log-file=/home/youruser/.velkavo/velkarod.log
log-level=1

# P2P
p2p-bind-port=19080
p2p-external-port=19080

# RPC (localhost only)
rpc-bind-ip=127.0.0.1
rpc-bind-port=19081

# Limits
out-peers=64
in-peers=128
limit-rate-up=8192
limit-rate-down=32768
```

Run with the config:
```bash
./velkarod --config-file /path/to/velkavo.conf --non-interactive
```

---

## Step 3 — Run as a System Service (Linux)

This keeps the node running after reboots.

```bash
# Create a dedicated user
sudo useradd -r -s /bin/false velkavo

# Create directories
sudo mkdir -p /etc/velkavo /var/lib/velkavo /var/log/velkavo
sudo chown velkavo:velkavo /var/lib/velkavo /var/log/velkavo

# Install binary
sudo cp velkarod /usr/local/bin/velkarod
sudo chmod +x /usr/local/bin/velkarod

# Install config
sudo cp velkavo.conf /etc/velkavo/velkavo.conf
```

Create `/etc/systemd/system/velkarod.service`:
```ini
[Unit]
Description=Velkavo Daemon
After=network.target

[Service]
Type=simple
User=velkavo
ExecStart=/usr/local/bin/velkarod --config-file /etc/velkavo/velkavo.conf --non-interactive
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now velkarod
```

---

## Checking Node Status

```bash
# Is it running?
sudo systemctl status velkarod

# Live logs
sudo journalctl -fu velkarod

# Query via RPC
curl -s http://127.0.0.1:19081/get_info | python3 -m json.tool
```

Key fields in the RPC response:

| Field | Meaning |
|---|---|
| `status` | Should be `OK` |
| `height` | Current block height your node is at |
| `target_height` | Network height (0 = synced) |
| `synchronized` | `true` when fully caught up |
| `outgoing_connections_count` | Peers you connected to |
| `incoming_connections_count` | Peers that connected to you |

---

## Ports & Firewall

| Port | Purpose | Direction |
|---|---|---|
| `19080` | P2P (peer discovery, block relay) | Inbound + Outbound |
| `19081` | RPC API | Localhost only |

Open port 19080 if you have a firewall:
```bash
# Ubuntu UFW
sudo ufw allow 19080/tcp

# iptables
sudo iptables -A INPUT -p tcp --dport 19080 -j ACCEPT
```

**Never expose port 19081 to the internet** — it has no authentication by default.
