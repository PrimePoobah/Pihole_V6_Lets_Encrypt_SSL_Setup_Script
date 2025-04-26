# Secure HTTPS Setup for Pi-hole using acme.sh (Docker + Bare-Metal)

This script securely configures **HTTPS and SSL certificates** for your **Pi-hole** installation using the **acme.sh** ACME client and **DNS API validation**.  
Supports both **bare-metal** and **Docker** Pi-hole setups with auto-renewal, hardened security, and major DNS providers.

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
   ```bash
   ./pihole-https-setup.sh
   ```

- Follow the prompts: Enter your domain, email, select DNS provider, supply API keys securely.
