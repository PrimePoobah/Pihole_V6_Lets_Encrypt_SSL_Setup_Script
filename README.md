# Secure HTTPS Setup for Pi-hole using acme.sh (Docker + Bare-Metal)

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
=======
- Follow the prompts: Enter your domain, email, select DNS provider, supply API keys securely.
>>>>>>> parent of 6979e5d (Refactored for even more security and structure)
=======
- Follow the prompts: Enter your domain, email, select DNS provider, supply API keys securely.
>>>>>>> parent of 6979e5d (Refactored for even more security and structure)
