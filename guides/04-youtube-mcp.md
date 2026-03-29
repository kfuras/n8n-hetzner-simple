# YouTube MCP Setup

The YouTube MCP server is already installed in the Docker image. You just need to add your Google credentials and register it.

## Prerequisites

Complete the Google OAuth setup first:
1. Go to https://console.cloud.google.com
2. Create a project, enable YouTube Data API v3, YouTube Analytics API, YouTube Reporting API
3. Create OAuth credentials (Desktop app)
4. Add your email as a test user
5. Download the credentials JSON file

## First-Time Authentication (on your local machine)

The YouTube MCP server needs a one-time browser sign-in. Do this on your laptop:

```bash
pip install youtube-studio-mcp
mkdir -p ~/.youtube-mcp
cp ~/Downloads/client_secret_*.json ~/.youtube-mcp/client_secret.json
youtube-studio-mcp
```

A browser opens — sign in with the Google account that **owns** your YouTube channel. After authorizing, a `token.json` is created at `~/.youtube-mcp/token.json`.

## Copy Credentials to Server

```bash
scp ~/.youtube-mcp/client_secret.json amam@YOUR_SERVER_IP:~/.openclaw/youtube-mcp/
scp ~/.youtube-mcp/token.json amam@YOUR_SERVER_IP:~/.openclaw/youtube-mcp/
```

## Register with OpenClaw

```bash
ssh amam@YOUR_SERVER_IP
docker exec openclaw-openclaw-gateway-1 openclaw mcp set youtube '{"command": "/opt/youtube-mcp/bin/youtube-studio-mcp"}'
cd ~/openclaw && docker compose restart
```

## Test

Send a Discord message to your bot:

> "Show me my YouTube channel stats"

If it responds with your channel data, the connection is working.

## What You Can Do

- Upload videos
- Check analytics (views, watch time, retention, revenue)
- Manage playlists
- Read and reply to comments
- Set thumbnails
- Get SEO suggestions and trending topics
- Extract transcripts

40 tools total — just tell the bot what you need.
