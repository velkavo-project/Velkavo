#!/usr/bin/env bash
set -euo pipefail

VM_IP="$1"          # e.g. 132.145.x.x
SSH_KEY="$2"        # path to your Oracle SSH private key
BINARY="$(dirname "$0")/../build/release/bin/valkarod"

echo "=== Deploying to $VM_IP ==="
ssh -i "$SSH_KEY" ubuntu@"$VM_IP" "
  sudo apt-get install -y libboost-all-dev libssl-dev liblzma-dev libunbound-dev
  sudo useradd -r -s /bin/false valkavo 2>/dev/null || true
  sudo mkdir -p /etc/valkavo /var/lib/valkavo /var/log/valkavo
  sudo chown valkavo:valkavo /var/lib/valkavo /var/log/valkavo
"
scp -i "$SSH_KEY" "$BINARY" ubuntu@"$VM_IP":/tmp/valkarod
scp -i "$SSH_KEY" "$(dirname "$0")/valkavo.conf" ubuntu@"$VM_IP":/tmp/valkavo.conf
scp -i "$SSH_KEY" "$(dirname "$0")/valkarod.service" ubuntu@"$VM_IP":/tmp/valkarod.service
ssh -i "$SSH_KEY" ubuntu@"$VM_IP" "
  sudo mv /tmp/valkarod /usr/local/bin/valkarod
  sudo chmod +x /usr/local/bin/valkarod
  sudo mv /tmp/valkavo.conf /etc/valkavo/valkavo.conf
  sudo mv /tmp/valkarod.service /etc/systemd/system/valkarod.service
  sudo systemctl daemon-reload
"
echo "=== Deploy complete for $VM_IP — run: sudo systemctl enable --now valkarod ==="
