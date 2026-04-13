# Valkavo Manual Bootstrapping

If DNS seeds (`seeds.valkavo.com`) are unavailable, you can add known peer IPs
manually to your config file:

1. Open `/etc/valkavo/valkavo.conf`
2. Add one or more lines:
   ```
   add-peer=KNOWN_PEER_IP:19080
   ```
3. Restart: `sudo systemctl restart valkarod`

To find known peer IPs, ask in the Valkavo community channels (Discord / Telegram / forum).
Once your node connects successfully even once, it saves peer addresses in `p2pstate.bin`
inside your data directory and uses them automatically on all future restarts —
no DNS or manual peers needed after that first connection.
