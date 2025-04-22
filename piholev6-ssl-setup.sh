#!/usr/bin/env bash
set -e

# Display information about the script
echo "=== Pi-hole HTTPS Setup Script ==="
echo "This script sets up HTTPS for Pi-hole using acme.sh"
echo "Supported DNS providers: Cloudflare, Namecheap, GoDaddy, AWS Route53, DigitalOcean, Linode, Google Cloud DNS"
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
read -p "Enter your choice (1-7): " DNS_PROVIDER

# Set up DNS validation credentials based on provider
case "$DNS_PROVIDER" in
  1)
    # Cloudflare setup
    read -p "Enter your Cloudflare API token: " CF_Token
    export CF_Token="${CF_Token}"
    export CF_Email="${ACME_EMAIL}"
    DNS_METHOD="dns_cf"
    ;;
    
  2)
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
    ;;
    
  3)
    # GoDaddy setup
    read -p "Enter your GoDaddy API key: " GODADDY_API_KEY
    read -p "Enter your GoDaddy API secret: " GODADDY_API_SECRET
    
    export GD_Key="${GODADDY_API_KEY}"
    export GD_Secret="${GODADDY_API_SECRET}"
    DNS_METHOD="dns_gd"
    ;;
    
  4)
    # AWS Route53 setup
    echo "For AWS Route53, you have two authentication options:"
    echo "1) AWS Access Key ID and Secret Access Key"
    echo "2) Use AWS credentials file (~/.aws/credentials)"
    read -p "Choose authentication method (1 or 2): " AWS_AUTH_METHOD
    
    if [ "$AWS_AUTH_METHOD" = "1" ]; then
      read -p "Enter your AWS Access Key ID: " AWS_ACCESS_KEY_ID
      read -p "Enter your AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
      read -p "Enter your AWS region (default: us-east-1): " AWS_REGION
      AWS_REGION=${AWS_REGION:-us-east-1}
      
      export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
      export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
      export AWS_DEFAULT_REGION="${AWS_REGION}"
    else
      echo "Using existing AWS credentials from ~/.aws/credentials"
      # Check if aws credentials file exists
      if [ ! -f ~/.aws/credentials ]; then
        echo "Warning: AWS credentials file not found. Please ensure AWS CLI is configured."
      fi
    fi
    DNS_METHOD="dns_aws"
    ;;
    
  5)
    # DigitalOcean setup
    read -p "Enter your DigitalOcean API token: " DO_API_TOKEN
    
    export DO_API_KEY="${DO_API_TOKEN}"
    DNS_METHOD="dns_dgon"
    ;;
    
  6)
    # Linode setup
    read -p "Enter your Linode API token: " LINODE_API_TOKEN
    
    export LINODE_V4_API_KEY="${LINODE_API_TOKEN}"
    DNS_METHOD="dns_linode"
    ;;
    
  7)
    # Google Cloud DNS setup
    echo "For Google Cloud DNS, you need a service account key file (JSON)"
    read -p "Enter the path to your service account JSON key file: " GCP_KEY_FILE
    
    if [ ! -f "$GCP_KEY_FILE" ]; then
      echo "Error: Service account key file not found at $GCP_KEY_FILE"
      exit 1
    fi
    
    export GCE_SERVICE_ACCOUNT_FILE="${GCP_KEY_FILE}"
    DNS_METHOD="dns_gcloud"
    ;;

  8)
    # deSEC
    read -p "Enter your deSEC API token: " DESEC_API_TOKEN
    
    export DEDYN_TOKEN="${DESEC_API_TOKEN}"
    DNS_METHOD="dns_desec"
    ;;
    
  *)
    echo "Invalid DNS provider selected. Exiting."
    exit 1
    ;;
esac

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
  --dns ${DNS_METHOD} \
  -d "${DOMAIN}" \
  --server letsencrypt \
  --keylength ec-256

# Certificate paths
CERT_PATH="${ACME_HOME}/${DOMAIN}_ecc"
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

# Provider-specific notes
case "$DNS_PROVIDER" in
  4)
    echo ""
    echo "AWS Route53 Note: If you encounter issues with permissions,"
    echo "ensure your IAM user/role has the following permissions:"
    echo "  - route53:ListHostedZones"
    echo "  - route53:GetChange"
    echo "  - route53:ChangeResourceRecordSets"
    ;;
  7)
    echo ""
    echo "Google Cloud DNS Note: Make sure your service account has the"
    echo "DNS Administrator role or appropriate permissions to create/modify records."
    ;;
esac
