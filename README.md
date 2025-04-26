# Secure HTTPS Setup Script for Pi-hole using acme.sh (Docker and Bare-Metal Support)

Easily and securely configure **HTTPS/SSL certificates** for your **Pi-hole** instance using [acme.sh](https://github.com/acmesh-official/acme.sh) with DNS API validation.\
This script is designed for **bare-metal** and **Docker-based** Pi-hole installations, fully hardened for production, and audit-ready.

---

## 🚀 Key Features

- Automatically issues **Let's Encrypt EC-256 certificates** (lightweight, secure).
- Supports **DNS API validation** with:
  - Cloudflare
  - Namecheap
  - GoDaddy
  - AWS Route53
  - DigitalOcean
  - Linode
  - Google Cloud DNS
  - deSEC
- Works for both **bare-metal** and **Dockerized** Pi-hole deployments.
- Detects Pi-hole environment **automatically** (Docker or Bare-Metal).
- Fully **automated HTTPS installation** and **Pi-hole FTL service reload**.
- **Auto-renewal hooks** configured through acme.sh.
- Full **secure logging** to `~/pihole-https-setup.log`.
- **Secure temp file handling** and automatic cleanup even on script failure.
- Hardened against:
  - Command injection
  - Secret leakage
  - Race conditions
  - Permission misconfigurations

---

## 🔒 Security Highlights

This script implements advanced security best practices:

- **Secrets never exported globally**: Credentials are scoped to temporary subshells.
- **No hardcoded paths**: All system paths and file locations are variables.
- **Trap cleanup**: Temporary files are securely deleted on exit or interruption.
- **Secure temp directories**: Created with `mktemp -d` and `chmod 700`.
- **Strict input validation**: Domains, emails, Docker container names, and API tokens validated safely.
- **Injection prevention**: All user inputs are safely sanitized.
- **AWS credentials**: Permissions validated dynamically and corrected if needed.
- **Centralized logging**: Logs actions (not secrets) into a secured `pihole-https-setup.log` file.

---

## 📖 How to Use

### 1. Prerequisites

Install required tools:

```bash
sudo apt update
sudo apt install -y curl jq sudo docker.io
```

(_Docker only if you are running Pi-hole in a container._)

Make sure you have **passwordless sudo** access.

---

### 2. Download the Script

   ```bash
   curl -O https://yourdomain.com/path/to/pihole-https-setup.sh
   chmod +x pihole-https-setup.sh

   ```

3. **Run the Script**
   ```bash
   ./pihole-https-setup.sh
   ```

- Follow the prompts: Enter your domain, email, select DNS provider, supply API keys securely.
