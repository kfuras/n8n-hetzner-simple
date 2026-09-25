# YouTube MCP Setup

Connect your OpenClaw agent to YouTube. 40 tools for uploading, analytics, comments, playlists, thumbnails, and more.

## How It Works

The YouTube MCP server is a Python package (`youtube-studio-mcp`) that gets baked into the OpenClaw Docker image at build time. This means:

- No manual `pip install` inside running containers
- Survives every restart and rebuild
- The binary lives at `/opt/youtube-mcp/bin/youtube-studio-mcp` inside the container

Your Google credentials are mounted into the container via a Docker volume, so they persist separately from the image.

## Step 1: Patch the Dockerfile

After cloning the OpenClaw repo (`git clone https://github.com/openclaw/openclaw.git ~/openclaw`), you need to inject the YouTube MCP server into the Dockerfile before it gets built.

Add this block to `~/openclaw/Dockerfile` **before** the `USER` line:

```dockerfile
# --- Custom: YouTube MCP server ---
RUN apt-get update -qq && \
    apt-get install -y -qq --no-install-recommends python3 python3-venv && \
    rm -rf /var/lib/apt/lists/* && \
    python3 -m venv /opt/youtube-mcp && \
    /opt/youtube-mcp/bin/pip install --no-cache-dir youtube-studio-mcp
# --- End custom ---
```

## Step 2: Add Volume Mounts

In your `docker-compose.yml`, make sure you have these volumes:

```yaml
volumes:
  - ${OPENCLAW_CONFIG_DIR}/youtube-mcp:/home/node/.youtube-mcp
```

And add the MCP binary to the container's PATH in the environment section:

```yaml
environment:
  - PATH=/opt/youtube-mcp/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

## Step 3: Build and Start

```bash
cd ~/openclaw
docker compose build
docker compose up -d
```

The build takes a few minutes. When it finishes, the YouTube MCP binary is available inside the container.

## Step 4: Google OAuth (on your local machine)

The YouTube MCP server needs a one-time browser sign-in. Do this on your laptop (not the server):

1. Go to https://console.cloud.google.com
2. Create a project, enable YouTube Data API v3, YouTube Analytics API, YouTube Reporting API
3. Create OAuth credentials (Desktop app type)
4. Add your email as a test user under the OAuth consent screen
5. Download the credentials JSON file

Then:

```bash
pip install youtube-studio-mcp
mkdir -p ~/.youtube-mcp
cp ~/Downloads/client_secret_*.json ~/.youtube-mcp/client_secret.json
youtube-studio-mcp
```

A browser opens -- sign in with the Google account that **owns** your YouTube channel. After authorizing, a `token.json` is created at `~/.youtube-mcp/token.json`.

## Step 5: Copy Credentials to Server

```bash
scp ~/.youtube-mcp/client_secret.json youruser@YOUR_SERVER_IP:~/.openclaw/youtube-mcp/
scp ~/.youtube-mcp/token.json youruser@YOUR_SERVER_IP:~/.openclaw/youtube-mcp/
```

## Step 6: Register with OpenClaw

```bash
ssh youruser@YOUR_SERVER_IP
docker exec openclaw-openclaw-gateway-1 openclaw mcp set youtube '{"command": "/opt/youtube-mcp/bin/youtube-studio-mcp"}'
```

Verify it's registered:

```bash
docker exec openclaw-openclaw-gateway-1 openclaw mcp list
```

You should see `youtube` in the list.

## Step 7: Test

Send a message to your agent from whichever channel you have configured -- WhatsApp, Discord, Telegram, or the web UI:

> "Show me my YouTube channel stats"

If it responds with your channel data (subscribers, views, watch time), the connection is working.

## What You Can Do

- Upload videos
- Check analytics (views, watch time, retention, revenue)
- Manage playlists
- Read and reply to comments
- Set thumbnails
- Get SEO suggestions and trending topics
- Extract transcripts

40 tools total -- just tell the bot what you need.

## Troubleshooting

- **Token expired:** Redo the Google OAuth on your local machine and copy the new `token.json` to the server.
- **No analytics data:** Make sure you signed in with the Google account that OWNS the channel, not a manager account.
- **MCP server not found:** Check that the volume mount is correct in `docker-compose.yml` and rebuild: `docker compose build && docker compose up -d`
- **Binary missing after rebuild:** The Dockerfile patch may have been lost if you did a `git pull` on the OpenClaw repo. Re-apply the patch from Step 1 and rebuild.
