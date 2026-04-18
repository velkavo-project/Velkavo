# Velkavo (VKV) — Complete User Guide

Velkavo (VKV) is a privacy-focused cryptocurrency. Transactions are private by default — the sender, receiver, and amount are hidden on the blockchain using RingCT, stealth addresses, and Dandelion++ networking.

This guide covers everything you need to go from zero to mining and sending VKV.

---

## Table of Contents

1. [Requirements](#requirements)
2. [Build from Source](#build-from-source)
   - [macOS](#macos)
   - [Linux (Ubuntu/Debian)](#linux-ubuntudebian)
3. [Running a Node](#running-a-node)
   - [Configuration](#configuration)
   - [Start the Node](#start-the-node)
   - [Run as a Background Service](#run-as-a-background-service)
   - [Check Node Status](#check-node-status)
4. [Create a Wallet](#create-a-wallet)
5. [Restore a Wallet from Seed Phrase](#restore-a-wallet-from-seed-phrase)
6. [Receive VKV](#receive-vkv)
7. [How to Mine](#how-to-mine)
   - [Option A — Built-in Miner](#option-a--built-in-miner-simple)
   - [Option B — XMRig (Recommended)](#option-b--xmrig-recommended)
8. [Send VKV](#send-vkv)
9. [Wallet Security and Backup](#wallet-security-and-backup)
10. [Network Reference](#network-reference)
11. [Troubleshooting](#troubleshooting)

---

## Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| OS | macOS 13 / Ubuntu 20.04 | macOS 14+ / Ubuntu 22.04+ |
| CPU | 2 cores | 8+ cores (for mining) |
| RAM | 2 GB | 4 GB+ (2 GB per mining thread) |
| Disk | 50 GB free SSD | 100 GB+ SSD |
| Network | Stable internet | 10+ Mbps, port 19080 open |

> A spinning hard drive will cause severe sync lag. Use an SSD.

---

## Build from Source

### macOS

**1. Install Xcode Command Line Tools**

```bash
xcode-select --install
```

A dialog will appear — click Install. Verify when done:

```bash
clang --version
# Apple clang version 15.x.x or later
```

**2. Install Homebrew (if not already installed)**

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

On Apple Silicon, add Homebrew to your PATH after install:

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

**3. Install build dependencies**

```bash
brew install cmake boost openssl zeromq unbound libsodium hidapi readline
```

**4. Clone the repository**

```bash
git clone --recurse-submodules https://github.com/velkavo-project/Velkavo.git
cd Velkavo
```

**5. Apply the wallet-crypto CMake fix**

```bash
sed -i '' '38s/.*/if (NOT COMMAND velkavo_crypto_autodetect)\n  function(velkavo_crypto_autodetect AVAILABLE_VAR BEST_VAR)\n    # Stub: fall back to internal "cn"\n  endfunction()\nendif()\n\n&/' src/crypto/wallet/CMakeLists.txt
```

**6. Build**

```bash
mkdir -p build/release && cd build/release
cmake -DCMAKE_BUILD_TYPE=Release -DMANUAL_SUBMODULES=1 \
  -DOPENSSL_ROOT_DIR=$(brew --prefix openssl) \
  ../..
make -j$(sysctl -n hw.logicalcpu)
```

Build time: ~10–15 min on M1, ~6 min on M2 Pro.

**Binaries are in `build/release/bin/`:**

| Binary | Purpose |
|--------|---------|
| `velkarod` | Node daemon |
| `velkavo-wallet-cli` | Wallet command-line interface |

Verify:

```bash
./build/release/bin/velkarod --version
# Velkavo 'Fluorine Fermi' (v0.18.1.0-...)
```

---

### Linux (Ubuntu/Debian)

**1. Install dependencies**

```bash
sudo apt-get update
sudo apt-get install -y build-essential cmake pkg-config \
  libboost-all-dev libssl-dev libzmq3-dev libunbound-dev \
  libsodium-dev libhidapi-dev liblzma-dev libreadline-dev
```

**2. Clone and build**

```bash
git clone --recurse-submodules https://github.com/velkavo-project/Velkavo.git
cd Velkavo

# Apply the wallet-crypto fix
sed -i '38s/.*/if (NOT COMMAND velkavo_crypto_autodetect)\n  function(velkavo_crypto_autodetect AVAILABLE_VAR BEST_VAR)\n  endfunction()\nendif()\n\n&/' src/crypto/wallet/CMakeLists.txt

mkdir -p build/release && cd build/release
cmake -DCMAKE_BUILD_TYPE=Release -DMANUAL_SUBMODULES=1 ../..
make -j$(nproc)
```

**Install binaries system-wide (optional but recommended):**

```bash
sudo cp build/release/bin/velkarod /usr/local/bin/
sudo cp build/release/bin/velkavo-wallet-cli /usr/local/bin/
```

---

## Running a Node

A node connects you to the Velkavo network, validates transactions, and is required for mining and sending transactions. You do not need to mine to run a node.

### Configuration

Create the data directory and config file:

**macOS:**
```bash
mkdir -p ~/.velkavo
```

Create `~/.velkavo/velkavo.conf`:

```ini
# Paths
data-dir=/Users/YOUR_USERNAME/.velkavo
log-file=/Users/YOUR_USERNAME/.velkavo/velkarod.log
log-level=1
max-log-file-size=104857600
max-log-files=5

# P2P
p2p-bind-port=19080
p2p-external-port=19080

# RPC — localhost only, do NOT expose to internet
rpc-bind-ip=127.0.0.1
rpc-bind-port=19081

# Connection limits
out-peers=64
in-peers=128

# Bandwidth (kB/s)
limit-rate-up=8192
limit-rate-down=32768
```

Replace `YOUR_USERNAME` with the output of `whoami`.

**Linux** — same content, stored at `/etc/velkavo/velkavo.conf` with paths like:
```ini
data-dir=/var/lib/velkavo
log-file=/var/log/velkavo/velkarod.log
```

**Config options reference:**

| Option | Description |
|--------|-------------|
| `data-dir` | Blockchain database location. Needs 50 GB+ free. |
| `log-level` | `0` = errors only, `1` = info (recommended), `2` = debug |
| `p2p-bind-port` | Port peers connect to you on. Must be open in firewall. |
| `rpc-bind-port` | Local API port. Keep on `127.0.0.1` — never expose publicly. |
| `out-peers` | Max outbound peer connections. |
| `in-peers` | Max inbound peer connections. |
| `add-peer` | Manually add a peer, e.g. `add-peer=80.225.231.55:19080` |
| `start-mining` | Auto-start mining on launch: `start-mining=<YOUR_ADDRESS>` |
| `mining-threads` | Threads for auto-start mining: `mining-threads=4` |
| `public-node` | Set to `1` to allow remote wallets to use your node |

---

### Start the Node

**Foreground (test / verify it works):**

```bash
velkarod --config-file ~/.velkavo/velkavo.conf --non-interactive
```

Press `Ctrl+C` to stop. The node discovers peers automatically via `seeds.velkavo.com`.

**Background (detached, no service manager):**

```bash
velkarod \
  --config-file ~/.velkavo/velkavo.conf \
  --detach \
  --pidfile ~/.velkavo/velkarod.pid
```

Stop it:
```bash
kill $(cat ~/.velkavo/velkarod.pid)
```

---

### Run as a Background Service

#### macOS — launchd

Install the binary system-wide first:

```bash
sudo cp build/release/bin/velkarod /usr/local/bin/velkarod
```

Create `~/Library/LaunchAgents/com.velkavo.node.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.velkavo.node</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/velkarod</string>
        <string>--config-file</string>
        <string>/Users/YOUR_USERNAME/.velkavo/velkavo.conf</string>
        <string>--non-interactive</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>ThrottleInterval</key>
    <integer>10</integer>
    <key>StandardOutPath</key>
    <string>/Users/YOUR_USERNAME/.velkavo/velkarod.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/YOUR_USERNAME/.velkavo/velkarod.err</string>
</dict>
</plist>
```

Replace `YOUR_USERNAME` with your actual username.

Load and start:
```bash
launchctl load ~/Library/LaunchAgents/com.velkavo.node.plist
launchctl start com.velkavo.node
```

| Action | Command |
|--------|---------|
| Start | `launchctl start com.velkavo.node` |
| Stop temporarily | `launchctl stop com.velkavo.node` |
| Disable permanently | `launchctl unload ~/Library/LaunchAgents/com.velkavo.node.plist` |
| Re-enable | `launchctl load ~/Library/LaunchAgents/com.velkavo.node.plist` |
| View logs | `tail -f ~/.velkavo/velkarod.log` |

#### Linux — systemd

```bash
# Create dedicated user
sudo useradd -r -s /bin/false velkavo

# Create directories
sudo mkdir -p /etc/velkavo /var/lib/velkavo /var/log/velkavo
sudo chown velkavo:velkavo /var/lib/velkavo /var/log/velkavo

# Install binary
sudo cp build/release/bin/velkarod /usr/local/bin/velkarod
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

| Action | Command |
|--------|---------|
| Start | `sudo systemctl start velkarod` |
| Stop | `sudo systemctl stop velkarod` |
| Status | `sudo systemctl status velkarod` |
| View logs | `sudo journalctl -fu velkarod` |

---

### Check Node Status

```bash
curl -s http://127.0.0.1:19081/get_info | python3 -m json.tool
```

Quick sync progress:

```bash
curl -s http://127.0.0.1:19081/get_info | python3 -c "
import json, sys
d = json.load(sys.stdin)
h, t = d['height'], d['target_height']
pct = (h / t * 100) if t else 100.0
print(f'Height:  {h} / {t}  ({pct:.1f}% synced)')
print(f'Peers:   {d[\"outgoing_connections_count\"]} out / {d[\"incoming_connections_count\"]} in')
print(f'Status:  {d[\"status\"]}  |  Synchronized: {d[\"synchronized\"]}')
"
```

Key fields:

| Field | Meaning |
|-------|---------|
| `synchronized: true` | Fully caught up — safe to mine and transact |
| `height` | Your node's current block height |
| `target_height` | Network tip (0 once synced) |
| `outgoing_connections_count` | Peers you are connected to (should be > 0) |
| `incoming_connections_count` | Peers connected to you (requires open port 19080) |

> You must be fully synchronized before mining or sending transactions. Mining on an unsynced node will produce orphaned blocks.

---

## Create a Wallet

Build the wallet CLI first (if you only built the daemon):

```bash
cd build/release
make velkavo-wallet-cli -j$(sysctl -n hw.logicalcpu)   # macOS
make velkavo-wallet-cli -j$(nproc)                      # Linux
```

**Create a new wallet:**

```bash
./build/release/bin/velkavo-wallet-cli --generate-new-wallet ~/my-wallet
```

You will be asked to set a password. Choose a strong one.

Example output:

```
Generated new wallet: /home/user/my-wallet
View key: <64-char hex>

Your wallet has been generated!

NOTE: the following 25 words can be used to recover access to your wallet.
Write them down and store them somewhere safe and secure.

word1 word2 word3 word4 word5 word6 word7 word8 word9 word10
word11 word12 word13 word14 word15 word16 word17 word18 word19 word20
word21 word22 word23 word24 word25
```

**Write down your 25-word seed phrase immediately and store it offline.** Anyone with these words can steal your funds. This is the only way to recover your wallet if you lose the file.

Inside the wallet CLI, run these commands to get started:

```
address       # shows your VKV wallet address
refresh       # syncs with the node
balance       # shows your balance
```

**Wallet files:**

| File | Contents | Back up? |
|------|----------|----------|
| `my-wallet` | Cached blockchain scan data | No — can be re-synced |
| `my-wallet.keys` | Your private keys | YES — critical |

**Always exit the wallet using the `exit` command, not Ctrl+C.** Ctrl+C does not save your sync state and you will need to re-scan on the next launch.

---

## Restore a Wallet from Seed Phrase

If you have your 25-word seed phrase but lost your wallet file:

```bash
./build/release/bin/velkavo-wallet-cli --restore-deterministic-wallet
```

You will be asked to:
1. Enter a filename for the new wallet
2. Enter your 25-word seed phrase
3. Set a new password
4. Optionally enter the block height when the wallet was created (speeds up scan — if unknown, enter `0`)

The wallet will restore and scan the blockchain for your transaction history. This may take time if scanning from block 0.

**Restore from a specific block height:**

If you know approximately when you created the wallet, enter that block height to skip scanning older blocks:

```bash
./build/release/bin/velkavo-wallet-cli --restore-deterministic-wallet --restore-height <BLOCK_HEIGHT>
```

---

## Receive VKV

**Get your wallet address:**

Inside the wallet CLI:
```
address
```

Your address starts with `VKV...` — share this with anyone who wants to send you VKV.

**Check incoming payments:**

```
refresh
balance
show_transfers in
```

`show_transfers in` lists all incoming transactions with their amounts, block heights, and transaction IDs.

**Unlock time:**

Mining rewards and received coins are locked for **10 blocks (~10 minutes)** before they appear in your `unlocked balance` and can be spent. This is normal.

**Subaddresses (advanced — recommended for privacy):**

Instead of sharing your main address everywhere, create subaddresses — each appears as a completely different address but all payments go to the same wallet:

```
address new
```

This generates a new subaddress. Use a different subaddress for each person or service that pays you. Subaddresses are unlinkable to each other and to your main address on the blockchain.

List all your subaddresses:
```
address all
```

---

## How to Mine

Mining requires:
- A running, **fully synced** node
- A VKV wallet address to receive rewards

Block reward starts at **17.592186 VKV** and decreases over time. Early-network mining has low difficulty — now is the best time to mine.

### Option A — Built-in Miner (Simple)

The node daemon includes a built-in miner. Lower hashrate than XMRig but requires no extra software.

**If your node is running interactively (without `--non-interactive`):**

Connect to the daemon console and run:
```
start_mining <YOUR_WALLET_ADDRESS> <THREADS>
```

Example:
```
start_mining VKVabc123... 6
```

Check status:
```
mining_status
```

Stop:
```
stop_mining
```

**If your node is running with `--non-interactive` (background service):**

Use the RPC API:

```bash
# Start mining
curl -s http://127.0.0.1:19081/start_mining \
  -d '{
    "do_background_mining": false,
    "ignore_battery": true,
    "miner_address": "YOUR_WALLET_ADDRESS",
    "threads_count": 6
  }' \
  -H 'Content-Type: application/json'

# Check status
curl -s http://127.0.0.1:19081/mining_status | python3 -m json.tool

# Stop mining
curl -s http://127.0.0.1:19081/stop_mining \
  -d '{}' -H 'Content-Type: application/json'
```

**Auto-start mining when the node launches** — add to `velkavo.conf`:

```ini
start-mining=YOUR_WALLET_ADDRESS
mining-threads=6
```

---

### Option B — XMRig (Recommended)

XMRig is a dedicated miner with significantly higher hashrate than the built-in miner. Recommended for serious mining.

**1. Install XMRig**

macOS:
```bash
brew install xmrig
```

Linux:
```bash
sudo apt-get install xmrig
# or download from https://github.com/xmrig/xmrig/releases
```

**2. Enable the node's RPC for mining access**

The node's RPC must accept mining connections. In `velkavo.conf`, confirm:
```ini
rpc-bind-ip=127.0.0.1
rpc-bind-port=19081
```

**3. Run XMRig pointed at your local node**

```bash
xmrig \
  --url 127.0.0.1:19081 \
  --user YOUR_WALLET_ADDRESS \
  --pass x \
  --coin monero \
  --threads $(nproc)
```

> XMRig uses `--coin monero` because Velkavo uses the same RandomX algorithm and RPC protocol.

**4. XMRig config file (recommended for persistent setup)**

Create `~/.xmrig.json`:

```json
{
  "pools": [
    {
      "url": "127.0.0.1:19081",
      "user": "YOUR_WALLET_ADDRESS",
      "pass": "x",
      "coin": "monero"
    }
  ],
  "cpu": {
    "enabled": true,
    "max-threads-hint": 90
  }
}
```

`max-threads-hint: 90` uses 90% of your CPU cores, leaving the rest for the node and OS.

Run:
```bash
xmrig --config ~/.xmrig.json
```

**Choosing thread count:**

| CPU cores | Recommended threads | Notes |
|-----------|--------------------|----|
| 2 | 1 | Leave 1 for system |
| 4 | 3 | Leave 1 for system |
| 8 | 6 | Leave 2 for node + OS |
| 16+ | `nproc - 2` | Leave 2 for node + OS |

**Enable large pages on Linux for ~10-15% hashrate boost:**

```bash
sudo sysctl -w vm.nr_hugepages=1168
# Make permanent:
echo 'vm.nr_hugepages=1168' | sudo tee -a /etc/sysctl.conf
```

**Mining rewards unlock after 60 blocks (~60 minutes)** and then appear in your wallet balance.

---

## Send VKV

Open your wallet connected to a running node:

```bash
./build/release/bin/velkavo-wallet-cli \
  --wallet-file ~/my-wallet \
  --daemon-host 127.0.0.1 \
  --daemon-port 19081
```

Enter your password when prompted.

**Step 1 — Sync your balance**

```
refresh
balance
```

Your `unlocked balance` is what you can spend. If it shows 0 but you have received funds, they may still be locked (wait 10 blocks) or the wallet needs to refresh.

**Step 2 — Send VKV**

```
transfer <RECIPIENT_ADDRESS> <AMOUNT>
```

Example — send 10 VKV:
```
transfer VKVabc123def456... 10
```

Send all funds:
```
transfer VKVabc123def456... all
```

The wallet displays the amount, fee, and recipient before asking you to confirm. Type `yes` to send.

**Transaction priorities (affect fee and speed):**

```
transfer <ADDRESS> <AMOUNT> <PRIORITY>
```

| Priority | Number | Speed |
|----------|--------|-------|
| Default | 0 | Standard |
| Low | 1 | Slow, lower fee |
| Normal | 2 | Standard |
| High | 3 | Faster |
| Urgent | 4 | Fastest, highest fee |

**Step 3 — Confirm the transaction**

After sending, the wallet prints a **Transaction ID (txid)**. Save it.

View your transaction history:
```
show_transfers
```

Get the transaction key (allows recipient to verify payment):
```
get_tx_key <TXID>
```

**Sweep all funds to a new address:**

```
sweep_all <DESTINATION_ADDRESS>
```

Useful when moving to a new wallet or consolidating funds.

**For exchanges — integrated address (address + payment ID combined):**

```
integrated_address
```

Share the generated integrated address instead of a payment ID + address separately.

**Remote node (no local node needed):**

To use the wallet without running your own node, connect to a Velkavo seed node:

```bash
./velkavo-wallet-cli \
  --wallet-file ~/my-wallet \
  --daemon-host 80.225.231.55 \
  --daemon-port 19081
```

> Using a remote node means that node can see your IP address and which transactions you query. For maximum privacy, run your own node.

**Always exit cleanly:**
```
exit
```

Never close the terminal window directly — this loses your sync state and requires a full re-scan next time.

---

## Wallet Security and Backup

**What to back up:**

| Item | How | Where to store |
|------|-----|----------------|
| 25-word seed phrase | Write on paper | Fireproof safe, separate from computer |
| `my-wallet.keys` file | Copy to USB drive | Offline, encrypted |
| Wallet password | Memory or password manager | Not on the same device as the keys |

**Encrypt your wallet file backup:**

```bash
# Encrypt with GPG
gpg --symmetric --cipher-algo AES256 my-wallet.keys

# Store my-wallet.keys.gpg on USB drive
```

**Never:**
- Share your seed phrase or `.keys` file with anyone
- Store your seed phrase as a photo or digital text
- Enter your seed phrase on a website or app you don't fully trust
- Run wallet software on an internet-connected server

**View-only wallet (monitor balance without risk):**

If you want to check your balance on an untrusted or internet-facing machine, create a view-only wallet — it can see incoming transactions but cannot spend:

```bash
./velkavo-wallet-cli --generate-from-view-key view-only-wallet
```

You will be asked for your address and view key (get the view key with `viewkey` inside your main wallet).

---

## Network Reference

| Property | Value |
|----------|-------|
| Coin name | Velkavo |
| Ticker | VKV |
| Algorithm | RandomX (CPU, ASIC-resistant) |
| Block time | ~60 seconds |
| Unlock time (mining rewards) | 60 blocks (~60 minutes) |
| Unlock time (received transactions) | 10 blocks (~10 minutes) |
| Starting block reward | 17.592186 VKV |
| DNS seeds | `seeds.velkavo.com` |
| Seed nodes | `80.225.231.55:19080`, `141.148.194.210:19080` |

**Ports:**

| Network | P2P | RPC | ZMQ |
|---------|-----|-----|-----|
| Mainnet | 19080 | 19081 | 19082 |
| Testnet | 29080 | 29081 | 29082 |
| Stagenet | 39080 | 39081 | 39082 |

**Firewall rules:**

- Open port **19080** (P2P) inbound — lets other nodes connect to you, improves the network
- Keep port **19081** (RPC) on localhost only — never expose this to the internet
- Port **19082** (ZMQ) — only needed for ZMQ event subscriptions

Ubuntu UFW:
```bash
sudo ufw allow 19080/tcp
```

---

## Troubleshooting

**Node won't connect to peers (`outgoing_connections_count: 0`)**

Check DNS resolves:
```bash
dig seeds.velkavo.com
```

Add seed nodes manually to `velkavo.conf`:
```ini
add-peer=80.225.231.55:19080
add-peer=141.148.194.210:19080
```

**Node stuck at the same block height**

Your node may be on a fork or have a corrupt block. Stop the node, delete only the blockchain database (your wallet is separate), and resync:

```bash
rm -rf ~/.velkavo/lmdb
velkarod --config-file ~/.velkavo/velkavo.conf --non-interactive
```

**Wallet shows `Not enough unlocked money`**

Mining rewards unlock after 60 blocks. Received transactions unlock after 10 blocks. Wait and run `refresh` again.

**Wallet shows 0 balance but I have received funds**

Run `refresh` to sync. If still 0, the wallet may need a full rescan:
```
rescan_blockchain
```

**Mining status shows `active: false` after starting**

The node must be fully synced before mining works. Check `synchronized: true` via:
```bash
curl -s http://127.0.0.1:19081/get_info | python3 -c "import json,sys; d=json.load(sys.stdin); print('Synced:', d['synchronized'])"
```

**Build error: `Could NOT find OpenSSL`**

```bash
cmake -DCMAKE_BUILD_TYPE=Release -DMANUAL_SUBMODULES=1 \
  -DOPENSSL_ROOT_DIR=$(brew --prefix openssl) \
  ../..
```

**Build error: `Unknown CMake command "velkavo_crypto_autodetect"`**

The wallet-crypto patch was not applied. Re-run step 5 of the build instructions.

**macOS: "velkarod cannot be opened because the developer cannot be verified"**

```bash
xattr -d com.apple.quarantine /usr/local/bin/velkarod
```

Or: System Settings → Privacy & Security → scroll down → Allow Anyway.

**Port 19080 already in use**

Another velkarod instance is running. Stop it:
```bash
pkill velkarod
```

**Wallet out of sync after restore**

If your restored wallet shows the wrong balance, rescan from block 0:
```
rescan_blockchain
```

This is slow but thorough. If you know the approximate block height when your wallet was first used, you can stop and restore again with `--restore-height` to skip older blocks.

---

## Common Wallet Commands Reference

| Command | Description |
|---------|-------------|
| `address` | Show your main wallet address |
| `address new` | Create a new subaddress |
| `address all` | List all subaddresses |
| `balance` | Show total and unlocked balance |
| `refresh` | Sync wallet with the node |
| `transfer <addr> <amount>` | Send VKV |
| `sweep_all <addr>` | Send entire balance to an address |
| `show_transfers` | Show all transaction history |
| `show_transfers in` | Show incoming transactions only |
| `show_transfers out` | Show outgoing transactions only |
| `get_tx_key <txid>` | Get proof key for a sent transaction |
| `viewkey` | Show your view key (for view-only wallets) |
| `seed` | Show your 25-word seed phrase (keep private) |
| `integrated_address` | Generate an integrated address + payment ID |
| `rescan_blockchain` | Full wallet rescan from block 0 |
| `help` | List all available commands |
| `exit` | Save and quit (always use this) |
