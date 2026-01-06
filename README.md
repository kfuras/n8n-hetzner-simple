# N8N Production Platform on Hetzner Cloud

[![OpenTofu](https://img.shields.io/badge/OpenTofu-FFDA18?style=for-the-badge&logo=opentofu&logoColor=black)](https://opentofu.org/docs/)
[![Hetzner](https://img.shields.io/badge/Hetzner-D50C2D?style=for-the-badge&logo=hetzner&logoColor=white)](https://console.hetzner.com/)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docs.docker.com/)
[![N8N](https://img.shields.io/badge/n8n-EA4B71?style=for-the-badge&logo=n8n&logoColor=white)](https://n8n.io/)
[![Skool Community](https://img.shields.io/badge/Skool-Build_&_Automate-FF6154?style=for-the-badge)](https://www.skool.com/build-automate)

Deploy a complete N8N automation platform with optional companion services on Hetzner Cloud. Fully automated deployment with SSL certificates, security hardening, and modular architecture.

## What Gets Created

- **N8N** - Workflow automation platform with PostgreSQL database
- **Traefik** - Automatic SSL certificates via Let's Encrypt
- **Optional Services** - BaseRow, NocoDB, MinIO, Kokoro TTS, NCA Toolkit, Postiz
- **Ubuntu 24.04 server** with Docker and security hardening
- **Firewall** with SSH restricted to your IP, HTTP/HTTPS open
- **fail2ban** protecting against brute-force attacks

All services automatically configured with your domain and secured behind Traefik with SSL certificates.

## Prerequisites

1. **Hetzner Cloud Account** and API token with **Read & Write** permissions ([console.hetzner.cloud](https://console.hetzner.com/) → Security → API Tokens)
2. **OpenTofu** installed:
   - macOS: `brew install opentofu`
   - Windows: `winget install --exact --id=OpenTofu.Tofu`
   - Linux: [opentofu.org/docs/intro/install](https://opentofu.org/docs/intro/install)
3. **GitHub Personal Access Token** with read access to your private repo
4. **SSH key pair** for server access
5. **Domain name** with access to DNS settings

### Creating an SSH Key Pair

```bash
ssh-keygen -t ed25519 -C "n8n-server" -f ~/.ssh/id_ed25519_n8n_dev
```

Creates:
- `~/.ssh/id_ed25519_n8n_dev` - Private key (keep secret)
- `~/.ssh/id_ed25519_n8n_dev.pub` - Public key (use in tfvars)

## Quick Start

1. **Clone this repository**
   ```bash
   git clone https://github.com/build-automate/n8n-hetzner-simple.git
   cd n8n-hetzner-simple
   ```

2. **Configure**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
   
   Edit `terraform.tfvars`:
   ```terraform
   hcloud_token = "your-hetzner-api-token"
   ssh_key_path = "~/.ssh/id_ed25519_n8n_dev.pub"
   home_ip      = "your.ip.address/32"  # Get with: curl ifconfig.co
   server_name  = "n8n-server-1"
   username     = "yourname"
   
   github_org   = "build-automate"
   github_repo  = "n8n-production-platform"
   github_pat   = "github_pat_xxxxx"
   
   domain       = "yourdomain.com"
   
   services = {
     baserow = {
       enabled = false
       secrets = ["SECRET_KEY", "DATABASE_PASSWORD", "REDIS_PASSWORD"]
     }
     # ... enable other services as needed (all default to false)
   }
   ```

3. **Deploy**
   ```bash
   tofu init
   tofu plan
   tofu apply
   ```

4. **Configure DNS**
   
   While deployment runs, add DNS records pointing to the server IP (shown in output):
   ```
   A    n8n        -> <server-ip>
   A    webhook    -> <server-ip>
   A    baserow    -> <server-ip>
   ```
   
   Or use wildcard: `A  *.yourdomain.com -> <server-ip>`

5. **Access N8N**
   
   Open `https://n8n.yourdomain.com` after DNS propagates (~2-5 minutes)

## Service URLs

- **N8N**: `https://n8n.yourdomain.com`
- **N8N Webhooks**: `https://webhook.yourdomain.com`
- **BaseRow**: `https://baserow.yourdomain.com`
- **NocoDB**: `https://nocodb.yourdomain.com`
- **MinIO Console**: `https://minio-console.yourdomain.com`

All services get automatic SSL certificates from Let's Encrypt.

## Configuration

### Server Sizing

Default: `cx33` (4 vCPU, 8GB RAM, ~$5.99/month)

**Recommended:**
- `cx23` - 2 vCPU, 4GB RAM (~$3.49/month) - N8N only
- `cx33` - 4 vCPU, 8GB RAM (~$5.99/month) - N8N + 1-2 services
- `cx43` - 8 vCPU, 16GB RAM (~$9.99/month) - N8N + 3-5 services
- `cx53` - 16 vCPU, 32GB RAM (~$18.99/month) - Full stack

### Locations

- `hel1` - Helsinki, Finland (EU, default)
- `nbg1` - Nuremberg, Germany (EU)
- `fsn1` - Falkenstein, Germany (EU)
- `ash` - Ashburn, USA (East Coast)

### Enabling/Disabling Services

All optional services default to disabled. To enable, edit `terraform.tfvars`:

```terraform
services = {
  baserow = {
    enabled = true  # Change to false to disable
    secrets = ["SECRET_KEY", "DATABASE_PASSWORD", "REDIS_PASSWORD"]
  }
}
```

Run `tofu apply` to apply changes.

## Security Features

- **Network**: SSH restricted to your IP, fail2ban protection
- **SSH**: Root login disabled, key-only authentication
- **Secrets**: Auto-generated on server using `openssl rand`, never in Terraform state
- **Docker**: Log rotation configured (10MB max, 3 files)

## Useful Commands

```bash
# Get server info
tofu output public_ipv4
tofu output dns_records_needed

# SSH to server
ssh -i ~/.ssh/id_ed25519_n8n_dev username@server-ip

# Check services
ssh user@server "docker compose -f ~/stack/docker-compose.yml ps"

# View logs
ssh user@server "docker compose -f ~/stack/docker-compose.yml logs -f n8n"

# Restart services
ssh user@server "docker compose -f ~/stack/docker-compose.yml restart"

# Destroy everything
tofu destroy
```

## Troubleshooting

**DNS not propagating:**
```bash
dig @1.1.1.1 n8n.yourdomain.com +short
```
Should return your server IP. Takes 1-5 minutes typically.

**SSL certificate issues:**
```bash
ssh user@server "docker compose -f ~/stack/docker-compose.yml logs traefik | grep acme"
```

**Can't access services:**
- Check DNS points to server IP
- Wait for SSL certificates (1-2 minutes after DNS propagates)
- Verify firewall allows HTTP/HTTPS: `curl -I http://server-ip`

## Cost Estimate

**Minimal** (N8N only, cx23): ~$3.49/month  
**Standard** (N8N + 2 services, cx33): ~$5.99/month  
**Full Stack** (All services, cx53): ~$18.99/month

Includes 20TB traffic. Add ~20% for backups if enabled.

## Support

Questions? Join the [Build & Automate community](https://www.skool.com/build-automate) on Skool.

## License

Provided as-is for use with your own infrastructure.
