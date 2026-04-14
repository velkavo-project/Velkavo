#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BINARY="$SCRIPT_DIR/../build/release/bin/velkarod"

# Load .env if present
ENV_FILE="$SCRIPT_DIR/../.env"
if [ -f "$ENV_FILE" ]; then
  set -o allexport; source "$ENV_FILE"; set +o allexport
fi

# Write a key (content or path) to a temp file; echo the temp path
resolve_key() {
  local key_val="${1/#\~/$HOME}"   # expand leading ~
  if [ -f "$key_val" ]; then
    echo "$key_val"   # already a file path
  else
    local tmp
    tmp=$(mktemp)
    printf -- "-----BEGIN RSA PRIVATE KEY-----\n%s\n-----END RSA PRIVATE KEY-----\n" "$key_val" > "$tmp"
    chmod 600 "$tmp"
    echo "$tmp"
  fi
}

deploy_to() {
  local vm_ip="$1"
  local key_val="$2"

  local key_file
  key_file=$(resolve_key "$key_val")

  echo "=== Deploying to $vm_ip ==="
  ssh -i "$key_file" -o StrictHostKeyChecking=accept-new ubuntu@"$vm_ip" "
    sudo apt-get install -y libboost-all-dev libssl-dev liblzma-dev libunbound-dev
    sudo useradd -r -s /bin/false velkavo 2>/dev/null || true
    sudo mkdir -p /etc/velkavo /var/lib/velkavo /var/log/velkavo
    sudo chown velkavo:velkavo /var/lib/velkavo /var/log/velkavo
  "
  scp -i "$key_file" "$BINARY"                            ubuntu@"$vm_ip":/tmp/velkarod
  scp -i "$key_file" "$SCRIPT_DIR/velkavo.conf"           ubuntu@"$vm_ip":/tmp/velkavo.conf
  scp -i "$key_file" "$SCRIPT_DIR/velkarod.service"       ubuntu@"$vm_ip":/tmp/velkarod.service
  ssh -i "$key_file" ubuntu@"$vm_ip" "
    sudo mv /tmp/velkarod /usr/local/bin/velkarod
    sudo chmod +x /usr/local/bin/velkarod
    sudo mv /tmp/velkavo.conf /etc/velkavo/velkavo.conf
    sudo mv /tmp/velkarod.service /etc/systemd/system/velkarod.service
    sudo systemctl daemon-reload
  "
  echo "=== Deploy complete for $vm_ip — run: sudo systemctl enable --now velkarod ==="
}

if [ $# -eq 2 ]; then
  # Explicit: ./deploy.sh <VM_IP> <SSH_KEY_PATH>
  deploy_to "$1" "$2"
elif [ $# -eq 0 ]; then
  # No args: deploy both VMs from .env
  if [ -z "${VM1_IP:-}" ] || [ -z "${VM2_IP:-}" ]; then
    echo "Error: set VM1_IP, VM2_IP in .env (and VM1_SSH_KEY / VM2_SSH_KEY or SSH_KEY)"
    exit 1
  fi
  KEY1="${VM1_SSH_KEY:-${SSH_KEY:-}}"
  KEY2="${VM2_SSH_KEY:-${SSH_KEY:-}}"
  if [ -z "$KEY1" ] || [ -z "$KEY2" ]; then
    echo "Error: no SSH key found — set VM1_SSH_KEY/VM2_SSH_KEY or SSH_KEY in .env"
    exit 1
  fi
  deploy_to "$VM1_IP" "$KEY1"
  deploy_to "$VM2_IP" "$KEY2"
else
  echo "Usage: $0 [<VM_IP> <SSH_KEY_PATH>]"
  echo "  With no args, reads VM1_IP, VM2_IP, VM1_SSH_KEY, VM2_SSH_KEY from .env."
  exit 1
fi
