# Discord Bot Setup

## Create the Bot

1. Go to https://discord.com/developers/applications
2. Click **New Application** — name it (e.g. your agent name)
3. Go to **Bot** section
4. Click **Reset Token** — copy and save the token securely

## Enable Intents

Still in the Bot section, enable under **Privileged Gateway Intents**:
- **Message Content Intent** (required)
- **Server Members Intent** (recommended)

## Invite the Bot

Use this URL (replace YOUR_APP_ID with your Application ID from the General Information page):

```
https://discord.com/oauth2/authorize?client_id=YOUR_APP_ID&scope=bot+applications.commands&permissions=117824
```

This grants: View Channels, Send Messages, Read Message History, Embed Links, Attach Files, Add Reactions.

Select your server and authorize.

## Add Token to OpenClaw

SSH into your server:

```bash
ssh amam@YOUR_SERVER_IP
nano ~/openclaw/.env
```

Replace `DISCORD_BOT_TOKEN=REPLACE_ME` with your actual token.

Restart OpenClaw:

```bash
cd ~/openclaw && docker compose restart
```

## Pair Your Account

1. DM the bot on Discord
2. It responds with a pairing code
3. Approve it:

```bash
docker exec openclaw-openclaw-gateway-1 openclaw pairing approve discord CODE
```

You're connected. The bot will now respond to your DMs.
