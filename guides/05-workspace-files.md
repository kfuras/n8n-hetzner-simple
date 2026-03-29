# Workspace Files

These files define your agent's personality and behavior. Edit them in the Control UI under Core Files, or on the server at `~/.openclaw/workspace/`.

## SOUL.md

Defines the agent's personality, tone, and boundaries. Example:

```markdown
# Identity
You are [Name]'s AI assistant.

# Tone
- Direct and helpful
- Concise responses
- Professional but friendly

# Hard Limits
- Never share private information
- Always ask before taking actions that cost money
- Never post publicly without approval
```

## USER.md

Tells the agent who you are so it can personalize responses:

```markdown
# Who I Am
- Name: [Your Name]
- Business: [Your Business]
- Goals: [What you're trying to achieve]
```

## Editing

**Via Control UI:**
1. Open http://localhost:18789 (with SSH tunnel running)
2. Navigate to workspace files
3. Edit and save

**Via SSH:**
```bash
ssh amam@YOUR_SERVER_IP
nano ~/.openclaw/workspace/SOUL.md
```

Changes take effect on the next conversation — no restart needed.
