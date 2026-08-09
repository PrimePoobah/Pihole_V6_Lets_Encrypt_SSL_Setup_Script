# 🕶️ Pi-hole v6.x HTTPS Certificate Setup — Now with 69% More Sass

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)
![Docker](https://img.shields.io/badge/Docker-Supported-blue?style=flat-square)
![Let's Encrypt](https://img.shields.io/badge/Let's%20Encrypt-Yes-green?style=flat-square)
![HTTPS Enabled](https://img.shields.io/badge/HTTPS-Enabled-brightgreen?style=flat-square)
[![Auto Renewal](https://img.shields.io/badge/Auto--Renewal-Enabled-brightgreen)](https://github.com/acmesh-official/acme.sh)

---

## 🔫 Welcome to the Show

So, you’ve got a Pi-hole. Congratulations, you’ve taken your first step toward *not* being followed by a thousand ad trackers. But are you browsing your Pi-hole dashboard over HTTP like a total peasant? Stop it. Seriously.

This script, makes it *stupid easy* to secure your Pi-hole with HTTPS using Let's Encrypt, DNS validation, and the magical powers of `acme.sh`. Works with both regular and Docker Pi-hole setups because inclusivity matters.

---
> TL;DR: Run a script. Get SSL. Feel fancy. Maybe cry tears of joy. Or frustration. Depends on your DNS provider.
---

## 🧠 Table of Awesome
- [Overview](#-overview)
- [Features](#-features)
- [Stuff You Gotta Have](#-prerequisites)
- [DNS Avenger Providers](#-supported-dns-providers)
- [Install Me Baby](#-installation)
- [Use It or Lose It](#-usage)
- [Fancy Configs](#️-configuration-options)
- [Dockerheads Unite](#-docker-support)
- [Auto-Magic Renewals](#-automatic-certificate-renewal)
- [Things That Go Boom](#-troubleshooting)
- [Security-ish](#-security-considerations)
- [Contribute or Else](#-contributing)
- [License Stuff](#-license)
- [Credits & Thanks-for-All-the-Fish](#-credits)

---

## 🔍 Overview

You want HTTPS. I want tacos. Let’s meet in the middle.

This script automagically sets up HTTPS on your Pi-hole admin interface using Let’s Encrypt and DNS validation — even if your Pi-hole is chilling behind a NAT like it’s hiding from John Wick.

It works on bare metal, in Docker, and possibly in the Quantum Realm (not tested).

---

## ✨ Features (Cue Drumroll)
- 💥 One-command HTTPS setup
- 🧙 DNS validation with *eight* mystical DNS providers
- 🐳 Docker support, because containerization is sexy
- 🔄 Auto-renewal, because remembering things is for chumps
- 🔐 ECC certs because... math
- 🧑‍🎤 Interactive setup wizard that holds your hand like a scared raccoon
- 🎚️ Optional control over whether the Pi-hole web UI is forced to listen on 80/443

---

## 📋 Prerequisites
Before we ride this unicorn, you’ll need:
- A working Pi-hole (duh)
- A domain or subdomain aimed squarely at your Pi-hole
- DNS provider API creds (no stealing!)
- A bash shell and `curl` installed
- Root, if Pi-hole runs bare-metal (the script writes `/etc/pihole/tls.pem` and restarts `pihole-FTL` directly). For Docker, just run the script as whichever user manages your Pi-hole container — don't `sudo` into a rootless Docker setup, or the renewal cron won't be able to reach it later.

---

## 🔒 Supported DNS Providers
We got ‘em all. Well, at least the cool ones:

- Cloudflare (bring your API token, not your drama)
- Namecheap (username, API key, source IP… and a love letter)
- GoDaddy (key + secret = 🔓)
- AWS Route53 (keys or credential files, you choose your poison)
- DigitalOcean (token, please)
- Linode (yep, also token)
- Google Cloud DNS (service account JSON file — it’s a party)
- deSEC (token, once again)

---

## 💻 Installation (aka CTRL+C this stuff)
```bash
curl -O https://raw.githubusercontent.com/PrimePoobah/Pihole_V6_Lets_Encrypt_SSL_Setup_Script/main/piholev6-ssl-setup.sh
chmod +x piholev6-ssl-setup.sh
./piholev6-ssl-setup.sh
```

---

## 🚀 Usage (Do the Thing)
When you run this magnificent beast:
1. Asks for your domain (e.g., `pihole.yourcooldomain.com`)
2. Gets your email (for Let's Encrypt. No spam. Probably.)
3. Lets you decide whether it should force the Pi-hole web UI back to ports 80/443
4. Asks which DNS god you worship
5. Collects your API soul… I mean credentials
6. Asks whether Pi-hole runs bare-metal or in Docker (no crystal ball involved)
7. Installs `acme.sh` if it’s slacking
8. Gets your certificate 🎉
9. Configures Pi-hole to use it
10. Sets up auto-renewal so you can forget this ever happened

---

## ⚙️ Configuration Options
No YAML, no BS. It’ll ask you things like:
- Your domain
- Your email
- Whether to reset the Pi-hole web interface ports to 80/443
- Your DNS provider
- Your API credentials

You answer. It obeys. Like a good intern.

---

## 🐳 Docker Support
Using Docker? You Rockstar. No problem.

- It asks for your container name (`pihole` by default, don’t be a maverick)
- Copies certs into the container
- Tells Pi-hole to behave with HTTPS
- Hooks into renewals like a cybernetic octopus

Example nerd-fu:
```bash
docker cp /path/to/tls.pem pihole:/etc/pihole/tls.pem
docker exec pihole pihole-FTL --config webserver.domain your-domain.com
docker exec pihole service pihole-FTL restart
```

---

## 🔄 Automatic Certificate Renewal
Because who wants to do anything manually?

This script:
- Sets a cron job to check every 60 days-ish
- Renews when it’s close to expiry
- Installs the new cert
- Restarts `pihole-FTL` like a champ

Manual override?
```bash
~/.acme.sh/acme.sh --renew -d your-domain.com --force
```

---

## ❓ Troubleshooting (aka Crap Hit the Fan)
**Can’t get a cert?**
- Check your DNS API creds
- Verify your DNS settings
- Sacrifice a virtual goat? (not required, but might help)

**HTTPS not working?**
- Check your files: `ls -l /etc/pihole/tls.pem`
- Read the logs: `sudo systemctl status pihole-FTL`
- Verify DNS is pointed correctly

**Docker crying?**
- Check your container name
- Verify paths
- Read those juicy `docker logs pihole`

---

## 🔐 Security Considerations
Because I care about your bits:
- API creds are stored *temporarily*
- Docker copies are done internally
- Only give API tokens the bare minimum rights
- Use restricted service accounts if you’re an AWS/Google ninja

---

## 🤝 Contributing (Let’s Be Besties)
Wanna help? Sweet.

1. Fork the repo
2. `git checkout -b feature/deadpool-does-ssl`
3. Make your changes. Go wild.
4. `git commit -m "Made it 1000% cooler"`
5. `git push origin feature/deadpool-does-ssl`
6. Open a PR. I'll bring the tacos.

---

## 📄 License

MIT. Do whatever. But if it breaks, you get to keep both halves.

---

## 🙏 Credits

This project wouldn't be possible without the following open-source projects and contributors:

- **[Pi-hole](https://pi-hole.net/)**: Because ads suck.
- **[acme.sh](https://github.com/acmesh-official/acme.sh)**: Shell-fu for SSL magic.
- **[Let's Encrypt](https://letsencrypt.org/)**: Saving the internet one free cert at a time.
- **[mplabs](https://github.com/mplabs)**: For adding deSEC support and increasing the awesome.

---

> _“This is not officially affiliated with Pi-hole, but it’s got a whole lotta love for it.”_
> 
---
🧨 Now go secure your Pi-hole like a cyber-ninja.
