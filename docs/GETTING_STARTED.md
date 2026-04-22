# Getting Started with Velkavo

The complete user guide is in the [README](../README.md). It covers:

1. [Requirements](../README.md#requirements)
2. [Build from Source](../README.md#build-from-source) — macOS, Linux, Windows
3. [Running a Node](../README.md#running-a-node)
4. [Create a Wallet](../README.md#create-a-wallet)
5. [How to Mine](../README.md#how-to-mine)
6. [Send VKV](../README.md#send-vkv)
7. [Troubleshooting](../README.md#troubleshooting)

## Quick Start (macOS / Linux)

**1. Build**
```bash
git clone --recurse-submodules https://github.com/velkavo-project/Velkavo.git
cd Velkavo
mkdir -p build/release && cd build/release
cmake -DCMAKE_BUILD_TYPE=Release -DMANUAL_SUBMODULES=1 ../..
make -j$(nproc 2>/dev/null || sysctl -n hw.logicalcpu)
```

**2. Start the node**
```bash
./bin/velkarod --data-dir ~/.velkavo --rpc-bind-ip 127.0.0.1 --rpc-bind-port 19081
```

Wait for `SYNCHRONIZED OK`.

**3. Create a wallet**
```bash
./bin/velkavo-wallet-cli --generate-new-wallet ~/my-wallet --daemon-port 19081
```

**4. Start mining**

Inside the wallet prompt:
```
start_mining 4
```

**5. Send VKV**

Inside the wallet prompt:
```
transfer <RECIPIENT_ADDRESS> <AMOUNT>
```

## Connect to a Public Node (no local node needed)

```bash
./bin/velkavo-wallet-cli --wallet-file ~/my-wallet --daemon-address 80.225.231.55:19083
```

## Network Ports

| Port | Purpose |
|------|---------|
| 19080 | P2P (open in firewall for incoming peers) |
| 19081 | RPC — localhost only, never expose publicly |
| 19083 | Restricted RPC — safe for public wallet connections |
