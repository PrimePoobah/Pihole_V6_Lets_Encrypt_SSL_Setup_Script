#!/usr/bin/env bash
set -e

# Prompt for domain, email, token
read -p "Enter the domain/subdomain (e.g., ns1.mydomain.com): " DOMAIN
read -p "Enter your email (used for ACME and Cloudflare): " ACME_EMAIL
read -p "Enter your Cloudflare API token: " CF_Token

# Export Cloudflare DNS API env variables
export CF_Token="${CF_Token}"
export CF_Email="${ACME_EMAIL}"

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
  --dns dns_cf \
  -d "${DOMAIN}" \
  --server letsencrypt

# 3. Install certificate into Pi-hole
echo "=== Installing certificate for '${DOMAIN}' into Pi-hole ==="
"${ACME_BIN}" --install-cert -d "${DOMAIN}" \
  --reloadcmd "sudo rm -f /etc/pihole/tls* && \
  sudo cat ${DOMAIN}.key ${DOMAIN}.cer | sudo tee /etc/pihole/tls.pem && \
  sudo service pihole-FTL restart"

# 4. Configure Pi-hole domain setting
echo "=== Configuring Pi-hole to serve HTTPS for domain '${DOMAIN}' ==="
sudo pihole-FTL --config webserver.domain "${DOMAIN}"
sudo service pihole-FTL restart

echo "=== Done! Pi-hole should now be serving HTTPS for ${DOMAIN} ==="
echo "Use '${ACME_BIN} --renew -d ${DOMAIN} --force' to force a renewal."
