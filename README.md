# Pi-hole v6.x HTTPS Certificate Setup 

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker Support](https://img.shields.io/badge/Docker-Support-blue)](https://www.docker.com/)
[![Pi-hole Compatible](https://img.shields.io/badge/Pi--hole-Compatible-green)](https://pi-hole.net/)
[![Let's Encrypt Compatible](https://img.shields.io/badge/Let%27s%20Encrypt-Compatible-brightgreen)](https://letsencrypt.org/)
[![acme.sh powered](https://img.shields.io/badge/acme.sh-powered-blue)](https://github.com/acmesh-official/acme.sh)
[![HTTPS Enabled](https://img.shields.io/badge/HTTPS-Enabled-brightgreen)]()
[![DNS Providers](https://img.shields.io/badge/DNS%20Providers-8-orange)]()
[![Auto Renewal](https://img.shields.io/badge/Auto%20Renewal-Enabled-success)]()

**Secure your Pi-hole admin interface with HTTPS/SSL using this automated setup script. Works with both traditional and Docker Pi-hole installations.**

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Supported DNS Providers](#supported-dns-providers)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration Options](#configuration-options)
- [Docker Support](#docker-support)
- [Automatic Certificate Renewal](#automatic-certificate-renewal)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)
- [Contributing](#contributing)
- [License](#license)

## 🔍 Overview

This script automates the process of securing your Pi-hole admin interface with HTTPS using Let's Encrypt certificates and DNS validation. It supports both traditional Pi-hole installations and Docker deployments, making it versatile for various setup configurations.

The script leverages [acme.sh](https://github.com/acmesh-official/acme.sh) for certificate management and integrates with multiple DNS providers for validation, allowing you to obtain valid SSL certificates even when your Pi-hole is not publicly accessible.

## ✨ Features

- **Automated HTTPS Setup**: One-command solution to secure your Pi-hole admin interface
- **Multiple DNS Provider Support**: Works with 8 major DNS providers for validation
- **Docker Support**: Detects and configures certificates for Docker Pi-hole installations
- **Automatic Renewal**: Sets up scheduled certificate renewal via cron
- **ECC Certificates**: Uses efficient and secure ECC certificates
- **User-Friendly**: Interactive prompts guide you through the setup process

## 📋 Prerequisites

- A running Pi-hole installation (bare metal or Docker)
- Domain or subdomain pointed to your Pi-hole's IP address
- API credentials for your DNS provider
- `bash` shell environment
- `curl` installed on your system
- Appropriate permissions to modify Pi-hole configuration

## 🔒 Supported DNS Providers

The script supports DNS validation through the following providers:

1. **Cloudflare** - Requires API token
2. **Namecheap** - Requires username, API key, and source IP
3. **GoDaddy** - Requires API key and secret
4. **AWS Route53** - Supports both API keys and credential files
5. **DigitalOcean** - Requires API token
6. **Linode** - Requires API token
7. **Google Cloud DNS** - Requires service account key file
8. **deSEC** - Requires API token

## 💻 Installation

1. Download the script:

```bash
curl -O https://raw.githubusercontent.com/PrimePoobah/piholev6-ssl-setup/main/piholev6-ssl-setup.sh
```

2. Make it executable:

```bash
chmod +x piholev6-ssl-setup.sh
```

3. Run the script:

```bash
./piholev6-ssl-setup.sh
```

## 🚀 Usage

When you run the script, it will guide you through the setup process with interactive prompts:

1. Detect if you're using Docker for Pi-hole
2. Ask for your domain/subdomain (e.g., `pihole.yourdomain.com`)
3. Request your email address (for Let's Encrypt registration)
4. Ask you to select your DNS provider
5. Collect the necessary API credentials for your chosen provider
6. Install acme.sh if not already present
7. Obtain the SSL certificate via DNS validation
8. Configure Pi-hole to use the new certificate
9. Setup automatic renewal

## ⚙️ Configuration Options

The script collects all necessary information interactively, including:

- **Domain**: The domain or subdomain for your Pi-hole admin interface
- **Email**: Your email for ACME registration and renewal notifications
- **DNS Provider**: Your DNS hosting provider for validation
- **API Credentials**: Authentication details for your DNS provider

## 🐳 Docker Support

For Docker installations, the script will:

1. Ask for your Pi-hole container name (defaults to "pihole")
2. Copy the certificate to the appropriate location in the container
3. Configure the container to use HTTPS
4. Set up renewal hooks that work with your Docker container

Example Docker-specific commands:

```bash
docker cp /path/to/tls.pem pihole:/etc/pihole/tls.pem
docker exec pihole pihole-FTL --config webserver.domain your-domain.com
docker exec pihole service pihole-FTL restart
```

## 🔄 Automatic Certificate Renewal

The script configures acme.sh to automatically renew your certificate before expiration. It adds a cron job that will:

1. Check certificate status approximately every 60 days
2. Renew if the certificate is nearing expiration
3. Automatically install the renewed certificate
4. Restart the Pi-hole FTL service to apply changes

You can manually force a renewal with:

```bash
~/.acme.sh/acme.sh --renew -d your-domain.com --force
```

## ❓ Troubleshooting

**Certificate Issuance Fails**:
- Verify your DNS provider API credentials
- Ensure your domain's DNS is properly configured
- Check if your DNS provider has API rate limits

**HTTPS Not Working After Setup**:
- Verify the certificate was properly installed: `ls -l /etc/pihole/tls.pem`
- Check Pi-hole FTL logs: `sudo systemctl status pihole-FTL`
- Ensure your domain resolves to the correct IP address

**Docker-Specific Issues**:
- Make sure the container name was entered correctly
- Verify the certificate path inside the container
- Check Docker logs: `docker logs pihole`

## 🔐 Security Considerations

- The script stores API credentials temporarily in environment variables
- In Docker environments, certificates are copied through Docker commands
- API tokens should have the minimum required permissions
- For AWS and Google Cloud, use restricted service accounts

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Credits

This project wouldn't be possible without the following open-source projects and contributors:

- **[Pi-hole](https://pi-hole.net/)**: Network-wide ad blocking solution that makes your network faster and more secure. Pi-hole is a registered trademark of Pi-hole LLC.
- **[acme.sh](https://github.com/acmesh-official/acme.sh)**: A pure Unix shell script implementing ACME client protocol, providing the backbone of our certificate management.
- **[Let's Encrypt](https://letsencrypt.org/)**: Free, automated, and open certificate authority providing the SSL certificates used in this project.
- **[mplabs](https://github.com/mplabs)**: Special thanks for contributing the deSEC DNS provider support, expanding the script's functionality.

---

**Note**: This script is not officially affiliated with Pi-hole. Pi-hole is a registered trademark of Pi-hole LLC.
