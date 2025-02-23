# Pi-hole IPv6 SSL Certificate Automation

This script automates the process of obtaining and installing an SSL certificate for your Pi-hole web interface using Let's Encrypt and Cloudflare DNS verification, with support for IPv6 configurations.

## Prerequisites

- A running Pi-hole installation with IPv6 enabled
- A domain or subdomain managed by Cloudflare
- Cloudflare API token with DNS editing permissions
- Root or sudo access on your Pi-hole server
- IPv6 connectivity on your server

## Features

- Automatic installation of acme.sh certificate manager
- Let's Encrypt certificate issuance using Cloudflare DNS verification
- Automatic certificate installation into Pi-hole
- Configuration of Pi-hole to use the new certificate
- Support for IPv6 accessibility
- Automatic service restart after installation

## Installation

1. Download the script:
```bash
curl -O https://raw.githubusercontent.com/yourusername/pihole-ssl/main/piholev6-ssl-setup.sh
chmod +x piholev6-ssl-setup.sh
