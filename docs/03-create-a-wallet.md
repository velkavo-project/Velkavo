# How to Create a Velkavo Wallet

A Velkavo wallet stores your private keys and lets you send and receive VKV. Your wallet generates a unique address and a 25-word seed phrase — keep the seed phrase safe, it is the only way to recover your funds.

---

## Requirements

Build the wallet CLI binary alongside the node:

```bash
cd build/release
make velkavo-wallet-cli -j$(nproc)        # Linux
make velkavo-wallet-cli -j$(sysctl -n hw.logicalcpu)  # macOS
```

Binary: `build/release/bin/velkavo-wallet-cli`

---

## Step 1 — Create a New Wallet

```bash
./velkavo-wallet-cli --generate-new-wallet my-wallet
```

You will be prompted for a password — choose a strong one. The wallet file `my-wallet` and `my-wallet.keys` will be created in the current directory.

**Example output:**
```
Generated new wallet: my-wallet
View key: <64-char hex>
**********************************************************************
Your wallet has been generated!
To start synchronizing with the daemon, use the "refresh" command.
Use the "help" command to see a simplified list of available commands.
Always use the "exit" command when closing velkavo-wallet-cli to save
your current session's state. Otherwise, you might lose synchronized
blockchain data.

NOTE: the following 25 words can be used to recover access to your wallet.
Write them down and store them somewhere safe and secure. Do not share
them with anyone. The wallet can be recovered with just these words.

<25-word seed phrase>
**********************************************************************
```

**Write down your 25-word seed phrase now.** Anyone with these words can access your funds.

---

## Step 2 — Note Your Wallet Address

Inside the wallet CLI, run:

```bash
address
```

This prints your public wallet address (starts with `VKV...` or a long alphanumeric string). Share this address to receive VKV.

---

## Step 3 — Connect to a Node

The wallet needs a running node to sync. If you are running a local node:

```bash
./velkavo-wallet-cli --wallet-file my-wallet --daemon-host 127.0.0.1 --daemon-port 19081
```

If you want to connect to a remote node (no local node needed):

```bash
./velkavo-wallet-cli --wallet-file my-wallet \
  --daemon-host 80.225.231.55 \
  --daemon-port 19081
```

Once connected, run `refresh` to sync your balance.

---

## Step 4 — Check Your Balance

```bash
balance
```

Output:
```
Balance: 0.000000000000 VKV, unlocked balance: 0.000000000000 VKV
```

Mining rewards and received transactions appear here after confirmation (10 blocks).

---

## Recovering a Wallet from Seed

If you lose your wallet file but have the 25-word seed phrase:

```bash
./velkavo-wallet-cli --restore-deterministic-wallet
```

Enter your seed phrase when prompted, set a new password, and the wallet will be restored.

---

## Wallet Files

| File | Contents |
|---|---|
| `my-wallet` | Cached blockchain data (can be deleted and re-synced) |
| `my-wallet.keys` | Your private keys — **back this up** |

**Never share your `.keys` file or seed phrase with anyone.**

---

## Common Wallet Commands

| Command | What it does |
|---|---|
| `balance` | Show current balance |
| `address` | Show your wallet address |
| `refresh` | Sync with the node |
| `help` | List all available commands |
| `exit` | Save and quit (always use this, not Ctrl+C) |

---

## View-Only Wallet

To create a wallet that can see incoming transactions but cannot spend:

```bash
./velkavo-wallet-cli --generate-from-view-key view-only-wallet
```

Useful for monitoring a wallet balance on an untrusted machine.
