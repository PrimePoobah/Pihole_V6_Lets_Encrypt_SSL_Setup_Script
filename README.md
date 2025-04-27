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
curl -O  https://raw.githubusercontent.com/PrimePoobah/Pihole_V6_Lets_Encrypt_SSL_Setup_Script/piholev6-ssl-setup.sh
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
```

---

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
