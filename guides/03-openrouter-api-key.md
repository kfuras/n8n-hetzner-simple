# OpenRouter API Key

OpenClaw uses OpenRouter to access AI models (DeepSeek, Claude, etc.).

## Get Your API Key

1. Go to https://openrouter.ai
2. Create an account
3. Go to **Keys** → **Create Key**
4. Copy the key (starts with `sk-or-`)

## Add to OpenClaw

SSH into your server:

```bash
ssh amam@YOUR_SERVER_IP
nano ~/openclaw/.env
```

Add or update the line:

```
OPENROUTER_API_KEY=sk-or-your-key-here
```

Restart:

```bash
cd ~/openclaw && docker compose restart
```

## Cost

The default model is DeepSeek V3.2:
- ~$0.001 per message (less than a tenth of a cent)
- 50 messages/day ≈ $1.50/month
- 100 messages/day ≈ $3/month

Add credits at https://openrouter.ai/credits. Start with $5 — it lasts a long time with DeepSeek.
