#!/usr/bin/env bash
set -e

# Display information about the script
echo "=== Pi-hole HTTPS Setup Script ==="
echo "This script sets up HTTPS for Pi-hole using acme.sh"
echo "Supported DNS providers: Cloudflare, Namecheap"
echo "Supports both bare metal and Docker installations"

# Detect if running in a Docker environment
IN_DOCKER=false
DOCKER_PIHOLE_NAME=""
if command -v docker &> /dev/null; then
  read -p "Are you running Pi-hole in Docker? (y/n): " docker_answer
  if [[ "${docker_answer}" =~ ^[Yy]$ ]]; then
    IN_DOCKER=true
    read -p "Enter your Pi-hole container name (default: pihole): " container_input
    DOCKER_PIHOLE_NAME=${container_input:-pihole}
    echo "Using Docker container: ${DOCKER_PIHOLE_NAME}"
  fi
fi

# Prompt for domain, email, and DNS provider
read -p "Enter the domain/subdomain (e.g., ns1.mydomain.com): " DOMAIN
read -p "Enter your email (used for ACME): " ACME_EMAIL

read -p "Choose DNS provider (1 for Cloudflare, 2 for Namecheap): " DNS_PROVIDER

# Set up DNS validation credentials based on provider
if [ "$DNS_PROVIDER" = "1" ]; then
  # Cloudflare setup
  read -p "Enter your Cloudflare API token: " CF_Token
  export CF_Token="${CF_Token}"
  export CF_Email="${ACME_EMAIL}"
  DNS_METHOD="dns_cf"
elif [ "$DNS_PROVIDER" = "2" ]; then
  # Namecheap setup
  read -p "Enter your Namecheap username: " NAMECHEAP_USERNAME
  read -p "Enter your Namecheap API key: " NAMECHEAP_API_KEY
  read -p "Enter your Namecheap source IP (or press Enter for current IP): " NAMECHEAP_SOURCEIP
  
  if [ -z "$NAMECHEAP_SOURCEIP" ]; then
    NAMECHEAP_SOURCEIP=$(curl -s https://api.ipify.org)
    echo "Using current IP: ${NAMECHEAP_SOURCEIP}"
  fi
  
  export Namecheap_Username="${NAMECHEAP_USERNAME}"
  export Namecheap_API_Key="${NAMECHEAP_API_KEY}"
  export Namecheap_Sourceip="${NAMECHEAP_SOURCEIP}"
  DNS_METHOD="dns_namecheap"
else
  echo "Invalid DNS provider selected. Exiting."
  exit 1
fi

# If script runs as root, use /root/.acme.sh; otherwise, use ~/.acme.sh
if [ "$(id -u)" = "0" ]; then
  ACME_HOME="/root/.acme.sh"
else
  ACME_HOME="${HOME}/.acme.sh"
fi

ACME_BIN="${ACME_HOME}/acme.sh"

# 1. Install acme.sh if missing
if [ ! -f "${ACME_BIN}" ]; then
  echo "acme.sh not found. Installing to ${ACME_HOME}..."
  curl https://get.acme.sh | sh -s email="${ACME_EMAIL}"
else
  echo "acme.sh is already installed at ${ACME_BIN}."
fi

# 2. Issue certificate using absolute path
echo "=== Checking acme.sh version ==="
"${ACME_BIN}" --version

echo "=== Issuing certificate for '${DOMAIN}' ==="
"${ACME_BIN}" --issue \
  --${DNS_METHOD} \
  -d "${DOMAIN}" \
  --server letsencrypt

# Certificate paths
CERT_PATH="${ACME_HOME}/${DOMAIN}"
KEY_FILE="${CERT_PATH}/${DOMAIN}.key" 
CERT_FILE="${CERT_PATH}/${DOMAIN}.cer"
COMBINED_CERT="/tmp/tls.pem"

# Combine key and certificate
cat "${KEY_FILE}" "${CERT_FILE}" > "${COMBINED_CERT}"

# 3. Install certificate into Pi-hole (with Docker support)
echo "=== Installing certificate for '${DOMAIN}' into Pi-hole ==="

if [ "$IN_DOCKER" = true ]; then
  # Docker installation approach
  echo "Installing certificate for Docker Pi-hole..."
  
  # Copy the combined certificate to the Docker container
  docker cp "${COMBINED_CERT}" "${DOCKER_PIHOLE_NAME}:/etc/pihole/tls.pem"
  
  # Configure the domain and restart FTL service inside container
  docker exec "${DOCKER_PIHOLE_NAME}" pihole-FTL --config webserver.domain "${DOMAIN}"
  docker exec "${DOCKER_PIHOLE_NAME}" service pihole-FTL restart
  
  # Set up auto-renewal hook
  "${ACME_BIN}" --install-cert -d "${DOMAIN}" \
    --reloadcmd "cat ${KEY_FILE} ${CERT_FILE} > ${COMBINED_CERT} && \
    docker cp ${COMBINED_CERT} ${DOCKER_PIHOLE_NAME}:/etc/pihole/tls.pem && \
    docker exec ${DOCKER_PIHOLE_NAME} service pihole-FTL restart"
else
  # Traditional installation
  "${ACME_BIN}" --install-cert -d "${DOMAIN}" \
    --reloadcmd "sudo rm -f /etc/pihole/tls* && \
    sudo cat ${KEY_FILE} ${CERT_FILE} | sudo tee /etc/pihole/tls.pem && \
    sudo service pihole-FTL restart"
    
  # Configure Pi-hole domain setting
  echo "=== Configuring Pi-hole to serve HTTPS for domain '${DOMAIN}' ==="
  sudo pihole-FTL --config webserver.domain "${DOMAIN}"
  sudo service pihole-FTL restart
fi

# Clean up temporary files
rm -f "${COMBINED_CERT}"

echo "=== Done! Pi-hole should now be serving HTTPS for ${DOMAIN} ==="
echo "Use '${ACME_BIN} --renew -d ${DOMAIN} --force' to force a renewal."

# Add cron job reminder
echo ""
echo "Note: acme.sh has automatically added a cron job to handle renewal."
echo "You can verify this with: crontab -l"
