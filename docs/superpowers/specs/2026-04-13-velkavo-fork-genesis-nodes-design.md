# Velkavo Fork — Genesis Blocks & Node Network Design

**Date:** 2026-04-13
**Status:** Approved

---

## Context

VelkavoV2 is a fork of Monero being established as an independent blockchain called **Velkavo (VKV)**. The goal of this first milestone is to give Velkavo its own chain identity (genesis blocks, network IDs, coin name, address format) and launch the initial 2-node network on Oracle Cloud VMs — with peer discovery that doesn't depend on a single point of failure.

---

## Coin Identity

| Property | Value |
|---|---|
| Coin name | Velkavo |
| Ticker | VKV |
| Address prefix | Starts with `VKV` (base58-encoded prefix, numeric value calculated during implementation) |
| Domain | velkavo.com |

---

## Network Configuration

Three networks are configured: mainnet, testnet, stagenet. Each gets:
- A fresh genesis coinbase transaction (GENESIS_TX hex) generated via the built-in genesis tool
- A new genesis nonce
- A new random UUID as the Network ID (prevents cross-network peer connections with Monero)
- Distinct port assignments

| Network | P2P Port | RPC Port | ZMQ Port |
|---|---|---|---|
| Mainnet | 19080 | 19081 | 19082 |
| Testnet | 29080 | 29081 | 29082 |
| Stagenet | 39080 | 39081 | 39082 |

---

## Genesis Block Generation

Each network's genesis block is generated using Monero's built-in genesis generation tool (already present in the codebase). The resulting GENESIS_TX hex string and nonce are hardcoded into `src/cryptonote_config.h` — one set per network. This is a one-time operation; the genesis block never changes once the chain is live.

---

## Peer Discovery — DNS Seeds + Config File Fallback

**Primary: DNS seeds**
- Hostname: `seeds.velkavo.com`
- DNS A records point to both Oracle VM IPs
- Nodes resolve this hostname at startup to find initial peers
- To add/remove nodes: update the DNS A record — no recompile needed

**Fallback: config file**
- If DNS is unavailable (domain lost, DNS down), node operators add peers manually:
  ```
  add-peer=VM1_IP:19080
  add-peer=VM2_IP:19080
  ```
- This fallback procedure will be documented so the community can bootstrap independently

**Why this matters:** DNS seeds are the single point of failure risk. The config file fallback ensures the network survives even if `velkavo.com` is inaccessible. Existing running nodes are always unaffected (they maintain local peer databases); only fresh bootstrapping needs the seed mechanism.

---

## Codebase Changes

| File | Change |
|---|---|
| `src/cryptonote_config.h` | Coin name, ticker, new ports, new network UUIDs, fresh GENESIS_TX + nonce for all 3 networks |
| `src/cryptonote_basic/cryptonote_basic.h` | Address prefix numeric value producing `VKV` in base58 encoding |
| `src/p2p/net_node.inl` | Replace Monero's DNS seed hostnames with `seeds.velkavo.com` |
| `CMakeLists.txt` | Rename binary output from `monerod` → `velkarod` |

No architectural changes. All changes are configuration and identity — the Monero consensus engine, crypto, and networking stack are preserved.

---

## Deployment (2 Oracle Ubuntu VMs)

**Build:** Compile `velkarod` locally on macOS, then deploy via SCP.

**Per VM:**
1. SCP `velkarod` binary to each VM
2. Create `/etc/velkavo/velkavo.conf` with basic config (data dir, log level, no hardcoded peers)
3. Open Oracle firewall rules: TCP inbound on 19080 (P2P), 19081 (RPC), 19082 (ZMQ)
4. Start daemon: `./velkarod --config-file /etc/velkavo/velkavo.conf`

**DNS setup (in velkavo.com registrar):**
- Add A record: `seeds.velkavo.com → VM1_IP`
- Add A record: `seeds.velkavo.com → VM2_IP`

**Node connectivity:**
- Both VMs resolve `seeds.velkavo.com` and find each other automatically
- No IPs hardcoded in the binary

---

## Verification

1. `velkarod --version` — confirms binary builds and reports Velkavo name
2. Start daemon on VM1 → check logs show genesis block initialized at height 0
3. Start daemon on VM2 → check logs show it resolves `seeds.velkavo.com` and connects to VM1
4. `curl http://VM1_IP:19081/json_rpc -d '{"method":"get_info"}' -H 'Content-type: application/json'` — confirms RPC responds with Velkavo network info
5. Both nodes show `height: 0`, same genesis block hash, peer count ≥ 1
