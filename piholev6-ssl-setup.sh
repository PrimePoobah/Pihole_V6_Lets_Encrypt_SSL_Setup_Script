#!/usr/bin/env bash
set -euo pipefail

# ============================= #
#   Pi-hole HTTPS Setup Script   #
# ============================= #

echo "=== Pi-hole HTTPS Setup Script ==="
echo "This script sets up HTTPS for Pi-hole using acme.sh securely."
echo "Supports DNS validation with: Cloudflare, Namecheap, GoDaddy, AWS Route53, DigitalOcean, Linode, Google Cloud DNS, deSEC."
echo ""

# ---- Functions ---- #

error_exit() {
  echo "Error: $1" >&2
  exit 1
}

safe_read_secret() {
  local var_name="$1"
  local prompt="$2"
  local secret
  read -rsp "$prompt" secret
  echo ""
  printf -v "$var_name" '%s' "$secret"
}

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

check_command() {
  command -v "$1" &>/dev/null || error_exit "'$1' command not found."
}

check_sudo_privileges() {
  if ! command -v sudo &>/dev/null; then
    error_exit "'sudo' command not found. Please install 'sudo' or run this script as root."
  fi
  if ! sudo -n true 2>/dev/null; then
    error_exit "User does not have passwordless sudo privileges. Please ensure you can run sudo commands without password prompts."
  fi
  echo "Sudo is available and passwordless."
}

get_public_ip() {
  local ip_services=(
    "https://api.ipify.org"
    "http://ifconfig.me/ip"
    "https://icanhazip.com"
  )

  for service in "${ip_services[@]}"; do
    echo "Trying $service..."
    ip=$(curl --silent --max-time 5 "$service" | tr -d '[:space:]')
    if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
      echo "Detected public IP: $ip"
      echo "$ip"
      return 0
    else
      echo "Warning: Invalid IP received from $service"
    fi
  done

  error_exit "Failed to detect a valid public IP from all services."
}

validate_gcp_json_key() {
  local file="$1"

  check_command jq

  if ! jq empty "$file" &>/dev/null; then
    error_exit "Invalid JSON format in the Google Cloud key file."
  fi

  local required_fields=("client_email" "private_key")
  for field in "${required_fields[@]}"; do
    if ! jq -e ".${field}" "$file" &>/dev/null; then
      error_exit "Missing required field '${field}' in Google Cloud key file."
    fi
  done

  echo "Google Cloud JSON key file is valid."
}

validate_aws_credentials_file() {
  local creds_file="$HOME/.aws/credentials"

  [ -f "$creds_file" ] || error_exit "AWS credentials file not found at $creds_file."

  local perms
  perms=$(stat -c "%a" "$creds_file")
  if [[ "$perms" != "600" && "$perms" != "400" ]]; then
    error_exit "AWS credentials file has insecure permissions ($perms). It must be 600 or 400."
  fi

  if ! grep -qE '^\[.*\]' "$creds_file"; then
    error_exit "AWS credentials file missing profile section (e.g., [default])."
  fi
  if ! grep -q 'aws_access_key_id' "$creds_file"; then
    error_exit "AWS credentials file missing aws_access_key_id."
  fi
  if ! grep -q 'aws_secret_access_key' "$creds_file"; then
    error_exit "AWS credentials file missing aws_secret_access_key."
  fi

  echo "AWS credentials file is valid and secure."
}

# ---- Checks ---- #

check_command curl
check_command docker || true
check_command tee
check_command cat
check_command stat
check_sudo_privileges

# ---- Docker Detection ---- #

IN_DOCKER=false
DOCKER_PIHOLE_NAME=""

if docker info &>/dev/null; then
  read -rp "Are you running Pi-hole in Docker? (y/n): " docker_answer
  if [[ "${docker_answer,,}" == "y" ]]; then
    IN_DOCKER=true
    read -rp "Enter your Pi-hole container name (default: pihole): " container_input
    DOCKER_PIHOLE_NAME=${container_input:-pihole}
    validate_docker_name "$DOCKER_PIHOLE_NAME" || error_exit "Invalid Docker container name."
    echo "Using Docker container: ${DOCKER_PIHOLE_NAME}"
  fi
fi

# ---- Domain and Email Input ---- #

read -rp "Enter your domain/subdomain (e.g., ns1.example.com): " DOMAIN
validate_domain "$DOMAIN" || error_exit "Invalid domain format."

read -rp "Enter your email (for ACME registration): " ACME_EMAIL
validate_email "$ACME_EMAIL" || error_exit "Invalid email address format."

# ---- Choose DNS Provider ---- #

echo ""
echo "Choose your DNS provider:"
PS3="Enter your choice: "
DNS_OPTIONS=("Cloudflare" "Namecheap" "GoDaddy" "AWS Route53" "DigitalOcean" "Linode" "Google Cloud DNS" "deSEC")
select choice in "${DNS_OPTIONS[@]}"; do
  if [[ -n "$choice" ]]; then
    DNS_PROVIDER="$REPLY"
    break
  fi
done

# ---- ACME Setup ---- #

readonly ACME_HOME="${HOME}/.acme.sh"
readonly ACME_BIN="${ACME_HOME}/acme.sh"

if [ ! -f "$ACME_BIN" ]; then
  echo "Installing acme.sh to ${ACME_HOME}..."
  curl --silent --max-time 30 https://get.acme.sh | sh -s email="${ACME_EMAIL}"
else
  echo "acme.sh found at ${ACME_BIN}"
fi

# ---- Secure Temporary Directory ---- #

readonly SECURE_TMP_DIR="${ACME_HOME}/tmp"
mkdir -p "$SECURE_TMP_DIR"
chmod 700 "$SECURE_TMP_DIR"
readonly COMBINED_CERT="${SECURE_TMP_DIR}/tls.pem"

# ---- Secure Issue Certificate ---- #

CERT_PATH="${ACME_HOME}/${DOMAIN}_ecc"
KEY_FILE="${CERT_PATH}/${DOMAIN}.key"
CERT_FILE="${CERT_PATH}/${DOMAIN}.cer"

echo "=== Issuing certificate for ${DOMAIN} ==="

case "$DNS_PROVIDER" in
  1)
    safe_read_secret CF_Token "Enter your Cloudflare API token: "
    validate_api_key "$CF_Token" || error_exit "Invalid API token format."
    (
      CF_Token="$CF_Token" \
      CF_Email="$ACME_EMAIL" \
      "$ACME_BIN" --issue --dns dns_cf -d "$DOMAIN" --server letsencrypt --keylength ec-256
    )
    ;;
  2)
    read -rp "Enter your Namecheap username: " NAMECHEAP_USERNAME
    validate_api_key "$NAMECHEAP_USERNAME" || error_exit "Invalid Namecheap username."
    safe_read_secret NAMECHEAP_API_KEY "Enter your Namecheap API key: "
    validate_api_key "$NAMECHEAP_API_KEY" || error_exit "Invalid Namecheap API key."
    read -rp "Enter your Namecheap source IP (press Enter to auto-detect): " NAMECHEAP_SOURCEIP
    if [ -z "$NAMECHEAP_SOURCEIP" ]; then
      NAMECHEAP_SOURCEIP=$(get_public_ip)
    fi
    echo "Using IP: ${NAMECHEAP_SOURCEIP}"
    (
      Namecheap_Username="$NAMECHEAP_USERNAME" \
      Namecheap_API_Key="$NAMECHEAP_API_KEY" \
      Namecheap_Sourceip="$NAMECHEAP_SOURCEIP" \
      "$ACME_BIN" --issue --dns dns_namecheap -d "$DOMAIN" --server letsencrypt --keylength ec-256
    )
    ;;
  3)
    safe_read_secret GODADDY_API_KEY "Enter your GoDaddy API key: "
    safe_read_secret GODADDY_API_SECRET "Enter your GoDaddy API secret: "
    validate_api_key "$GODADDY_API_KEY" || error_exit "Invalid GoDaddy API key."
    validate_api_key "$GODADDY_API_SECRET" || error_exit "Invalid GoDaddy API secret."
    (
      GD_Key="$GODADDY_API_KEY" \
      GD_Secret="$GODADDY_API_SECRET" \
      "$ACME_BIN" --issue --dns dns_gd -d "$DOMAIN" --server letsencrypt --keylength ec-256
    )
    ;;
  4)
    echo "AWS Route53 authentication:"
    echo "1) Use AWS Access Key and Secret"
    echo "2) Use AWS CLI credentials"
    read -rp "Choose (1/2): " AWS_AUTH_METHOD
    if [[ "$AWS_AUTH_METHOD" == "1" ]]; then
      safe_read_secret AWS_ACCESS_KEY_ID "Enter AWS Access Key ID: "
      safe_read_secret AWS_SECRET_ACCESS_KEY "Enter AWS Secret Access Key: "
      validate_api_key "$AWS_ACCESS_KEY_ID" || error_exit "Invalid AWS Access Key format."
      validate_aws_secret "$AWS_SECRET_ACCESS_KEY" || error_exit "Invalid AWS Secret Access Key format."
      read -rp "Enter AWS Region (default us-east-1): " AWS_REGION
      (
        AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
        AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
        AWS_DEFAULT_REGION="${AWS_REGION:-us-east-1}" \
        "$ACME_BIN" --issue --dns dns_aws -d "$DOMAIN" --server letsencrypt --keylength ec-256
      )
    else
      validate_aws_credentials_file
      "$ACME_BIN" --issue --dns dns_aws -d "$DOMAIN" --server letsencrypt --keylength ec-256
    fi
    ;;
  5)
    safe_read_secret DO_API_KEY "Enter your DigitalOcean API token: "
    validate_api_key "$DO_API_KEY" || error_exit "Invalid DigitalOcean API token format."
    (
      DO_API_KEY="$DO_API_KEY" \
      "$ACME_BIN" --issue --dns dns_dgon -d "$DOMAIN" --server letsencrypt --keylength ec-256
    )
    ;;
  6)
    safe_read_secret LINODE_V4_API_KEY "Enter your Linode API token: "
    validate_api_key "$LINODE_V4_API_KEY" || error_exit "Invalid Linode API token format."
    (
      LINODE_V4_API_KEY="$LINODE_V4_API_KEY" \
      "$ACME_BIN" --issue --dns dns_linode -d "$DOMAIN" --server letsencrypt --keylength ec-256
    )
    ;;
  7)
    read -rp "Enter path to Google Cloud JSON key file: " GCP_KEY_FILE
    [ -f "$GCP_KEY_FILE" ] || error_exit "Key file not found."
    validate_gcp_json_key "$GCP_KEY_FILE"
    (
      GCE_SERVICE_ACCOUNT_FILE="$GCP_KEY_FILE" \
      "$ACME_BIN" --issue --dns dns_gcloud -d "$DOMAIN" --server letsencrypt --keylength ec-256
    )
    ;;
  8)
    safe_read_secret DEDYN_TOKEN "Enter your deSEC API token: "
    validate_api_key "$DEDYN_TOKEN" || error_exit "Invalid deSEC API token format."
    (
      DEDYN_TOKEN="$DEDYN_TOKEN" \
      "$ACME_BIN" --issue --dns dns_desec -d "$DOMAIN" --server letsencrypt --keylength ec-256
    )
    ;;
  *)
    error_exit "Invalid provider selected."
    ;;
esac

# ---- Combine cert/key securely ---- #

cat "$KEY_FILE" "$CERT_FILE" > "$COMBINED_CERT"
chmod 600 "$COMBINED_CERT"

# ---- Install certificate into Pi-hole ---- #

echo "=== Installing certificate into Pi-hole ==="

if [ "$IN_DOCKER" = true ]; then
  docker cp "$COMBINED_CERT" "${DOCKER_PIHOLE_NAME}:/etc/pihole/tls.pem"
  docker exec "$DOCKER_PIHOLE_NAME" pihole-FTL --config webserver.domain "$DOMAIN"
  docker exec "$DOCKER_PIHOLE_NAME" service pihole-FTL restart
else
  sudo cp /etc/pihole/tls.pem /etc/pihole/tls.pem.bak 2>/dev/null || true
  sudo tee /etc/pihole/tls.pem < "$COMBINED_CERT"
  sudo pihole-FTL --config webserver.domain "$DOMAIN"
  sudo service pihole-FTL restart
fi

# ---- Cleanup ---- #

rm -f "$COMBINED_CERT"

# ---- Final Message ---- #

echo "=== Setup complete! Pi-hole now serves HTTPS for ${DOMAIN} ==="
echo "Use '${ACME_BIN} --renew -d ${DOMAIN} --force' to force renewal."
echo "acme.sh has installed a cron job for automatic renewal."
