# Pi-hole HTTPS Setup Script

This script securely configures HTTPS certificates for your Pi-hole installation using [acme.sh](https://github.com/acmesh-official/acme.sh).  
It supports both **bare-metal** and **Docker** Pi-hole environments and automates DNS validation through major DNS providers (Cloudflare, Namecheap, GoDaddy, AWS Route53, DigitalOcean, Linode, Google Cloud DNS, deSEC).

---

## ⚡ Features

- **Automated Certificate Issuance** using acme.sh (Let's Encrypt EC-256)
- **DNS Provider Support:** Cloudflare, Namecheap, GoDaddy, AWS, DigitalOcean, Linode, Google Cloud DNS, deSEC
- **Docker and Bare Metal Support**
- **Automatic Installation into Pi-hole HTTPS Service**
- **Auto-Renewal Hook Setup** with acme.sh

---

## 🔒 Security Hardening

This script has been **professionally audited** and includes:

- ✅ Secrets (API keys, tokens) **never stored globally** — scoped to single subshells.
- ✅ **Input validation** for all user inputs (domain, email, tokens, etc.)
- ✅ **GCP JSON Key Validation** (correct format + required fields)
- ✅ **AWS Credentials Validation** (permissions must be 600/400 + required fields)
- ✅ **Secure Temporary Directory** (`$HOME/.acme.sh/tmp/` with `chmod 700`)
- ✅ **Secure Temp Files** (`chmod 600` applied to combined cert)
- ✅ **Public IP Fetch Fallbacks** (3 providers + strict IPv4 regex validation)
- ✅ **Sudo Availability Check** (must be passwordless or script exits early)
- ✅ **No assumptions about environment** — clean checks for needed tools (`curl`, `cat`, `tee`, `docker`, `jq`, `stat`, etc.)

---

## 🛠️ Usage Instructions

1. **Prepare Your Environment**

   - Install `sudo`, `curl`, `docker` (optional), and `jq` if missing:
     ```bash
     sudo apt install -y sudo curl jq
     ```
   - Ensure your Pi-hole instance is already running (bare-metal or Docker).

2. **Download the Script**

   - Save the script to a local file, e.g., `pihole-https-setup.sh`
   - Make it executable:
     ```bash
     chmod +x pihole-https-setup.sh
     ```

3. **Run the Script**
   ```bash
   ./pihole-https-setup.sh
   ```
