#!/usr/bin/env bash
# Pi-hole v6 HTTPS with acme.sh (DNS-01) — Debian 13 "Trixie" compatible
# - Supports Cloudflare, Namecheap, GoDaddy, AWS Route53, DigitalOcean, Linode, Google Cloud DNS, deSEC
# - Issues ECDSA (P-256) certs with Let's Encrypt via acme.sh
# - Installs PEM (fullchain + key) to Pi-hole v6 embedded web server (no lighttpd)
# - Configures pihole-FTL to use your domain, TLS cert, and (optionally) listen on 80/443
# - If a cert already exists, this script forces renewal and reinstall
#
# Requirements beforehand:
#   sudo apt update && sudo apt install -y curl cron socat coreutils
#   # Optional for Docker-managed Pi-hole path:
#   sudo apt install -y docker.io
#
# Notes:
# - Pi-hole v6 uses /etc/pihole/pihole.toml and an embedded web server in FTL.
# - TLS PEM must contain both the certificate chain AND the private key (fullchain + key).
# - For Docker, this script can copy the PEM into the container and reload it.

set -euo pipefail

CONFIGURE_WEB_PORTS=true

# ---------- Helpers ----------
need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Error: required command '$1' not found."; exit 1; }; }
in_path()  { command -v "$1" >/dev/null 2>&1; }

need_cmd curl
need_cmd tee
need_cmd sed
need_cmd awk

# ---------- Prompts ----------
read -r -p "Enter the domain/subdomain (e.g., ns1.mydomain.com): " DOMAIN
if [[ -z "${DOMAIN}" ]]; then echo "Domain is required."; exit 1; fi

read -r -p "Enter your email (used for ACME): " ACME_EMAIL
if [[ -z "${ACME_EMAIL}" ]]; then echo "ACME email is required."; exit 1; fi

read -r -p "Force the Pi-hole web UI to use HTTP 80 and HTTPS 443? (Y/n): " FORCE_WEB_PORTS
if [[ "${FORCE_WEB_PORTS}" =~ ^[Nn]$ ]]; then
  CONFIGURE_WEB_PORTS=false
  echo "Existing Pi-hole webserver.port settings will be left unchanged."
else
  echo "Pi-hole webserver.port will be set to 80 (HTTP) and 443 (HTTPS)."
fi

echo ""
echo "Choose DNS provider:"
echo "1) Cloudflare"
echo "2) Namecheap"
echo "3) GoDaddy"
echo "4) AWS Route53"
echo "5) DigitalOcean"
echo "6) Linode"
echo "7) Google Cloud DNS"
echo "8) deSEC"
read -r -p "Enter your choice (1-8): " DNS_PROVIDER

# ---------- Provider setup ----------
DNS_METHOD=""
case "$DNS_PROVIDER" in
  1)
    # Cloudflare (token with Zone:DNS Edit on the zone)
    read -r -p "Enter your Cloudflare API token: " CF_Token
    export CF_Token="${CF_Token}"
    export CF_Email="${ACME_EMAIL}"   # optional with token auth; harmless if present
    DNS_METHOD="dns_cf"
    ;;
  2)
    # Namecheap (case-sensitive env names)
    read -r -p "Enter your Namecheap username: " NAMECHEAP_USERNAME
    read -r -p "Enter your Namecheap API key: " NAMECHEAP_API_KEY
    read -r -p "Enter your Namecheap source IP (or press Enter for current IP): " NAMECHEAP_SOURCEIP
    if [ -z "${NAMECHEAP_SOURCEIP}" ]; then
      NAMECHEAP_SOURCEIP="$(curl -s https://api.ipify.org)"
      echo "Using current IP: ${NAMECHEAP_SOURCEIP}"
    fi
    export Namecheap_Username="${NAMECHEAP_USERNAME}"
    export Namecheap_APIKey="${NAMECHEAP_API_KEY}"
    export Namecheap_SourceIP="${NAMECHEAP_SOURCEIP}"
    DNS_METHOD="dns_namecheap"
    ;;
  3)
    # GoDaddy
    read -r -p "Enter your GoDaddy API key: " GODADDY_API_KEY
    read -r -p "Enter your GoDaddy API secret: " GODADDY_API_SECRET
    export GD_Key="${GODADDY_API_KEY}"
    export GD_Secret="${GODADDY_API_SECRET}"
    DNS_METHOD="dns_gd"
    ;;
  4)
    # AWS Route53
    echo "For AWS Route53, choose authentication:"
    echo "1) Enter Access Key and Secret now"
    echo "2) Use ~/.aws/credentials or instance profile"
    read -r -p "Choose authentication method (1 or 2): " AWS_AUTH_METHOD
    if [ "${AWS_AUTH_METHOD}" = "1" ]; then
      read -r -p "Enter your AWS Access Key ID: " AWS_ACCESS_KEY_ID
      read -r -p "Enter your AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
      read -r -p "Enter your AWS region (default: us-east-1): " AWS_REGION
      AWS_REGION=${AWS_REGION:-us-east-1}
      export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
      export AWS_DEFAULT_REGION="${AWS_REGION}"
    else
      echo "Using existing AWS credentials from ~/.aws/credentials or instance profile."
      if [ ! -f "${HOME}/.aws/credentials" ]; then
        echo "Warning: ~/.aws/credentials not found. Ensure IAM role/profile has Route53 permissions."
      fi
    fi
    DNS_METHOD="dns_aws"
    ;;
  5)
    # DigitalOcean
    read -r -p "Enter your DigitalOcean API token: " DO_API_TOKEN
    export DO_API_KEY="${DO_API_TOKEN}"
    DNS_METHOD="dns_dgon"
    ;;
  6)
    # Linode
    read -r -p "Enter your Linode API token: " LINODE_API_TOKEN
    export LINODE_V4_API_KEY="${LINODE_API_TOKEN}"
    DNS_METHOD="dns_linode"
    ;;
  7)
    # Google Cloud DNS
    echo "For Google Cloud DNS, you need a service account key file (JSON)."
    read -r -p "Enter the path to your service account JSON key file: " GCP_KEY_FILE
    if [ ! -f "$GCP_KEY_FILE" ]; then
      echo "Error: Service account key file not found at $GCP_KEY_FILE"
      exit 1
    fi
    read -r -p "Enter your GCP Project ID: " GCP_PROJECT
    if [[ -z "${GCP_PROJECT}" ]]; then echo "GCP Project ID is required for dns_gcloud."; exit 1; fi
    export GCE_SERVICE_ACCOUNT_FILE="${GCP_KEY_FILE}"
    export GCE_PROJECT="${GCP_PROJECT}"
    export GOOGLE_APPLICATION_CREDENTIALS="${GCP_KEY_FILE}"
    DNS_METHOD="dns_gcloud"
    ;;
  8)
    # deSEC
    read -r -p "Enter your deSEC API token: " DESEC_API_TOKEN
    # acme.sh's dns_desec plugin reads DEDYN_TOKEN, not DESEC_TOKEN.
    export DEDYN_TOKEN="${DESEC_API_TOKEN}"
    DNS_METHOD="dns_desec"
    ;;
  *)
    echo "Invalid DNS provider selected. Exiting."
    exit 1
    ;;
esac

# ---------- Pi-hole deployment mode ----------
# Decided before the root check below: bare-metal and Docker need different
# privileges, and for Docker specifically, whoever runs this script also
# decides whose crontab (and whose Docker socket, for rootless setups) the
# renewal hook will use later.
echo ""
echo "Where is your Pi-hole running?"
echo "1) Bare-metal / VM (pihole-FTL on the host)"
echo "2) Docker container"
read -r -p "Enter your choice (1-2): " PH_MODE

IN_DOCKER=false
DOCKER_PIHOLE_NAME="pihole"
TARGET_CERT_PATH_HOST="/etc/pihole/tls.pem"
TARGET_CERT_PATH_DOCKER="/etc/pihole/tls.pem"

if [ "${PH_MODE}" = "2" ]; then
  IN_DOCKER=true
  need_cmd docker
  read -r -p "Enter your Docker Pi-hole container name (default: pihole): " _cn
  DOCKER_PIHOLE_NAME="${_cn:-pihole}"
  read -r -p "Path inside container for PEM (default: /etc/pihole/tls.pem): " _tp
  TARGET_CERT_PATH_DOCKER="${_tp:-/etc/pihole/tls.pem}"
fi

# ---------- Paths & acme.sh install ----------
if [ "${IN_DOCKER}" = true ]; then
  # Docker mode never touches /etc/pihole or pihole-FTL on the host -- the
  # reload hook only runs docker cp/exec/restart against the container, so
  # it needs access to the right Docker socket, not root. For ROOTLESS
  # Docker that socket belongs to a normal user; requiring root here would
  # make the renewal hook (and this initial run) unable to reach it. acme.sh
  # installs its cron for whoever invokes this script, so running as the
  # same user who owns the rootless Docker daemon keeps the later
  # cron-triggered renewal in the same context as this interactive run.
  if [ "$(id -u)" = "0" ]; then
    echo "Warning: running as root with Docker mode selected."
    echo "If Pi-hole's container is managed by ROOTLESS Docker under a normal"
    echo "user, run this script as that user instead (no sudo) -- otherwise"
    echo "the renewal cron/reload hook may not reach the socket that"
    echo "actually owns the Pi-hole container."
  fi
  ACME_HOME="$( [ "$(id -u)" = "0" ] && echo "/root/.acme.sh" || echo "${HOME}/.acme.sh" )"
else
  # Bare-metal mode writes /etc/pihole/tls.pem and restarts pihole-FTL, so it
  # needs root. acme.sh installs its renewal cron for whoever runs this
  # script: run as a normal user and that cron fires without a TTY, every
  # sudo in the hook fails, and the cert silently stops being deployed.
  if [ "$(id -u)" != "0" ]; then
    echo "Error: run this script as root for bare-metal Pi-hole (e.g. 'sudo -H ./piholev6-ssl-setup.sh')."
    echo "acme.sh installs its auto-renewal cron for the invoking user, and the"
    echo "renewal hook needs root to write /etc/pihole/tls.pem and restart pihole-FTL."
    echo "Running as '$(id -un)' would install a cron that cannot deploy renewals."
    exit 1
  fi
  ACME_HOME="/root/.acme.sh"
fi
ACME_BIN="${ACME_HOME}/acme.sh"

if [ ! -f "${ACME_BIN}" ]; then
  echo "acme.sh not found. Installing to ${ACME_HOME}..."
  for c in cron socat; do
    if ! in_path "$c"; then
      echo "Warning: '$c' not found. Install it first: apt install -y $c"
    fi
  done
  # --home is explicit: the installer otherwise derives its target from $HOME,
  # which sudo may leave pointing at the invoking user's home.
  curl https://get.acme.sh | sh -s -- --home "${ACME_HOME}" --accountemail "${ACME_EMAIL}"
else
  echo "acme.sh is already installed at ${ACME_BIN}."
fi

echo "=== acme.sh version ==="
"${ACME_BIN}" --version

# ---------- Determine issuance vs forced renewal ----------
CERT_PATH="${ACME_HOME}/${DOMAIN}_ecc"
KEY_FILE="${CERT_PATH}/${DOMAIN}.key"
FULLCHAIN_FILE="${CERT_PATH}/fullchain.cer"
COMBINED_CERT="/tmp/tls.pem"

echo "=== Preparing certificate for '${DOMAIN}' via ${DNS_METHOD} ==="
"${ACME_BIN}" --set-default-ca --server letsencrypt

# Test for the cert itself, not the directory: a failed issuance leaves
# ${CERT_PATH} behind holding only a domain key, and renewing that is an error.
if [ -f "${FULLCHAIN_FILE}" ]; then
  echo "Existing certificate detected at ${FULLCHAIN_FILE}."
  echo "Forcing renewal and reinstall..."
  if ! "${ACME_BIN}" --renew -d "${DOMAIN}" --force --dnssleep 30; then
    echo "Error: certificate renewal failed for ${DOMAIN}. Aborting install so an old certificate is not re-deployed."
    exit 1
  fi
else
  echo "No existing certificate found. Issuing a new certificate..."
  if ! "${ACME_BIN}" --issue \
    --dns "${DNS_METHOD}" \
    -d "${DOMAIN}" \
    --server letsencrypt \
    --keylength ec-256 \
    --dnssleep 30; then
    echo "Error: certificate issuance failed for ${DOMAIN}. Aborting install."
    exit 1
  fi
fi

# Validate files after (re)issuance
if [ ! -f "${KEY_FILE}" ] || [ ! -f "${FULLCHAIN_FILE}" ]; then
  echo "Error: expected cert files not found. KEY: ${KEY_FILE}, FULLCHAIN: ${FULLCHAIN_FILE}"
  exit 1
fi

# Build PEM as CERT first, then KEY (embedded server accepts PEM with both)
cat "${FULLCHAIN_FILE}" "${KEY_FILE}" > "${COMBINED_CERT}"

# ---------- Functions for configuring FTL webserver ----------
set_ftl_config() {
  # Usage: set_ftl_config key value
  local key="$1"
  local value="$2"
  sudo pihole-FTL --config "${key}" "${value}"
}

ensure_ports_include_tls() {
  if [ "${CONFIGURE_WEB_PORTS}" != true ]; then
    echo "Skipping Pi-hole webserver.port changes per user request."
    return
  fi
  # Explicitly set webserver.port to sane value "80,443s"
  # (Avoids weird accumulations like "80o,443os,...")
  set_ftl_config "webserver.port" "80,443s"
}

# ---------- Install into Pi-hole ----------
if [ "${IN_DOCKER}" = true ]; then
  echo "=== Installing certificate into Docker Pi-hole container '${DOCKER_PIHOLE_NAME}' ==="
  docker cp "${COMBINED_CERT}" "${DOCKER_PIHOLE_NAME}:${TARGET_CERT_PATH_DOCKER}"
  docker exec "${DOCKER_PIHOLE_NAME}" bash -lc "chmod 600 '${TARGET_CERT_PATH_DOCKER}' || true"

  # Configure domain, PEM path, and TLS port via CLI inside container
  docker exec "${DOCKER_PIHOLE_NAME}" bash -lc "pihole-FTL --config webserver.domain '${DOMAIN}'"
  docker exec "${DOCKER_PIHOLE_NAME}" bash -lc "pihole-FTL --config webserver.tls.cert '${TARGET_CERT_PATH_DOCKER}'"
  if [ "${CONFIGURE_WEB_PORTS}" = true ]; then
    docker exec "${DOCKER_PIHOLE_NAME}" bash -lc "pihole-FTL --config webserver.port '80,443s'"
  fi

  # Restart container to reload with new TLS
  docker restart "${DOCKER_PIHOLE_NAME}"

  # Renewal hook for Docker (force reinstall on renew)
  DOCKER_RELOAD_PORT_SNIPPET=""
  if [ "${CONFIGURE_WEB_PORTS}" = true ]; then
    DOCKER_RELOAD_PORT_SNIPPET="; pihole-FTL --config webserver.port '80,443s'"
  fi
  "${ACME_BIN}" --install-cert -d "${DOMAIN}" --force \
    --reloadcmd "cat '${FULLCHAIN_FILE}' '${KEY_FILE}' > '${COMBINED_CERT}' && \
    docker cp '${COMBINED_CERT}' '${DOCKER_PIHOLE_NAME}:${TARGET_CERT_PATH_DOCKER}' && \
    docker exec '${DOCKER_PIHOLE_NAME}' bash -lc \"chmod 600 '${TARGET_CERT_PATH_DOCKER}' || true; pihole-FTL --config webserver.tls.cert '${TARGET_CERT_PATH_DOCKER}'; pihole-FTL --config webserver.domain '${DOMAIN}'${DOCKER_RELOAD_PORT_SNIPPET}\" && \
    docker restart '${DOCKER_PIHOLE_NAME}'"

else
  echo "=== Installing certificate into bare-metal Pi-hole (embedded web server) ==="
  sudo install -d -m 700 /etc/pihole
  HOST_RELOAD_PORT_SNIPPET=""
  if [ "${CONFIGURE_WEB_PORTS}" = true ]; then
    HOST_RELOAD_PORT_SNIPPET=" && sudo pihole-FTL --config webserver.port '80,443s'"
  fi

  # Write PEM via sudo tee (avoids permission denied from shell redirection)
  cat "${FULLCHAIN_FILE}" "${KEY_FILE}" | sudo tee /etc/pihole/tls.pem >/dev/null
  sudo chmod 600 /etc/pihole/tls.pem
  sudo chown pihole:pihole /etc/pihole/tls.pem || true

  # Configure FTL embedded webserver
  need_cmd pihole-FTL
  set_ftl_config "webserver.domain" "${DOMAIN}"
  set_ftl_config "webserver.tls.cert" "/etc/pihole/tls.pem"
  ensure_ports_include_tls

  # Restart FTL to pick up TLS
  if in_path systemctl; then
    sudo systemctl restart pihole-FTL
  else
    sudo service pihole-FTL restart || true
  fi

  # Renewal hook for bare-metal (force reinstall on renew)
  # ponytail: chown is the only tolerated failure; it is braced so `|| true`
  # cannot swallow a failed write. Without the braces the chain parses as
  # ((write && chmod && chown) || true) && ... -- a failed write still exits 0,
  # so acme.sh logs "Reload successful" while FTL keeps serving the old cert.
  "${ACME_BIN}" --install-cert -d "${DOMAIN}" --force \
    --reloadcmd "cat '${FULLCHAIN_FILE}' '${KEY_FILE}' | sudo tee '/etc/pihole/tls.pem' >/dev/null && \
    sudo chmod 600 '/etc/pihole/tls.pem' && \
    { sudo chown pihole:pihole '/etc/pihole/tls.pem' || true; } && \
    sudo pihole-FTL --config webserver.tls.cert '/etc/pihole/tls.pem' && \
    sudo pihole-FTL --config webserver.domain '${DOMAIN}'${HOST_RELOAD_PORT_SNIPPET} && \
    (sudo systemctl restart pihole-FTL 2>/dev/null || sudo service pihole-FTL restart) && \
    cat '${FULLCHAIN_FILE}' '${KEY_FILE}' | sudo cmp -s - /etc/pihole/tls.pem"
fi

# Clean up temporary combined cert
rm -f "${COMBINED_CERT}"

echo "=== Done! Pi-hole v6 should now be serving HTTPS for ${DOMAIN} on port 443 ==="
echo "Try: https://${DOMAIN}/admin/"
echo "Force-renew now: '${ACME_BIN} --renew -d ${DOMAIN} --force'"
echo "acme.sh auto-renewal cron is usually installed; check with: crontab -l"

# Provider-specific notes
case "$DNS_PROVIDER" in
  4)
    echo ""
    echo "AWS Route53 Note: Ensure IAM permissions:"
    echo "  - route53:ListHostedZones"
    echo "  - route53:GetChange"
    echo "  - route53:ChangeResourceRecordSets"
    ;;
  7)
    echo ""
    echo "Google Cloud DNS Note: Service account needs DNS Admin on project '${GCE_PROJECT}'."
    ;;
esac
