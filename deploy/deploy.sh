#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BINARY="$SCRIPT_DIR/../build/release/bin/velkarod"

# Load .env if present
ENV_FILE="$SCRIPT_DIR/../.env"
if [ -f "$ENV_FILE" ]; then
  set -o allexport; source "$ENV_FILE"; set +o allexport
fi

deploy_to() {
  local vm_ip="$1"
  local ssh_key="$2"
  echo "=== Deploying to $vm_ip ==="
  ssh -i "$ssh_key" ubuntu@"$vm_ip" "
    sudo apt-get install -y libboost-all-dev libssl-dev liblzma-dev libunbound-dev
    sudo useradd -r -s /bin/false velkavo 2>/dev/null || true
    sudo mkdir -p /etc/velkavo /var/lib/velkavo /var/log/velkavo
    sudo chown velkavo:velkavo /var/lib/velkavo /var/log/velkavo
  "
  scp -i "$ssh_key" "$BINARY" ubuntu@"$vm_ip":/tmp/velkarod
  scp -i "$ssh_key" "$(dirname "$0")/velkavo.conf" ubuntu@"$vm_ip":/tmp/velkavo.conf
  scp -i "$ssh_key" "$(dirname "$0")/velkarod.service" ubuntu@"$vm_ip":/tmp/velkarod.service
  ssh -i "$ssh_key" ubuntu@"$vm_ip" "
    sudo mv /tmp/velkarod /usr/local/bin/velkarod
    sudo chmod +x /usr/local/bin/velkarod
    sudo mv /tmp/velkavo.conf /etc/velkavo/velkavo.conf
    sudo mv /tmp/velkarod.service /etc/systemd/system/velkarod.service
    sudo systemctl daemon-reload
  "
  echo "=== Deploy complete for $vm_ip — run: sudo systemctl enable --now velkarod ==="
}

if [ $# -eq 2 ]; then
  # Explicit: ./deploy.sh <VM_IP> <SSH_KEY>
  deploy_to "$1" "$2"
elif [ $# -eq 0 ]; then
  # No args: deploy to both VMs from .env
  if [ -z "${VM1_IP:-}" ] || [ -z "${VM2_IP:-}" ] || [ -z "${SSH_KEY:-}" ]; then
    echo "Error: set VM1_IP, VM2_IP, and SSH_KEY in .env, or pass args: $0 <VM_IP> <SSH_KEY>"
    exit 1
  fi
  deploy_to "$VM1_IP" "$SSH_KEY"
  deploy_to "$VM2_IP" "$SSH_KEY"
else
  echo "Usage: $0 [<VM_IP> <SSH_KEY>]"
  echo "  With no args, reads VM1_IP, VM2_IP, SSH_KEY from .env and deploys both."
  exit 1
fi
