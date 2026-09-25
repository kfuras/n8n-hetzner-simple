#!/bin/bash
# Setup OpenClaw with Docker (baked-in MCP servers)
# Clones official repo, injects MCP server into Dockerfile, builds and runs
set -e

USERNAME="$1"

OPENCLAW_DIR="/home/$USERNAME/openclaw"
CONFIG_DIR="/home/$USERNAME/.openclaw"
ENV_FILE="$OPENCLAW_DIR/.env"

echo "Setting up OpenClaw..."

# Create persistent host directories
mkdir -p "$CONFIG_DIR/workspace"
mkdir -p "$CONFIG_DIR/youtube-mcp"
chown -R 1000:1000 "$CONFIG_DIR"

# Clone official OpenClaw repo (source build as per docs)
if [ ! -d "$OPENCLAW_DIR/.git" ]; then
  echo "Cloning OpenClaw repository..."
  git clone https://github.com/openclaw/openclaw.git "$OPENCLAW_DIR"
  chown -R "$USERNAME:$USERNAME" "$OPENCLAW_DIR"
else
  echo "OpenClaw repo already cloned"
fi

# Inject MCP server installation into the Dockerfile (before the USER line)
echo "Adding YouTube MCP server to Dockerfile..."
if ! grep -q 'youtube-studio-mcp' "$OPENCLAW_DIR/Dockerfile"; then
  sed -i '/^USER /i \
# --- Custom: YouTube MCP server ---\
RUN apt-get update -qq \&\& \\\
    apt-get install -y -qq --no-install-recommends python3 python3-venv \&\& \\\
    rm -rf /var/lib/apt/lists/* \&\& \\\
    python3 -m venv /opt/youtube-mcp \&\& \\\
    /opt/youtube-mcp/bin/pip install --no-cache-dir youtube-studio-mcp\
# --- End custom ---' "$OPENCLAW_DIR/Dockerfile"
  echo "Dockerfile patched"
else
  echo "Dockerfile already patched"
fi

# Copy our docker-compose.yml (overrides the repo's default)
cp /tmp/openclaw-config/docker-compose.yml "$OPENCLAW_DIR/docker-compose.yml"

# Generate .env if it doesn't exist
if [ ! -f "$ENV_FILE" ]; then
  GATEWAY_TOKEN=$(openssl rand -hex 32)

  cat > "$ENV_FILE" <<EOF
OPENCLAW_GATEWAY_TOKEN=$GATEWAY_TOKEN
OPENCLAW_GATEWAY_BIND=lan
OPENCLAW_GATEWAY_PORT=18789
OPENCLAW_CONFIG_DIR=$CONFIG_DIR
OPENCLAW_WORKSPACE_DIR=$CONFIG_DIR/workspace
DISCORD_BOT_TOKEN=REPLACE_ME
EOF
  chmod 600 "$ENV_FILE"

  # Save token for easy retrieval
  echo "$GATEWAY_TOKEN" > "$CONFIG_DIR/gateway-token.txt"
  chmod 600 "$CONFIG_DIR/gateway-token.txt"
  chown 1000:1000 "$CONFIG_DIR/gateway-token.txt"

  echo "Generated gateway token and .env"
else
  echo ".env already exists — preserving secrets"
fi

# Create openclaw.json with base config
if [ ! -f "$CONFIG_DIR/openclaw.json" ]; then
  cat > "$CONFIG_DIR/openclaw.json" <<'OCJSON'
{
  "gateway": {
    "mode": "local",
    "bind": "lan",
    "controlUi": {
      "allowedOrigins": ["http://localhost:18789", "http://127.0.0.1:18789"]
    }
  },
  "channels": {
    "discord": {
      "enabled": true,
      "token": {
        "source": "env",
        "provider": "default",
        "id": "DISCORD_BOT_TOKEN"
      },
      "dmPolicy": "pairing",
      "groupPolicy": "allowlist"
    },
    "whatsapp": {
      "enabled": false
    }
  }
}
OCJSON
  chmod 600 "$CONFIG_DIR/openclaw.json"
  chown 1000:1000 "$CONFIG_DIR/openclaw.json"
  echo "Created openclaw.json"
fi

# Build and start
cd "$OPENCLAW_DIR"
docker compose build
docker compose up -d

echo ""
echo "OpenClaw is running on 127.0.0.1:18789"
echo "Gateway token: $(cat $CONFIG_DIR/gateway-token.txt)"
echo ""
echo "YouTube MCP server is baked into the image at /opt/youtube-mcp/bin/youtube-studio-mcp"
echo "To configure: docker exec openclaw-openclaw-gateway-1 openclaw mcp set youtube '{\"command\": \"/opt/youtube-mcp/bin/youtube-studio-mcp\"}'"
echo "Credentials go in: $CONFIG_DIR/youtube-mcp/ (mounted at /home/node/.youtube-mcp)"
echo ""
echo "From your laptop, run:"
echo "  ssh -N -L 18789:127.0.0.1:18789 $USERNAME@<SERVER_IP>"
echo "Then open: http://localhost:18789"
