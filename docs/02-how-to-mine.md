# How to Mine Velkavo (VKV)

Mining secures the Velkavo network and rewards you with newly created VKV coins. Velkavo uses the **RandomX** proof-of-work algorithm, which is optimized for CPU mining — GPUs have no significant advantage.

---

## Requirements

- A running and synced Velkavo node (see [01-run-a-node.md](01-run-a-node.md))
- A Velkavo wallet address to receive rewards (see [03-create-a-wallet.md](03-create-a-wallet.md))
- A CPU (the more cores, the better)

---

## Option 1 — Mine via the Node Daemon (Built-in)

The simplest way. Your node mines directly using its built-in miner.

### Start mining

Connect to the daemon console and run:

```bash
# If running interactively (no --non-interactive flag):
start_mining <YOUR_WALLET_ADDRESS> <NUMBER_OF_THREADS>
```

Example:
```bash
start_mining VKVabc123... 4
```

Replace `VKVabc123...` with your wallet address and `4` with the number of CPU threads to use (leave 1-2 free for the OS).

### Check mining status

```bash
mining_status
```

Output shows hashrate, thread count, and whether you are actively mining.

### Stop mining

```bash
stop_mining
```

### Enable mining at startup (via config)

Add to your `velkavo.conf`:

```ini
start-mining=<YOUR_WALLET_ADDRESS>
mining-threads=4
```

The node will begin mining automatically on start.

---

## Option 2 — Mine via RPC (Node Running Non-Interactively)

If your node is running with `--non-interactive`, control mining through the RPC API.

### Start mining
```bash
curl -s http://127.0.0.1:19081/start_mining \
  -d '{"do_background_mining": false, "ignore_battery": true, "miner_address": "<YOUR_WALLET_ADDRESS>", "threads_count": 4}' \
  -H 'Content-Type: application/json'
```

### Check status
```bash
curl -s http://127.0.0.1:19081/mining_status | python3 -m json.tool
```

Key fields:

| Field | Meaning |
|---|---|
| `active` | `true` if mining |
| `speed` | Hashrate in H/s |
| `threads_count` | Number of mining threads |
| `address` | Wallet receiving rewards |

### Stop mining
```bash
curl -s http://127.0.0.1:19081/stop_mining -d '{}' -H 'Content-Type: application/json'
```

---

## Choosing Thread Count

| CPU cores | Recommended threads |
|---|---|
| 2 | 1 |
| 4 | 3 |
| 8 | 6 |
| 16+ | `nproc` − 2 |

Leave at least 1-2 cores free so the node stays responsive.

---

## Mining Rewards

- Block reward starts at **17.592186 VKV** and decreases over time (tail emission)
- Rewards go directly to your wallet address after the block is confirmed
- Early network = lower difficulty = higher chance of finding blocks

---

## Notes

- You must be **fully synced** before mining. Check with `curl -s http://127.0.0.1:19081/get_info | python3 -m json.tool` — `synchronized` should be `true`.
- Mining on a **rotating HDD** is slow. An SSD is strongly recommended.
- RandomX performs best when the CPU supports **large pages**. On Linux:
  ```bash
  sudo sysctl -w vm.nr_hugepages=1168
  ```
