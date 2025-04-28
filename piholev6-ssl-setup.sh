#!/usr/bin/env bash
set -euo pipefail

# ============================= #
#   Pi-hole HTTPS Setup Script   #
# ============================= #

# === Configuration ===
ACME_HOME="${HOME}/.acme.sh"
ACME_BIN="${ACME_HOME}/acme.sh"
LOG_FILE="${HOME}/pihole-https-setup.log"
PIHOLE_TLS_PATH="/etc/pihole/tls.pem"

# === Setup Secure Logging ===
touch "$LOG_FILE"
chmod 600 "$LOG_FILE"

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

error_exit() {
  log "ERROR: $1"
  echo "Error: $1" >&2
  exit 1
}

# === Secure Cleanup on Exit ===
SECURE_TMP_DIR=""
cleanup() {
  if [[ -n "${SECURE_TMP_DIR:-}" && -d "$SECURE_TMP_DIR" ]]; then
    rm -rf "$SECURE_TMP_DIR"
    log "Cleaned up secure temp directory."
  fi
}
trap cleanup EXIT

# === Secure Temp Directory Setup ===
SECURE_TMP_DIR=$(mktemp -d "${ACME_HOME}/tmp.XXXXXXXXXX")
chmod 700 "$SECURE_TMP_DIR"

# === Check Required Tools ===
check_command() {
  command -v "$1" &>/dev/null || error_exit "'$1' command not found."
}
for cmd in curl tee cat stat sudo; do
  check_command "$cmd"
done

# === Check Sudo ===
if ! sudo -n true 2>/dev/null; then
  error_exit "User does not have passwordless sudo privileges."
fi

# === Validate Inputs ===
validate_domain() {
  [[ "$1" =~ ^([a-zA-Z0-9](-?[a-zA-Z0-9])*\.)+[a-zA-Z]{2,}$ ]]
}

validate_email() {
  [[ "$1" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]
}

validate_api_key() {
  [[ "$1" =~ ^[A-Za-z0-9._-]+$ ]]
}

validate_aws_secret() {
  [[ "$1" =~ ^[A-Za-z0-9/+=]+$ ]]
}

validate_docker_name() {
  [[ "$1" =~ ^[a-zA-Z0-9_.-]+$ ]]
}

validate_aws_credentials_file() {
  local creds_file="$HOME/.aws/credentials"
  if [ -f "$creds_file" ]; then
    local perms
    perms=$(stat -c "%a" "$creds_file")
    if [[ "$perms" != "600" && "$perms" != "400" ]]; then
      log "Fixing permissions for AWS credentials file."
      chmod 600 "$creds_file"
    fi
    grep -q 'aws_access_key_id' "$creds_file" || error_exit "AWS credentials missing aws_access_key_id."
    grep -q 'aws_secret_access_key' "$creds_file" || error_exit "AWS credentials missing aws_secret_access_key."
    log "AWS credentials file is valid and secure."
  fi
}

get_public_ip() {
  for service in "https://api.ipify.org" "http://ifconfig.me/ip" "https://icanhazip.com"; do
    ip=$(curl --silent --max-time 5 "$service" | tr -d '[:space:]')
    if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
      log "Detected public IP: $ip"
      echo "$ip"
      return
    fi
  done
  error_exit "Failed to detect a valid public IP address."
}

# === Dynamic Pi-hole Detection ===
IN_DOCKER=false
DOCKER_PIHOLE_NAME=""

if docker info &>/dev/null; then
  if docker ps --format '{{.Names}}' | grep -q '^pihole$'; then
    IN_DOCKER=true
    DOCKER_PIHOLE_NAME="pihole"
    log "Auto-detected Docker Pi-hole container: pihole"
  fi
fi

# Manual override if needed
if [ "$IN_DOCKER" = false ]; then
  read -rp "Are you running Pi-hole in Docker? (y/n): " docker_answer
  if [[ "${docker_answer,,}" == "y" ]]; then
    IN_DOCKER=true
    read -rp "Enter your Pi-hole Docker container name (default: pihole): " container_input
    DOCKER_PIHOLE_NAME=${container_input:-pihole}
    validate_docker_name "$DOCKER_PIHOLE_NAME" || error_exit "Invalid Docker container name."
    log "Using Docker container: $DOCKER_PIHOLE_NAME"
  fi
fi

# === Domain and Email ===
read -rp "Enter your domain/subdomain (e.g., ns1.example.com): " DOMAIN
validate_domain "$DOMAIN" || error_exit "Invalid domain format."

read -rp "Enter your email (for ACME registration): " ACME_EMAIL
validate_email "$ACME_EMAIL" || error_exit "Invalid email format."

# === Select DNS Provider ===
echo ""
echo "Select your DNS provider:"
options=("Cloudflare" "Namecheap" "GoDaddy" "AWS Route53" "DigitalOcean" "Linode" "Google Cloud DNS" "deSEC")
select provider in "${options[@]}"; do
  if [[ "$REPLY" =~ ^[1-8]$ ]]; then
    DNS_PROVIDER="$provider"
    break
  else
    echo "Invalid selection. Please enter 1-8."
  fi
done

# === Install acme.sh if needed ===
if [ ! -f "$ACME_BIN" ]; then
  log "Installing acme.sh..."
  curl --silent --max-time 30 https://get.acme.sh | sh -s email="${ACME_EMAIL}"
fi

# === Centralized Certificate Issuing ===
issue_certificate() {
  local dns_method="$1"
  shift
  "$ACME_BIN" --issue --dns "$dns_method" -d "$DOMAIN" --server letsencrypt --keylength ec-256 "$@"
}

collect_credentials_and_issue() {
  case "$DNS_PROVIDER" in
    "Cloudflare")
      read -rsp "Enter your Cloudflare API token: " CF_TOKEN && echo
      validate_api_key "$CF_TOKEN" || error_exit "Invalid Cloudflare token."
      issue_certificate "dns_cf" CF_Token="$CF_TOKEN" CF_Email="$ACME_EMAIL"
      ;;
    "Namecheap")
      read -rp "Enter your Namecheap username: " NC_USER
      validate_api_key "$NC_USER" || error_exit "Invalid Namecheap username."
      read -rsp "Enter your Namecheap API key: " NC_KEY && echo
      validate_api_key "$NC_KEY" || error_exit "Invalid Namecheap API key."
      read -rp "Enter your Namecheap source IP (or leave blank for auto-detect): " NC_IP
      [ -z "$NC_IP" ] && NC_IP=$(get_public_ip)
      issue_certificate "dns_namecheap" Namecheap_Username="$NC_USER" Namecheap_API_Key="$NC_KEY" Namecheap_Sourceip="$NC_IP"
      ;;
    "GoDaddy")
      read -rsp "Enter your GoDaddy API key: " GD_KEY && echo
      read -rsp "Enter your GoDaddy API secret: " GD_SECRET && echo
      validate_api_key "$GD_KEY" || error_exit "Invalid GoDaddy key."
      validate_api_key "$GD_SECRET" || error_exit "Invalid GoDaddy secret."
      issue_certificate "dns_gd" GD_Key="$GD_KEY" GD_Secret="$GD_SECRET"
      ;;
    "AWS Route53")
      echo "AWS authentication:"
      echo "1) Provide access keys"
      echo "2) Use AWS CLI configured credentials"
      read -rp "Choose (1/2): " AWS_METHOD
      if [ "$AWS_METHOD" = "1" ]; then
        read -rsp "Enter AWS Access Key ID: " AWS_KEY && echo
        read -rsp "Enter AWS Secret Access Key: " AWS_SECRET && echo
        validate_api_key "$AWS_KEY" || error_exit "Invalid AWS Access Key ID."
        validate_aws_secret "$AWS_SECRET" || error_exit "Invalid AWS Secret Access Key."
        read -rp "Enter AWS region (default: us-east-1): " AWS_REGION
        AWS_REGION=${AWS_REGION:-us-east-1}
        issue_certificate "dns_aws" AWS_ACCESS_KEY_ID="$AWS_KEY" AWS_SECRET_ACCESS_KEY="$AWS_SECRET" AWS_DEFAULT_REGION="$AWS_REGION"
      else
        validate_aws_credentials_file
        issue_certificate "dns_aws"
      fi
      ;;
    "DigitalOcean")
      read -rsp "Enter your DigitalOcean API token: " DO_TOKEN && echo
      validate_api_key "$DO_TOKEN" || error_exit "Invalid DigitalOcean token."
      issue_certificate "dns_dgon" DO_API_KEY="$DO_TOKEN"
      ;;
    "Linode")
      read -rsp "Enter your Linode API token: " LINODE_TOKEN && echo
      validate_api_key "$LINODE_TOKEN" || error_exit "Invalid Linode token."
      issue_certificate "dns_linode" LINODE_V4_API_KEY="$LINODE_TOKEN"
      ;;
    "Google Cloud DNS")
      read -rp "Enter path to Google Cloud JSON key file: " GCLOUD_KEY
      [ -f "$GCLOUD_KEY" ] || error_exit "Google Cloud key file not found."
      issue_certificate "dns_gcloud" GCE_SERVICE_ACCOUNT_FILE="$GCLOUD_KEY"
      ;;
    "deSEC")
      read -rsp "Enter your deSEC API token: " DESEC_TOKEN && echo
      validate_api_key "$DESEC_TOKEN" || error_exit "Invalid deSEC token."
      issue_certificate "dns_desec" DEDYN_TOKEN="$DESEC_TOKEN"
      ;;
  esac
}

# === Start Certificate Issuing ===
collect_credentials_and_issue

# === Combine Cert/Key Securely ===
cat "${ACME_HOME}/${DOMAIN}_ecc/${DOMAIN}.key" "${ACME_HOME}/${DOMAIN}_ecc/${DOMAIN}.cer" > "${SECURE_TMP_DIR}/tls.pem"
chmod 600 "${SECURE_TMP_DIR}/tls.pem"

# === Install Certificate ===
install_cert_to_docker() {
  docker cp "${SECURE_TMP_DIR}/tls.pem" "${DOCKER_PIHOLE_NAME}:${PIHOLE_TLS_PATH}"
  docker exec "${DOCKER_PIHOLE_NAME}" pihole-FTL --config webserver.domain "$DOMAIN"
  docker exec "${DOCKER_PIHOLE_NAME}" service pihole-FTL restart
}

install_cert_to_baremetal() {
  sudo cp "${SECURE_TMP_DIR}/tls.pem" "$PIHOLE_TLS_PATH"
  sudo pihole-FTL --config webserver.domain "$DOMAIN"
  sudo service pihole-FTL restart
}

if [ "$IN_DOCKER" = true ]; then
  install_cert_to_docker
else
  install_cert_to_baremetal
fi

log "Pi-hole HTTPS setup completed successfully for $DOMAIN."
echo "✅ Pi-hole HTTPS setup complete. Logs available at: $LOG_FILE"
