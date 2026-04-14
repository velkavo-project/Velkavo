#!/usr/bin/env bash
set -euo pipefail

VM_IP="$1"          # e.g. 132.145.x.x
SSH_KEY="$2"        # path to your Oracle SSH private key
BINARY="$(dirname "$0")/../build/release/bin/velkarod"

echo "=== Deploying to $VM_IP ==="
ssh -i "$SSH_KEY" ubuntu@"$VM_IP" "
  sudo apt-get install -y libboost-all-dev libssl-dev liblzma-dev libunbound-dev
  sudo useradd -r -s /bin/false velkavo 2>/dev/null || true
  sudo mkdir -p /etc/velkavo /var/lib/velkavo /var/log/velkavo
  sudo chown velkavo:velkavo /var/lib/velkavo /var/log/velkavo
"
scp -i "$SSH_KEY" "$BINARY" ubuntu@"$VM_IP":/tmp/velkarod
scp -i "$SSH_KEY" "$(dirname "$0")/velkavo.conf" ubuntu@"$VM_IP":/tmp/velkavo.conf
scp -i "$SSH_KEY" "$(dirname "$0")/velkarod.service" ubuntu@"$VM_IP":/tmp/velkarod.service
ssh -i "$SSH_KEY" ubuntu@"$VM_IP" "
  sudo mv /tmp/velkarod /usr/local/bin/velkarod
  sudo chmod +x /usr/local/bin/velkarod
  sudo mv /tmp/velkavo.conf /etc/velkavo/velkavo.conf
  sudo mv /tmp/velkarod.service /etc/systemd/system/velkarod.service
  sudo systemctl daemon-reload
"
echo "=== Deploy complete for $VM_IP — run: sudo systemctl enable --now velkarod ==="
