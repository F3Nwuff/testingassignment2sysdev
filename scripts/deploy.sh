#!/usr/bin/env bash
set -euo pipefail

: "${AWS_PROFILE:=default}"
: "${AWS_REGION:=us-east-1}"
: "${TF_DIR:=infra}"
: "${ANSIBLE_DIR:=ansible}"
: "${SSH_PRIV_KEY:=~/.ssh/assignment2key}"
: "${ANSIBLE_FORKS:=10}"

command -v aws >/dev/null
command -v terraform >/dev/null
command -v ansible-playbook >/dev/null

aws sts get-caller-identity --profile "$AWS_PROFILE" >/dev/null

terraform -chdir="$TF_DIR" init -input=false
terraform -chdir="$TF_DIR" apply -auto-approve -input=false

# task 6
FRONTEND_IP=$(terraform -chdir="$TF_DIR" output -json frontend_public_ip | jq -r .)
BACKEND_IP=$(terraform -chdir="$TF_DIR"  output -json backend_public_ip  | jq -r .)
DB_IP=$(terraform -chdir="$TF_DIR"       output -json db_private_ip       | jq -r .)
SSH_USER=$(terraform -chdir="$TF_DIR"    output -json ssh_user           | jq -r .)

DB_PRIV_IP=$(terraform -chdir="$TF_DIR" output -raw db_private_ip 2>/dev/null || true)

# task 6 (inventory)
INV_FILE="$(mktemp)"
cat > "$INV_FILE" <<EOF
[db_host]
${DB_IP} ansible_user=${SSH_USER} ansible_ssh_private_key_file=${SSH_PRIV_KEY} ansible_ssh_common_args='-o ProxyCommand="ssh -i ${SSH_PRIV_KEY} -W %h:%p -o StrictHostKeyChecking=no ${SSH_USER}@${BACKEND_IP}"'

[backend_host]
${BACKEND_IP} ansible_user=${SSH_USER} ansible_ssh_private_key_file=${SSH_PRIV_KEY}

[frontend_host]
${FRONTEND_IP} ansible_user=${SSH_USER} ansible_ssh_private_key_file=${SSH_PRIV_KEY}
EOF

ANSIBLE_HOST_KEY_CHECKING=False \
ansible-playbook -i "$INV_FILE" "$ANSIBLE_DIR/site.yml" --forks "$ANSIBLE_FORKS" --ssh-extra-args="-o StrictHostKeyChecking=no"

echo "FRONTEND: http://$FRONTEND_IP/"
echo "BACKEND:  http://$BACKEND_IP:8080/"
[ -n "${DB_PRIV_IP:-}" ] && echo "DB (private): $DB_PRIV_IP"
echo "SSH (frontend):  ssh -i $SSH_PRIV_KEY $SSH_USER@$FRONTEND_IP"
echo "SSH (backend):   ssh -i $SSH_PRIV_KEY $SSH_USER@$BACKEND_IP"
