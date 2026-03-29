# Security

## What's Already Configured

Your server comes with:
- **SSH key-only access** — no password login
- **Fail2Ban** — blocks IPs after 2 failed SSH attempts
- **UFW firewall** — only ports 22 (SSH), 80 (HTTP), 443 (HTTPS) open
- **OpenClaw on loopback** — Control UI only accessible via SSH tunnel, not the internet
- **Discord pairing** — only approved users can talk to the bot

## SSH Access

Only these IPs can SSH in (configured in firewall):
- Your IP
- Kjetil's IP (for support)

To add a new IP, contact Kjetil.

## Secrets

All API keys and tokens are stored in `~/openclaw/.env`:
- `OPENCLAW_GATEWAY_TOKEN` — Control UI access
- `DISCORD_BOT_TOKEN` — Discord bot
- `OPENROUTER_API_KEY` — AI model access
- `GOG_KEYRING_PASSWORD` — internal encryption

Never share these. If compromised, regenerate and update.

## Updating OpenClaw

```bash
ssh amam@YOUR_SERVER_IP
cd ~/openclaw
git pull
docker compose build
docker compose up -d
```

This rebuilds the image with the latest OpenClaw version and restarts.
