<<<<<<< HEAD
# Secure HTTPS Setup for Pi-hole using acme.sh (Docker + Bare-Metal)

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
Easily and securely configure **HTTPS/SSL certificates** for your **Pi-hole** instance using [acme.sh](https://github.com/acmesh-official/acme.sh) with DNS API validation.\
This script is designed for **bare-metal** and **Docker-based** Pi-hole installations, fully hardened for production, and audit-ready.
=======
This script securely configures **HTTPS and SSL certificates** for your **Pi-hole** installation using the **acme.sh** ACME client and **DNS API validation**.  
Supports both **bare-metal** and **Docker** Pi-hole setups with auto-renewal, hardened security, and major DNS providers.
>>>>>>> parent of 6979e5d (Refactored for even more security and structure)
=======
This script securely configures **HTTPS and SSL certificates** for your **Pi-hole** installation using the **acme.sh** ACME client and **DNS API validation**.  
Supports both **bare-metal** and **Docker** Pi-hole setups with auto-renewal, hardened security, and major DNS providers.
>>>>>>> parent of 6979e5d (Refactored for even more security and structure)
=======
This script securely configures **HTTPS and SSL certificates** for your **Pi-hole** installation using the **acme.sh** ACME client and **DNS API validation**.  
Supports both **bare-metal** and **Docker** Pi-hole setups with auto-renewal, hardened security, and major DNS providers.
>>>>>>> parent of 6979e5d (Refactored for even more security and structure)
=======
This script securely configures **HTTPS and SSL certificates** for your **Pi-hole** installation using the **acme.sh** ACME client and **DNS API validation**.  
Supports both **bare-metal** and **Docker** Pi-hole setups with auto-renewal, hardened security, and major DNS providers.
>>>>>>> parent of 6979e5d (Refactored for even more security and structure)

---

## ✨ Key Features

- Automates **Let's Encrypt EC-256 certificates** for Pi-hole.
- **DNS API validation** for:
  - Cloudflare
  - Namecheap
  - GoDaddy
  - AWS Route53
  - DigitalOcean
  - Linode
  - Google Cloud DNS
  - deSEC
- Works with **Docker-based** and **bare-metal** Pi-hole servers.
- **Automatic HTTPS installation** and **FTL service reload**.
- **Auto-renewal** configured with acme.sh hooks.

---

## 🔒 Advanced Security Hardening

- ✅ API keys handled in **secure subshells** (never globally exported).
- ✅ **Input validation**: domains, emails, Docker names, API secrets.
- ✅ **Public IP fallback** using multiple providers with strict IPv4 validation.
- ✅ **Secure temporary file handling** (`$HOME/.acme.sh/tmp/` with strict permissions).
- ✅ **GCP JSON key validation** (format and required fields).
- ✅ **AWS credentials file validation** (permissions + required keys).
- ✅ **Passwordless sudo check** before running privileged commands.

---

## 📖 How to Use

1. **Install Dependencies**  
   Ensure you have `sudo`, `curl`, `jq`, and (optionally) `docker` installed.

2. **Download Script**

   ```bash
   curl -O https://yourdomain.com/path/to/pihole-https-setup.sh
   chmod +x pihole-https-setup.sh

   ```

3. **Run the Script**
=======
# Pi-hole v6 SSL Automation Using acme.sh with Multiple DNS Providers and Docker Support

This repository automates obtaining and installing a **Let's Encrypt SSL certificate** for [Pi-hole v6](https://pi-hole.net/) using [acme.sh](https://github.com/acmesh-official/acme.sh) with multiple DNS provider support. The script works with both traditional installations and Docker deployments. It uses the **absolute path** to `acme.sh` rather than relying on shell aliases or profiles. This approach ensures reliable operation in both interactive and non-interactive environments, including Debian 12.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Script Details](#script-details)
- [Usage](#usage)
- [Docker Support](#docker-support)
- [DNS Provider Support](#dns-provider-support)
  - [Cloudflare](#cloudflare)
  - [Namecheap](#namecheap)
  - [GoDaddy](#godaddy)
  - [AWS Route53](#aws-route53)
  - [DigitalOcean](#digitalocean)
  - [Linode](#linode)
  - [Google Cloud DNS](#google-cloud-dns)
- [Verification](#verification)
- [Renewal](#renewal)
- [Troubleshooting](#troubleshooting)
- [License](#license)

---

## Overview

Pi-hole v6 includes an embedded web server that can be secured with an SSL/TLS certificate. By default, Pi-hole v6 generates a self-signed certificate, but you can automate certificate issuance using:

- **acme.sh**: An ACME protocol client script.
- **Let's Encrypt**: A free Certificate Authority (CA).
- **DNS validation plugins**: To validate domain ownership via DNS across multiple providers.
- **Docker support**: To manage certificates in Docker-based Pi-hole installations.

This repository's script uses the **absolute path** to `acme.sh`. It installs `acme.sh` into the current user's home directory (or `/root` if running as root) and then calls it directly. This avoids problems with aliases not loading in non-interactive shells or different shell configurations.

---

## Prerequisites

1. **Pi-hole v6**  
   - Already installed and running on your Debian 12 (or other Linux) system or in a Docker container.
2. **DNS Provider Account**  
   - One of the following DNS providers where your domain is managed:
     - [Cloudflare](https://dash.cloudflare.com/)
     - [Namecheap](https://www.namecheap.com/)
     - [GoDaddy](https://www.godaddy.com/)
     - [AWS Route53](https://aws.amazon.com/route53/)
     - [DigitalOcean](https://www.digitalocean.com/)
     - [Linode](https://www.linode.com/)
     - [Google Cloud DNS](https://cloud.google.com/dns)
3. **API Credentials**  
   - Appropriate API credentials for your chosen DNS provider (details in [DNS Provider Support](#dns-provider-support))
4. **A Registered Domain**  
   - The domain you control must point to your Pi-hole or be resolvable (e.g., `ns1.mydomain.com`).  
5. **Docker** (Optional)
   - If using Pi-hole in Docker, make sure the Docker CLI is available on the host system.
6. **Debian 12 or Other Linux**  
   - The script works on Debian/Ubuntu-based systems and other Linux distributions. Adjust commands as necessary for your environment.

---

## Script Details

The script:
1. Prompts you for:
   - **Installation type** (traditional or Docker)
   - **Docker container name** (if using Docker)
   - **Domain** (e.g., `ns1.mydomain.com`)
   - **Email** (for ACME registration)
   - **DNS Provider** (from the supported list)
   - **Provider-specific credentials**
2. **Installs `acme.sh`** (if not already installed) to `~/.acme.sh` (or `/root/.acme.sh` if run as root).
3. **Issues an SSL Certificate** from Let's Encrypt, using the selected DNS validation plugin.
4. **Installs** the resulting certificate:
   - For traditional installations: into `/etc/pihole/tls.pem`
   - For Docker installations: copies to the Pi-hole container
5. **Configures Pi-hole** to use your domain name to avoid domain mismatch warnings.

---

## Usage

1. **Clone or download** this repository:
>>>>>>> parent of 9dfeb4b (Refactored for Security)
   ```bash
   git clone https://github.com/PrimePoobah/Pihole_V6_Lets_Encrypt_SSL_Setup_Script.git
   cd Pihole_V6_Lets_Encrypt_SSL_Setup_Script
   ```
<<<<<<< HEAD

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
---

### 2. Download the Script

```bash
curl -O https://github.com/PrimePoobah/Pihole_V6_Lets_Encrypt_SSL_Setup_Script/blob/main/piholev6-ssl-setup.sh
chmod +x piholev6-ssl-setup.sh
```

(_Replace the URL with your hosted copy if needed._)

---

### 3. Run the Script

```bash
./piholev6-ssl-setup.sh
```

You will be prompted to:

- Enter your domain or subdomain.
- Enter your email for ACME registration.
- Choose your DNS provider.
- Enter your API credentials securely (no leaking to logs or environment).

---

### 4. Force Certificate Renewal (Optional)

Manually renew certificates if needed:

```bash
~/.acme.sh/acme.sh --renew -d your.domain.com --force
=======
   
2. **Make the script executable:**
  ```bash
  chmod +x piholev6-ssl-setup.sh
   ```

3. **Run the script** (as root or a user with sudo privileges):
  ```bash
  sudo ./piholev6-ssl-setup.sh
   ```

4. **Follow the prompts** to select your installation type, DNS provider, and enter the required information.

The script will:
  - Install or verify `acme.sh`
  - Issue an SSL certificate
  - Install the certificate into Pi-hole
  - Restart Pi-hole FTL

---

## Docker Support

The script includes full support for Pi-hole running in Docker:

1. **Select Docker mode** when prompted
2. **Provide your container name** (defaults to "pihole")
3. The script will:
   - Issue the certificate using the host's file system
   - Copy the certificate into the Docker container
   - Configure the Pi-hole container to use the certificate
   - Set up auto-renewal to update the container's certificate

Example Docker commands:
```bash
# Show running containers to find your Pi-hole container name
docker ps

# Manual certificate verification inside the container
docker exec pihole cat /etc/pihole/tls.pem | openssl x509 -text -noout
>>>>>>> parent of 9dfeb4b (Refactored for Security)
```

---

<<<<<<< HEAD
## ⚙️ System Requirements

- Linux (Debian, Ubuntu, CentOS, RHEL, etc.)
- Installed Pi-hole (either bare-metal or Docker)
- Installed:
  - `curl`
  - `jq`
  - `sudo`
  - `docker` (only if using Dockerized Pi-hole)
- DNS API access credentials (Cloudflare token, AWS keys, etc.)
- Passwordless `sudo` access (for automation)

---

## 🔡 Best Practices for API Key Storage

For maximum security:

- Avoid hardcoding credentials into scripts.
- Use secure environment managers:
  - [direnv](https://direnv.net/)
  - [pass](https://www.passwordstore.org/)
  - OS-native keychains (e.g., macOS Keychain, GNOME Keyring)
  - HashiCorp Vault for production environments

Never leave plaintext API keys in your filesystem or history.

---

## 📋 Important Notes

- AWS users: Ensure `~/.aws/credentials` exists with permission `600` or `400`. This script will auto-correct permissions if needed.
- The script uses **Let's Encrypt** by default with **ECDSA P-256** (EC-256) certificates.
- No sensitive credential data is logged or leaked during the process.
- Temp directories and temporary cert files are **cleaned automatically** even if you interrupt the script.

---

## 👨‍💻 Credits

- Built on top of the [acme.sh](https://github.com/acmesh-official/acme.sh) ACME client.
- Inspired by the open-source [Pi-hole](https://pi-hole.net/) community.
- Hardened following NIST, CIS, and SOC2 Level 2 security principles.

---

## 📜 License

This script is distributed under the [MIT License](LICENSE).

---

## 📈 SEO Tags

**Keywords**:\
`Secure HTTPS for Pi-hole`, `Pi-hole Let's Encrypt setup`, `Pi-hole SSL Docker`, `Secure Pi-hole SSL bare metal`, `acme.sh Pi-hole DNS API`, `Docker Pi-hole HTTPS SSL`, `Pi-hole SSL Automation Script`
=======
- Follow the prompts: Enter your domain, email, select DNS provider, supply API keys securely.
>>>>>>> parent of 6979e5d (Refactored for even more security and structure)
=======
- Follow the prompts: Enter your domain, email, select DNS provider, supply API keys securely.
>>>>>>> parent of 6979e5d (Refactored for even more security and structure)
=======
- Follow the prompts: Enter your domain, email, select DNS provider, supply API keys securely.
>>>>>>> parent of 6979e5d (Refactored for even more security and structure)
=======
- Follow the prompts: Enter your domain, email, select DNS provider, supply API keys securely.
>>>>>>> parent of 6979e5d (Refactored for even more security and structure)
=======
## DNS Provider Support

The script supports multiple DNS providers for domain validation. Select your provider from the menu and provide the requested credentials.

### Cloudflare

1. **Requirements**:
   - Domain managed by Cloudflare
   - Cloudflare API Token with DNS Edit permissions

2. **Setup**:
   - Create an API token in the Cloudflare dashboard with Zone:DNS:Edit permissions
   - Select Cloudflare as your DNS provider in the script
   - Enter your API token when prompted

### Namecheap

1. **Requirements**:
   - Domain registered with Namecheap
   - API access enabled in your Namecheap account
   - Whitelisted IP for API access

2. **Setup**:
   - Enable API access in your Namecheap account settings
   - Add your current IP to the API access whitelist
   - Select Namecheap as your DNS provider in the script
   - Enter your Namecheap username and API key
   - Enter source IP or let the script detect it automatically

### GoDaddy

1. **Requirements**:
   - Domain registered with GoDaddy
   - API key and secret from GoDaddy Developer Portal

2. **Setup**:
   - Create API credentials in the [GoDaddy Developer Portal](https://developer.godaddy.com/)
   - Select GoDaddy as your DNS provider in the script
   - Enter your API key and secret when prompted

### AWS Route53

1. **Requirements**:
   - Domain managed by AWS Route53
   - AWS IAM user with appropriate permissions:
     - route53:ListHostedZones
     - route53:GetChange
     - route53:ChangeResourceRecordSets

2. **Setup**:
   - Create AWS credentials with proper permissions
   - Select AWS Route53 as your DNS provider in the script
   - Choose between direct key entry or using AWS credentials file
   - If using direct key entry, provide Access Key ID, Secret Access Key, and region

### DigitalOcean

1. **Requirements**:
   - Domain managed by DigitalOcean DNS
   - DigitalOcean API token with write access

2. **Setup**:
   - Create an API token in the DigitalOcean control panel
   - Select DigitalOcean as your DNS provider in the script
   - Enter your API token when prompted

### Linode

1. **Requirements**:
   - Domain managed by Linode DNS Manager
   - Linode API token with DNS permissions

2. **Setup**:
   - Create an API token in the Linode Cloud Manager with DNS permissions
   - Select Linode as your DNS provider in the script
   - Enter your API token when prompted

### Google Cloud DNS

1. **Requirements**:
   - Domain managed by Google Cloud DNS
   - Service account with DNS Administrator role
   - Service account key file (JSON format)

2. **Setup**:
   - Create a service account in Google Cloud with DNS Administrator role
   - Generate and download a JSON key file for the service account
   - Select Google Cloud DNS as your DNS provider in the script
   - Provide the path to the JSON key file when prompted

---

## Verification
After the script completes:

1. **Access Pi-hole**: Open a browser and go to:
  ```bash
  https://ns1.mydomain.com/admin
   ```

2. **Check Certificate**:
  - Your browser should show a valid certificate issued by Let's Encrypt (or whichever CA you specified).
  - For traditional installations, verify via command line:
  ```bash
  sudo openssl x509 -in /etc/pihole/tls.pem -text -noout
  ```
  - For Docker installations, verify via command line:
  ```bash
  docker exec pihole cat /etc/pihole/tls.pem | openssl x509 -text -noout
  ```

---

## Renewal
`acme.sh` will set up a daily cron job to **automatically renew** certificates before they expire.

  - **Force a manual renew** (for testing):
    ```bash
    ~/.acme.sh/acme.sh --renew -d ns1.mydomain.com --force
    ```
     - If running as root:
      ```bash
      /root/.acme.sh/acme.sh --renew -d ns1.mydomain.com --force
      ```

---

## Troubleshooting

### General Issues
   - `acme.sh: command not found`
   If you see this error, verify that you are:
   1. Using **this script** (it calls `acme.sh` via the absolute path).
   2. Running as **Bash** (not `sh` or `dash`).
   
### DNS Validation Issues
   - **Cloudflare**: Ensure your domain's DNS is managed by the Cloudflare account corresponding to the Cloudflare token.
   - **Namecheap**: Verify that your API access is enabled, your source IP is whitelisted, and the domain is managed by Namecheap.
   - **GoDaddy**: Make sure your API key has sufficient permissions.
   - **AWS Route53**: Verify IAM permissions and that your domain is managed by Route53.
   - **DigitalOcean**: Ensure your API token has write access.
   - **Linode**: Verify your API token has DNS permissions.
   - **Google Cloud DNS**: Make sure the service account has the DNS Administrator role.

### Docker-specific Issues
   - **Container not found**: Verify the container name with `docker ps`
   - **Permission denied**: Ensure you have permissions to access Docker socket (you might need to run with sudo)
   - **Restart issues**: If the container doesn't restart properly, try manually restarting it with `docker restart pihole`

### Certificate Domain Mismatch
   Make sure the **Pi-hole domain** set by the script matches the domain in your certificate.
   - For traditional installations:
     ```bash
     pihole-FTL --show
     ```
   - For Docker:
     ```bash
     docker exec pihole pihole-FTL --show
     ```
   The `webserver.domain` should show your custom domain (e.g., `ns1.mydomain.com`).

---

## License
This project is licensed under the MIT License. Please review the license file for more details.

Thank you for using this script to secure your Pi-hole v6 installation. If you find it helpful, consider contributing or submitting issues via GitHub.
>>>>>>> parent of 9dfeb4b (Refactored for Security)
