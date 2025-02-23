# Pi-hole v6 SSL Automation Using acme.sh and Cloudflare DNS (Absolute Path Method)

This repository automates obtaining and installing a Let’s Encrypt SSL certificate for [Pi-hole v6](https://pi-hole.net/) using [acme.sh](https://github.com/acmesh-official/acme.sh) and **Cloudflare DNS**. The script uses the **absolute path** to `acme.sh` rather than relying on shell aliases or profiles. This approach ensures reliable operation in both interactive and non-interactive environments, including Debian 12.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Script Details](#script-details)
- [Usage](#usage)
- [Verification](#verification)
- [Renewal](#renewal)
- [Troubleshooting](#troubleshooting)
- [License](#license)

---

## Overview

Pi-hole v6 includes an embedded web server that can be secured with an SSL/TLS certificate. By default, Pi-hole v6 generates a self-signed certificate, but you can automate certificate issuance using:

- **acme.sh**: An ACME protocol client script.
- **Let’s Encrypt**: A free Certificate Authority (CA).
- **Cloudflare DNS plugin**: To validate domain ownership via DNS.

This repository’s script uses the **absolute path** to `acme.sh`. It installs `acme.sh` into the current user’s home directory (or `/root` if running as root) and then calls it directly. This avoids problems with aliases not loading in non-interactive shells or different shell configurations.

---

## Prerequisites

1. **Pi-hole v6**  
   - Already installed and running on your Debian 12 (or other Linux) system.
2. **Cloudflare Account**  
   - You must have a [Cloudflare](https://dash.cloudflare.com/) account managing your domain’s DNS.
3. **Cloudflare API Token**  
   - Your Cloudflare token with sufficient permissions to create DNS TXT records for domain validation.  
   - For more information, see Cloudflare’s [API Tokens documentation](https://developers.cloudflare.com/api/tokens/create/).
4. **A Registered Domain**  
   - The domain you control must point to your Pi-hole or be resolvable (e.g., `ns1.mydomain.com`).  
5. **Debian 12**  
   - The script also works on other Debian/Ubuntu-based systems. Adjust commands as necessary for your environment.

---

## Script Details

The script:
1. Prompts you for:
   - **Domain** (e.g., `ns1.mydomain.com`)
   - **Email** (for both ACME registration and Cloudflare)
   - **Cloudflare API Token** (paste in plain text)
2. **Installs `acme.sh`** (if not already installed) to `~/.acme.sh` (or `/root/.acme.sh` if run as root).
3. **Issues an SSL Certificate** from Let’s Encrypt, using the Cloudflare DNS validation plugin.
4. **Installs** the resulting certificate into `/etc/pihole/tls.pem`, combining your private key and public certificate.
5. **Configures Pi-hole** to use your domain name to avoid domain mismatch warnings.

---

## Usage

1. **Clone or download** this repository:
   ```bash
   git clone https://github.com/PrimePoobah/Pihole_V6_Lets_Encrypt_SSL_Setup_Script.git
   cd Pihole_V6_Lets_Encrypt_SSL_Setup_Script
   ```
   
2. **Make the script executable:**
  ```bash
  chmod +x pihole-ssl-setup.sh
   ```

3. **Run the script** (as root or a user with sudo privileges):
  ```bash
  sudo ./pihole-ssl-setup.sh
   ```

4. **Follow the prompts:**
  - **Domain**: e.g. `ns1.mydomain.com`
  - **Email**: e.g. `myemail@example.com`
  - **Cloudflare API Token**: Paste your token in plain text.

The script will:
  - Install or verify `acme.sh`
  - Issue an SSL certificate
  - Install the certificate into Pi-hole
  - Restart Pi-hole FTL

## Verification
After the script completes:

1. **Access Pi-hole**: Open a browser and go to:
  ```bash
  https://ns1.mydomain.com/admin
   ```

2. **Check Certificate**:
  - Your browser should show a valid certificate issued by Let’s Encrypt (or whichever CA you specified).
  - You can also verify via command line:
  ```bash
  sudo openssl x509 -in /etc/pihole/tls.pem -text -noout
   ```

## Renewal
`acme.sh` will set up a daily cron job to **automatically renew** certificates before they expire.

  - **Force a manual renew** (for testing):
    ```bash
    ~/.acme.sh/acme.sh --renew -d ns1.mydomain.com --force
   ```
   - If running as root:

## Troubleshooting
   - `acme.sh: command not found`
   If you see this error, verify that you are:
   1. Using **this script** (it calls `acme.sh` via the absolute path).
   2. Running as **Bash** (not `sh` or `dash`).
   - **DNS Validation Failures**
   Ensure your domain’s DNS is managed by the Cloudflare account corresponding to the Cloudflare token.
   - **Certificate Domain Mismatch**
   Make sure the **Pi-hole domain** set by the script matches the domain in your certificate. You can check with:
 ```bash
pihole-FTL --show
```
The `webserver.domain` should show your custom domain (e.g., `ns1.mydomain.com`).

## License
This project is licensed under the MIT License. Please review the license file for more details.

Thank you for using this script to secure your Pi-hole v6 installation. If you find it helpful, consider contributing or submitting issues via GitHub.****
