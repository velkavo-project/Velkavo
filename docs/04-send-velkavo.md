# How to Send Velkavo (VKV)

Sending VKV requires an open wallet connected to a synced node. Transactions are private by default — the sender, receiver, and amount are not visible on the public blockchain.

---

## Requirements

- `velkavo-wallet-cli` binary (see [03-create-a-wallet.md](03-create-a-wallet.md))
- A wallet with a balance
- A running Velkavo node (local or remote)

---

## Step 1 — Open Your Wallet

```bash
./velkavo-wallet-cli --wallet-file my-wallet --daemon-host 127.0.0.1 --daemon-port 19081
```

Enter your password when prompted.

---

## Step 2 — Sync Your Balance

```bash
refresh
```

Wait for the sync to complete, then check your balance:

```bash
balance
```

Your **unlocked balance** is what you can spend. Newly received coins are locked for 10 blocks (~20 minutes) before they can be sent.

---

## Step 3 — Send VKV

```bash
transfer <RECIPIENT_ADDRESS> <AMOUNT>
```

**Example — send 10 VKV:**
```bash
transfer VKVabc123def456... 10
```

**Example — send all funds:**
```bash
transfer VKVabc123def456... all
```

The wallet will show a confirmation prompt with the amount, fee, and recipient. Type `yes` to confirm.

---

## Transaction Fees

Fees are calculated automatically based on network conditions. The wallet shows the fee before you confirm. Typical fees are very small (a few millivkavo).

To set a priority level (affects fee and confirmation speed):

```bash
transfer <ADDRESS> <AMOUNT> <PRIORITY>
```

| Priority | Value | Speed |
|---|---|---|
| Default | 0 | Normal |
| Unimportant | 1 | Slow, lower fee |
| Normal | 2 | Standard |
| Elevated | 3 | Faster |
| Priority | 4 | Fastest, highest fee |

Example — high priority:
```bash
transfer VKVabc123... 10 4
```

---

## Step 4 — Verify the Transaction

After sending, the wallet prints a **Transaction ID (txid)**. Save it.

Check the status in the wallet:
```bash
show_transfers
```

Or check a specific transaction:
```bash
get_tx_key <TXID>
```

The recipient can verify receipt using the tx key (without revealing your identity).

---

## Sending with Payment ID (for exchanges)

Some exchanges require a payment ID to identify your deposit:

```bash
transfer <ADDRESS> <AMOUNT> <PRIORITY> <PAYMENT_ID>
```

Or use an **integrated address** (address + payment ID combined):
```bash
integrated_address
```

This generates a single address that includes a payment ID — share this with the exchange instead of a separate payment ID.

---

## Sweep All Funds to Another Wallet

To move everything to a new address (e.g. upgrading wallet):

```bash
sweep_all <DESTINATION_ADDRESS>
```

This sends your entire unlocked balance in one or more transactions and handles the fee automatically.

---

## Common Issues

| Problem | Fix |
|---|---|
| `Not enough unlocked money` | Wait for coins to unlock (10 blocks ~20 min) |
| `No connection to daemon` | Check node is running: `curl http://127.0.0.1:19081/get_info` |
| `Transaction not found` | Sync the wallet with `refresh` |
| `Error: invalid address` | Double-check recipient address — Velkavo addresses are case-sensitive |

---

## Always Exit Cleanly

```bash
exit
```

Always use `exit` instead of Ctrl+C. This saves your wallet's sync state so you don't have to re-scan the blockchain next time.
