# Getting Started

## Access the Control UI

From your laptop, open a terminal and run:

```bash
ssh -N -L 18789:127.0.0.1:18789 amam@YOUR_SERVER_IP
```

Keep this running. Then open: http://localhost:18789

Enter your gateway token when prompted. To find it:

```bash
ssh amam@YOUR_SERVER_IP
cat ~/.openclaw/gateway-token.txt
```

## What You'll See

The Control UI shows:
- Active channels (Discord)
- Agent status
- Session history
- Workspace files (SOUL.md, USER.md, etc.)

## Test Your Agent

Send a DM to your Discord bot. It should respond. If it asks for a pairing code, approve it in the Control UI or run:

```bash
ssh amam@YOUR_SERVER_IP
docker exec openclaw-openclaw-gateway-1 openclaw pairing approve discord CODE
```
