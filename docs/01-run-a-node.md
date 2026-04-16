# How to Run a Velkavo Node

A Velkavo node connects you to the network, validates transactions, and relays blocks. You do not need to mine to run a node.

This guide covers macOS in full detail. Linux instructions are included at the end of each section.

---

## Table of Contents

1. [Requirements](#requirements)
2. [macOS: Build from Source](#macos-build-from-source)
   - [1. Verify your system](#1-verify-your-system)
   - [2. Install Xcode Command Line Tools](#2-install-xcode-command-line-tools)
   - [3. Install Homebrew](#3-install-homebrew)
   - [4. Install build dependencies](#4-install-build-dependencies)
   - [5. Clone the repository and submodules](#5-clone-the-repository-and-submodules)
   - [6. Apply the wallet-crypto CMake fix](#6-apply-the-wallet-crypto-cmake-fix)
   - [7. Configure with cmake](#7-configure-with-cmake)
   - [8. Compile the daemon](#8-compile-the-daemon)
3. [Linux: Build from Source](#linux-build-from-source)
4. [Configuration](#configuration)
5. [Running the Node](#running-the-node)
6. [Run as a Background Service](#run-as-a-background-service)
   - [macOS — launchd](#macos--launchd)
   - [Linux — systemd](#linux--systemd)
7. [Checking Node Status](#checking-node-status)
8. [Ports & Firewall](#ports--firewall)
9. [Upgrading](#upgrading)
10. [Stopping the Node Gracefully](#stopping-the-node-gracefully)
11. [Uninstalling](#uninstalling)
12. [Troubleshooting](#troubleshooting)

---

## Requirements

| | Minimum | Recommended |
|---|---|---|
| OS | macOS 13 Ventura (Apple Silicon M1+) | macOS 14+ |
| RAM | 2 GB | 4 GB+ |
| Disk | 50 GB free | 100 GB+ (SSD preferred) |
| Network | Stable internet, port 19080 open | 10+ Mbps, static IP or DDNS |
| CPU | Any Apple Silicon | M2 or newer |

> **Disk note:** The chain grows over time. An SSD is strongly preferred — blockchain I/O on a spinning disk will cause the node to lag badly during sync.

### Verify your system before starting

```bash
# macOS version
sw_vers -productVersion

# Architecture (should be arm64 on Apple Silicon)
uname -m

# Available RAM
sysctl -n hw.memsize | awk '{printf "%.1f GB\n", $1/1024/1024/1024}'

# Free disk space on your home volume
df -h ~

# CPU core count (used later for -j flag)
sysctl -n hw.logicalcpu
```

---

## macOS: Build from Source

Pre-built macOS binaries are not distributed. You must compile `velkarod` from source. The steps below were verified on macOS 15 (Apple Silicon, M1).

---

### 1. Verify your system

Make sure you have at least 50 GB free and are on macOS 13 or later:

```bash
sw_vers -productVersion   # e.g. 15.3.0
df -h ~                   # check "Avail" column
```

---

### 2. Install Xcode Command Line Tools

The Xcode Command Line Tools provide `clang` (C/C++ compiler), `git`, `make`, `ar`, and other core build tools.

```bash
xcode-select --install
```

A system dialog will appear — click **Install** and wait for the download (about 1–2 GB). Do **not** use `sudo` for this command.

**Verify the install:**
```bash
xcode-select -p
# Expected output: /Library/Developer/CommandLineTools
clang --version
# Expected: Apple clang version 15.x.x or later
```

**If you already have Xcode.app** (the full IDE), the tools are bundled. You can also run:
```bash
xcode-select -s /Applications/Xcode.app/Contents/Developer
```

**Troubleshooting:**
- If the dialog never appears: `sudo xcode-select --reset`, then try again.
- If you get `xcode-select: error: tool 'xcodebuild' requires Xcode`: install Xcode from the App Store or use `xcode-select --install`.
- On macOS 15+, if the install stalls, try: **System Settings → General → Software Update** and install any pending Command Line Tools updates.

---

### 3. Install Homebrew

Homebrew is the macOS package manager used to install all C/C++ library dependencies.

**Check if Homebrew is already installed:**
```bash
brew --version
```

If that returns a version, skip to step 4.

**Install Homebrew:**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

After installation, the installer prints a "Next steps" section. On **Apple Silicon** you must add Homebrew to your PATH — run the two commands it prints, which look like:

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

On **Intel Macs**, Homebrew installs to `/usr/local` which is already on PATH — no extra step needed.

**Verify:**
```bash
brew --version
# Homebrew 4.x.x
which brew
# /opt/homebrew/bin/brew  (Apple Silicon)
# /usr/local/bin/brew     (Intel)
```

**Keep Homebrew up to date before installing packages:**
```bash
brew update
```

---

### 4. Install build dependencies

```bash
brew install cmake boost openssl zeromq unbound libsodium hidapi readline
```

All eight packages are required:

| Package | Brew name | Version tested | Purpose |
|---|---|---|---|
| CMake | `cmake` | 3.28+ | Build system generator |
| Boost | `boost` | 1.84+ | Filesystem, threads, chrono, serialization, program_options |
| OpenSSL | `openssl` | 3.x | SHA-256, TLS for the RPC server |
| ZeroMQ | `zeromq` | 4.3.x | ZMQ pub/sub messaging interface |
| Unbound | `unbound` | 1.19+ | DNSSEC-validating resolver for peer/seed lookup |
| libsodium | `libsodium` | 1.0.x | Ed25519 signatures, ChaCha20 encryption |
| HIDAPI | `hidapi` | 0.14+ | Hardware wallet (Ledger) USB communication |
| GNU Readline | `readline` | 8.x | Interactive daemon CLI input |

> **Note:** The CMake variable uses `zmq` but the Homebrew formula is named `zeromq`. If you accidentally install `zmq`, remove it (`brew uninstall zmq`) and install `zeromq` instead.

**Verify all packages installed:**
```bash
brew list cmake boost openssl zeromq unbound libsodium hidapi readline
```

Each package should print its installed files with no errors. If a package is missing from the output, re-run the `brew install` line.

**Check for linking issues (optional):**
```bash
brew doctor
```

Resolve any warnings it reports before proceeding.

---

### 5. Clone the repository and submodules

```bash
git clone https://github.com/velkavo-project/Velkavo.git
cd Velkavo
```

Initialize all submodules. The build **will fail** without this step:

```bash
git submodule update --init --recursive
```

This clones five submodules:

| Submodule | Path | Purpose |
|---|---|---|
| GoogleTest | `external/gtest` | Unit test framework |
| miniupnp | `external/miniupnp` | UPnP port mapping |
| RandomX | `external/randomx` | Proof-of-work algorithm |
| RapidJSON | `external/rapidjson` | JSON parsing |
| supercop | `external/supercop` | Cryptographic reference implementations |

**Verify submodules:**
```bash
git submodule status
# Each line should start with a commit hash, not a "-" (uninitialised) or "+" (modified)
```

---

### 6. Apply the wallet-crypto CMake fix

The current source tree is missing the definition of a CMake function called `velkavo_crypto_autodetect`. Without this patch, cmake will abort with:

```
CMake Error at src/crypto/wallet/CMakeLists.txt:39 (velkavo_crypto_autodetect):
  Unknown CMake command "velkavo_crypto_autodetect".
```

**Apply the fix** by opening `src/crypto/wallet/CMakeLists.txt` and inserting the following stub immediately before the line `if (${VELKAVO_WALLET_CRYPTO_LIBRARY} STREQUAL "auto")` (around line 38):

```cmake
if (NOT COMMAND velkavo_crypto_autodetect)
  function(velkavo_crypto_autodetect AVAILABLE_VAR BEST_VAR)
    # Stub: no external wallet crypto backends; fall back to internal "cn"
  endfunction()
endif()
```

**What this does:** The autodetect function is supposed to search for optional external crypto backends and set a `BEST` variable. Because it is not defined, we provide an empty stub. The empty stub leaves `BEST` unset, so cmake falls through to the default `set(VELKAVO_WALLET_CRYPTO_LIBRARY "cn")` — the internal CryptoNight implementation — which is the correct and fully supported option on macOS.

**Or apply it as a one-liner from the repo root:**
```bash
sed -i '' '38s/.*/if (NOT COMMAND velkavo_crypto_autodetect)\n  function(velkavo_crypto_autodetect AVAILABLE_VAR BEST_VAR)\n    # Stub: fall back to internal "cn"\n  endfunction()\nendif()\n\n&/' src/crypto/wallet/CMakeLists.txt
```

---

### 7. Configure with cmake

Create a dedicated build directory (keeps the source tree clean) and run cmake from inside it:

```bash
mkdir -p build/release
cd build/release
cmake -DCMAKE_BUILD_TYPE=Release -DMANUAL_SUBMODULES=1 /path/to/Velkavo
```

Replace `/path/to/Velkavo` with the absolute path to the repo root, e.g. `$HOME/Desktop/Velkavo`.

**CMake flags explained:**

| Flag | Meaning |
|---|---|
| `-DCMAKE_BUILD_TYPE=Release` | Enables compiler optimizations (`-O3`), disables debug symbols. Required for a production node. |
| `-DMANUAL_SUBMODULES=1` | Tells cmake to use the submodules you cloned in step 5, rather than trying to download them itself. |

**Expected end of output:**
```
Defaulting to internal crypto library for wallet
-- Trezor: support disabled
-- Not building tests
-- Configuring done (2–5s)
-- Generating done
-- Build files have been written to: .../build/release
```

**Warnings that are safe to ignore:**

| Warning | Why it appears | Safe? |
|---|---|---|
| `CMake Deprecation Warning: CMP0148` | Old `FindPythonInterp` policy | Yes |
| `CMake Deprecation Warning: CMP0167` | Old `FindBoost` module | Yes |
| `Trezor: protobuf library not found` | Protobuf not installed; Trezor hardware wallet support disabled | Yes — node still works |
| `Could NOT find Doxygen` | Doc generation tool not installed | Yes |
| `ccache NOT found` | Optional compile cache not installed | Yes (install `brew install ccache` to speed up rebuilds) |
| `-fcf-protection=full ... Failed` | ARM64 doesn't support this x86 flag | Yes |

**If cmake fails:**

- `Could NOT find Boost`: run `brew install boost` and try again. If boost is installed but not found, run `brew link boost`.
- `Could NOT find OpenSSL`: run `brew install openssl`. If still not found, add: `-DOPENSSL_ROOT_DIR=$(brew --prefix openssl)` to the cmake command.
- `Could NOT find libzmq`: ensure `zeromq` (not `zmq`) is installed: `brew install zeromq`.
- `Could NOT find Unbound`: `brew install unbound`.

---

### 8. Compile the daemon

From inside `build/release`:

```bash
make daemon -j$(sysctl -n hw.logicalcpu)
```

`-j$(sysctl -n hw.logicalcpu)` uses all logical CPU cores in parallel. On an M1 with 8 cores this compiles all ~250 translation units simultaneously.

**Typical build time:**

| Mac | Time |
|---|---|
| M1 (8-core) | ~10–15 min |
| M2 Pro (12-core) | ~6–10 min |
| M3 Max (16-core) | ~4–6 min |

You will see output like:
```
[  2%] Building CXX object external/randomx/CMakeFiles/randomx.dir/...
[ 10%] Linking CXX static library librandomx.a
...
[100%] Linking CXX executable velkarod
[100%] Built target daemon
```

**Binary output:** `build/release/bin/velkarod`

**Verify the build:**
```bash
./build/release/bin/velkarod --version
# Velkavo 'Fluorine Fermi' (v0.18.1.0-...)
```

**If the build fails:**

- `error: use of undeclared identifier`: usually a missing dependency. Re-check step 4.
- Ran out of memory during link: reduce parallelism: `make daemon -j2`.
- `ld: library not found for -lssl`: OpenSSL not linked. Add to cmake: `-DOPENSSL_ROOT_DIR=$(brew --prefix openssl)`.
- Compile errors in `src/crypto`: ensure step 6 (the wallet-crypto patch) was applied correctly.

---

## Linux: Build from Source

**Install dependencies (Ubuntu/Debian):**
```bash
sudo apt-get update
sudo apt-get install build-essential cmake pkg-config \
  libboost-all-dev libssl-dev libzmq3-dev libunbound-dev \
  libsodium-dev libhidapi-dev liblzma-dev libreadline-dev
```

**Clone, patch, and build:**
```bash
git clone https://github.com/velkavo-project/Velkavo.git
cd Velkavo
git submodule update --init --recursive

# Apply the wallet-crypto CMake fix (same as macOS step 6)
sed -i '38s/.*/if (NOT COMMAND velkavo_crypto_autodetect)\n  function(velkavo_crypto_autodetect AVAILABLE_VAR BEST_VAR)\n  endfunction()\nendif()\n\n&/' src/crypto/wallet/CMakeLists.txt

mkdir -p build/release && cd build/release
cmake -DCMAKE_BUILD_TYPE=Release -DMANUAL_SUBMODULES=1 ../..
make daemon -j$(nproc)
```

Binary output: `build/release/bin/velkarod`

---

## Configuration

### macOS config file

Create the data directory and config file:

```bash
mkdir -p ~/.velkavo
```

Create `~/.velkavo/velkavo.conf` with the following contents, replacing `YOUR_USERNAME` with your actual username (`whoami` prints it):

```ini
# Data and logs
data-dir=/Users/YOUR_USERNAME/.velkavo
log-file=/Users/YOUR_USERNAME/.velkavo/velkarod.log
log-level=1
max-log-file-size=104857600
max-log-files=5

# P2P networking
p2p-bind-port=19080
p2p-external-port=19080

# RPC API — localhost only
rpc-bind-ip=127.0.0.1
rpc-bind-port=19081

# Bandwidth limits (kB/s)
limit-rate-up=8192
limit-rate-down=32768

# Peer counts
out-peers=64
in-peers=128
```

### All configuration options explained

| Option | Default | Description |
|---|---|---|
| `data-dir` | `~/.velkavo` | Where the blockchain database, peer cache, and ring database are stored. Needs 50 GB+ free. |
| `log-file` | `~/.velkavo/velkavo.log` | Path to the log file. |
| `log-level` | `0` | Verbosity: 0 = errors only, 1 = informational, 2 = debug, 3 = trace, 4 = everything. Level 1 is recommended for normal operation. |
| `max-log-file-size` | `104850000` (~100 MB) | Log is rotated when it reaches this size (bytes). |
| `max-log-files` | `10` | Number of rotated log files to keep. Set to `0` for no limit. |
| `p2p-bind-port` | `19080` | Port the P2P server listens on for incoming peer connections. |
| `p2p-external-port` | `19080` | The port advertised to peers (use if behind NAT/router port forwarding with a different external port). |
| `rpc-bind-ip` | `127.0.0.1` | IP the RPC server listens on. Keep as `127.0.0.1` unless you need remote wallet access. |
| `rpc-bind-port` | `19081` | Port the RPC server listens on. |
| `out-peers` | `12` | Maximum outbound peer connections. Higher values improve network connectivity. |
| `in-peers` | `-1` (unlimited) | Maximum inbound peer connections. Set a limit (e.g. `128`) to cap resource usage. |
| `limit-rate-up` | `8192` | Upload bandwidth cap in kB/s. 8192 = 8 MB/s. |
| `limit-rate-down` | `32768` | Download bandwidth cap in kB/s. 32768 = 32 MB/s. |
| `no-igd` | off | Add this flag to disable UPnP automatic port mapping (useful if your router does not support UPnP). |
| `public-node` | off | Advertise as a public node that wallets can connect to remotely (enables restricted RPC mode). |
| `no-zmq` | off | Disable the ZMQ pub/sub interface if you don't need it. |

### Optional: bootstrap daemon for wallets during sync

If you want your wallet to work while the node is still syncing, add:

```ini
bootstrap-daemon-address=auto
```

This routes wallet RPC calls to a trusted public node until your local node is fully synced.

---

## Running the Node

### Quick start (foreground, no config file)

```bash
./build/release/bin/velkarod --non-interactive
```

Press `Ctrl+C` to stop. The node discovers peers via `seeds.velkavo.com` automatically.

### With config file (recommended)

```bash
./build/release/bin/velkarod --config-file ~/.velkavo/velkavo.conf --non-interactive
```

### Run detached (background process, no service manager)

```bash
./build/release/bin/velkarod \
  --config-file ~/.velkavo/velkavo.conf \
  --detach \
  --pidfile ~/.velkavo/velkarod.pid
```

The daemon forks to the background and writes its PID to `~/.velkavo/velkarod.pid`.

To stop it later:
```bash
kill $(cat ~/.velkavo/velkarod.pid)
```

> For persistent background operation across reboots, use launchd (see next section) instead of `--detach`.

---

## Run as a Background Service

### macOS — launchd

launchd is the macOS init system. A LaunchAgent runs as your user at login and is restarted automatically if the process crashes.

#### 1. Install the binary system-wide

```bash
sudo cp build/release/bin/velkarod /usr/local/bin/velkarod
sudo chmod +x /usr/local/bin/velkarod
```

Verify:
```bash
which velkarod
# /usr/local/bin/velkarod
velkarod --version
```

#### 2. Set up data and log directories

```bash
sudo mkdir -p /var/lib/velkavo /var/log/velkavo
sudo chown $(whoami) /var/lib/velkavo /var/log/velkavo
```

#### 3. Install the config

```bash
sudo mkdir -p /etc/velkavo
sudo cp ~/.velkavo/velkavo.conf /etc/velkavo/velkavo.conf
```

Edit `/etc/velkavo/velkavo.conf` to use the system paths:

```ini
data-dir=/var/lib/velkavo
log-file=/var/log/velkavo/velkarod.log
log-level=1
max-log-file-size=104857600
max-log-files=5

p2p-bind-port=19080
p2p-external-port=19080

rpc-bind-ip=127.0.0.1
rpc-bind-port=19081

limit-rate-up=8192
limit-rate-down=32768
out-peers=64
in-peers=128
```

#### 4. Create the LaunchAgent plist

Save the following to `~/Library/LaunchAgents/com.velkavo.node.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Unique service identifier -->
    <key>Label</key>
    <string>com.velkavo.node</string>

    <!-- Command and arguments to run -->
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/velkarod</string>
        <string>--config-file</string>
        <string>/etc/velkavo/velkavo.conf</string>
        <string>--non-interactive</string>
    </array>

    <!-- Start at login -->
    <key>RunAtLoad</key>
    <true/>

    <!-- Restart automatically if it exits or crashes -->
    <key>KeepAlive</key>
    <true/>

    <!-- Stdout goes here (node startup messages) -->
    <key>StandardOutPath</key>
    <string>/var/log/velkavo/velkarod.log</string>

    <!-- Stderr goes here (fatal errors) -->
    <key>StandardErrorPath</key>
    <string>/var/log/velkavo/velkarod.err</string>

    <!-- Throttle restarts: wait 10s before restarting on failure -->
    <key>ThrottleInterval</key>
    <integer>10</integer>
</dict>
</plist>
```

#### 5. Load and start the service

```bash
launchctl load ~/Library/LaunchAgents/com.velkavo.node.plist
launchctl start com.velkavo.node
```

Verify it is running:
```bash
launchctl list | grep velkavo
# Should show the PID in the first column
```

#### 6. Service management commands

```bash
# Start
launchctl start com.velkavo.node

# Stop (it will restart automatically due to KeepAlive — use unload to stop permanently)
launchctl stop com.velkavo.node

# Stop permanently (survives reboot)
launchctl unload ~/Library/LaunchAgents/com.velkavo.node.plist

# Re-enable after unload
launchctl load ~/Library/LaunchAgents/com.velkavo.node.plist

# Reload after editing the plist
launchctl unload ~/Library/LaunchAgents/com.velkavo.node.plist
launchctl load ~/Library/LaunchAgents/com.velkavo.node.plist
```

---

### Linux — systemd

```bash
# Create a dedicated system user (no login shell)
sudo useradd -r -s /bin/false velkavo

# Create directories
sudo mkdir -p /etc/velkavo /var/lib/velkavo /var/log/velkavo
sudo chown velkavo:velkavo /var/lib/velkavo /var/log/velkavo

# Install binary
sudo cp build/release/bin/velkarod /usr/local/bin/velkarod
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

### macOS — process and logs

```bash
# Is velkarod running? (prints PID and name if yes)
pgrep -l velkarod

# Live log stream (Ctrl+C to stop)
tail -f /var/log/velkavo/velkarod.log

# Last 50 log lines
tail -50 /var/log/velkavo/velkarod.log

# launchd service status (PID is in first column; 0 = stopped)
launchctl list | grep velkavo

# Error log (fatal crashes only)
cat /var/log/velkavo/velkarod.err
```

### Linux — process and logs

```bash
# Systemd service status
sudo systemctl status velkarod

# Live log stream
sudo journalctl -fu velkarod

# Last 100 lines
sudo journalctl -u velkarod -n 100
```

### RPC status check (all platforms)

```bash
curl -s http://127.0.0.1:19081/get_info | python3 -m json.tool
```

Full field reference:

| Field | Type | Meaning |
|---|---|---|
| `status` | string | `"OK"` = daemon is healthy |
| `height` | int | Block height your node is currently at |
| `target_height` | int | Network's current tip height (`0` once fully synced) |
| `synchronized` | bool | `true` when `height == target_height` |
| `outgoing_connections_count` | int | Number of peers you dialed out to |
| `incoming_connections_count` | int | Number of peers that connected to you (requires open port 19080) |
| `white_peerlist_size` | int | Peers in your trusted peerlist |
| `grey_peerlist_size` | int | Peers seen but not confirmed reachable |
| `tx_pool_size` | int | Unconfirmed transactions in the mempool |
| `busy_syncing` | bool | `true` while downloading blocks |
| `database_size` | int | Blockchain DB size in bytes |
| `free_space` | int | Free disk space in bytes on the data-dir volume |
| `version` | string | Daemon version string |
| `nettype` | string | `"mainnet"`, `"testnet"`, or `"stagenet"` |

**Quick sync progress:**
```bash
curl -s http://127.0.0.1:19081/get_info | python3 -c "
import json, sys
d = json.load(sys.stdin)
h, t = d['height'], d['target_height']
pct = (h / t * 100) if t else 100
print(f'Height: {h} / {t}  ({pct:.1f}% synced)')
print(f'Peers: {d[\"outgoing_connections_count\"]} out / {d[\"incoming_connections_count\"]} in')
print(f'Status: {d[\"status\"]}  |  Synchronized: {d[\"synchronized\"]}')
"
```

---

## Ports & Firewall

| Port | Protocol | Purpose | Exposure |
|---|---|---|---|
| `19080` | TCP | P2P (peer discovery, block relay, tx propagation) | Internet-facing (inbound + outbound) |
| `19081` | TCP | JSON-RPC API | Localhost only |
| `19082` | TCP | ZMQ pub/sub | Localhost only |

### macOS firewall

macOS does not block outbound connections by default, so your node will connect to peers and sync without any firewall changes.

For **inbound** connections (peers connecting to you — improves network health):

1. Open **System Settings → Network → Firewall**
2. Make sure the firewall is turned on
3. Click **Options…**
4. Click **+** and add `/usr/local/bin/velkarod`
5. Set it to **Allow incoming connections**

**Router / NAT port forwarding:**

If your Mac is behind a home router (which it almost certainly is), you must forward port 19080 to your Mac's local IP address:

1. Find your Mac's local IP: `ipconfig getifaddr en0` (Wi-Fi) or `ipconfig getifaddr en1` (Ethernet)
2. Log in to your router admin panel (usually `192.168.1.1` or `192.168.0.1`)
3. Find "Port Forwarding" or "NAT" settings
4. Add a rule: **External port 19080 → Internal IP:19080, TCP**

Without port forwarding, `incoming_connections_count` will remain `0`. Your node still syncs and participates in the network (outbound works fine), but you contribute less to P2P connectivity.

**Verify inbound reachability:**
```bash
# From another machine or using an online port checker:
nc -zv YOUR_PUBLIC_IP 19080
```

### Linux firewall

```bash
# Ubuntu UFW
sudo ufw allow 19080/tcp
sudo ufw status

# iptables
sudo iptables -A INPUT -p tcp --dport 19080 -j ACCEPT
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

**Never expose port 19081 or 19082 to the internet.** The RPC server has no authentication by default and grants full control of the node.

---

## Upgrading

When a new version is released:

```bash
cd /path/to/Velkavo

# Pull latest code
git fetch origin
git checkout main
git pull

# Update submodules (new submodule versions may be pinned)
git submodule update --init --recursive

# Reapply the wallet-crypto fix if it was lost (check first)
grep -q "velkavo_crypto_autodetect" src/crypto/wallet/CMakeLists.txt \
  && echo "fix already present" \
  || echo "fix needed — reapply step 6"

# Rebuild (cmake reconfigures automatically on changes)
cd build/release
make daemon -j$(sysctl -n hw.logicalcpu)   # macOS
make daemon -j$(nproc)                      # Linux
```

After building, replace the binary:

```bash
# macOS (if using system-wide install)
sudo cp build/release/bin/velkarod /usr/local/bin/velkarod

# Restart the service
launchctl stop com.velkavo.node    # macOS launchd (auto-restarts due to KeepAlive)
sudo systemctl restart velkarod    # Linux systemd
```

The node resumes syncing from where it left off — no re-sync needed on upgrades.

---

## Stopping the Node Gracefully

Always stop the node gracefully to avoid database corruption.

```bash
# macOS — if running as launchd service (stops and auto-restarts due to KeepAlive)
launchctl stop com.velkavo.node

# macOS — to stop permanently until manually started again
launchctl unload ~/Library/LaunchAgents/com.velkavo.node.plist

# macOS — if running in foreground
# Press Ctrl+C once; the node saves state and exits cleanly

# macOS — if running with --detach
kill -SIGTERM $(cat ~/.velkavo/velkarod.pid)

# Linux systemd
sudo systemctl stop velkarod
```

Do **not** use `kill -9` (SIGKILL) — it bypasses the graceful shutdown and may corrupt the LMDB database.

---

## Uninstalling

```bash
# Stop the service
launchctl unload ~/Library/LaunchAgents/com.velkavo.node.plist   # macOS
sudo systemctl disable --now velkarod                             # Linux

# Remove the plist / unit file
rm ~/Library/LaunchAgents/com.velkavo.node.plist   # macOS
sudo rm /etc/systemd/system/velkarod.service        # Linux

# Remove the binary
sudo rm /usr/local/bin/velkarod

# Remove config
sudo rm -rf /etc/velkavo

# Remove blockchain data (irreversible — you will need to re-sync from scratch)
rm -rf ~/.velkavo
sudo rm -rf /var/lib/velkavo /var/log/velkavo   # if using system paths
```

---

## Troubleshooting

### Port 19080 already in use

```
FATAL Error starting server: Failed to bind IPv4 (set to required)
```

Another `velkarod` process is already running. Find and stop it:

```bash
pgrep -l velkarod
pkill velkarod     # sends SIGTERM — graceful
```

Wait a few seconds for the port to be released, then restart.

### Node connects 0 outbound peers

- Check that `seeds.velkavo.com` resolves: `dig seeds.velkavo.com`
- Check your internet connection
- Try adding a known peer manually in the config: `add-peer=<ip>:19080`

### incoming_connections_count stays at 0

You likely do not have port 19080 forwarded through your router. See the firewall section above. Having 0 inbound is not fatal — your node syncs correctly through outbound connections.

### Database corruption after unclean shutdown

If the node was killed with SIGKILL or the machine lost power mid-write:

```bash
velkarod --config-file ~/.velkavo/velkavo.conf --non-interactive
# The node will attempt LMDB recovery automatically on next start
```

If recovery fails:
```bash
# Remove only the blockchain DB, keep your config
rm -rf ~/.velkavo/lmdb
# The node will re-sync from scratch on next start
```

### Build error: cannot find -lssl or -lcrypto

OpenSSL is keg-only on macOS (not linked into standard paths). Pass its prefix explicitly:

```bash
cmake -DCMAKE_BUILD_TYPE=Release -DMANUAL_SUBMODULES=1 \
  -DOPENSSL_ROOT_DIR=$(brew --prefix openssl) \
  /path/to/Velkavo
```

### Build error: Boost not found

```bash
brew reinstall boost
# Then re-run cmake
```

### macOS Gatekeeper blocks velkarod

If macOS shows "velkarod cannot be opened because the developer cannot be verified":

```bash
xattr -d com.apple.quarantine /usr/local/bin/velkarod
```

Or: **System Settings → Privacy & Security → scroll down → Allow Anyway**.

### High CPU usage after sync completes

Normal during initial sync. After `synchronized: true`, CPU usage drops significantly. If CPU remains high after sync, check `log-level` — level 3 or 4 generates very heavy I/O and CPU load; set it back to `1`.

### Log file grows too large

The daemon rotates logs automatically. The defaults keep up to 10 files of 100 MB each (1 GB total). To reduce:

```ini
max-log-file-size=10485760   # 10 MB per file
max-log-files=3              # keep 3 rotated files
```
