# Upload SSH keys
resource "hcloud_ssh_key" "main" {
  name       = "${var.server_name}-main-key"
  public_key = file(var.ssh_key_path)
}

resource "hcloud_ssh_key" "extra" {
  count      = length(var.extra_ssh_keys)
  name       = "${var.server_name}-${element(split(" ", var.extra_ssh_keys[count.index]), 2)}-key"
  public_key = var.extra_ssh_keys[count.index]
}

# Firewall rules
resource "hcloud_firewall" "main" {
  name = "${var.server_name}-firewall"

  rule {
    description = "Allow SSH from Home IP"
    direction   = "in"
    port        = "22"
    protocol    = "tcp"
    source_ips  = [var.home_ip]
  }

  rule {
    description = "Allow HTTP"
    direction   = "in"
    port        = "80"
    protocol    = "tcp"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }

  rule {
    description = "Allow HTTPS"
    direction   = "in"
    port        = "443"
    protocol    = "tcp"
    source_ips  = ["0.0.0.0/0", "::/0"]
  }
}

# Generate cloud-init script
locals {
  cloud_init_content = templatefile("${path.module}/cloud-init.yaml", {
    username        = var.username
    ssh_public_keys = concat([file(var.ssh_key_path)], var.extra_ssh_keys)
    github_org      = var.github_org
    github_repo     = var.github_repo
    github_pat      = var.github_pat
  })

  # Build sed commands: uncomment enabled services, comment disabled ones
  service_commands = [
    for name, config in var.services :
    config.enabled
    ? "sed -i 's|^#  - docker-compose.${name}.yml|  - docker-compose.${name}.yml|' /home/${var.username}/stack/docker-compose.yml"
    : "sed -i 's|^  - docker-compose.${name}.yml|#  - docker-compose.${name}.yml|' /home/${var.username}/stack/docker-compose.yml"
  ]

  # Build secret generation commands for all services
  secret_commands = flatten([
    for name, config in var.services : [
      for secret in config.secrets :
      "sed -i 's|${secret}=.*|${secret}='$(openssl rand -base64 24 | tr -d '/+=')'|g' /home/${var.username}/stack/.env"
    ]
  ])

  # Copy service-specific env files from examples (only for enabled services)
  service_env_commands = flatten([
    for name, config in var.services : config.enabled ? [
      "if [ -f /home/${var.username}/stack/${name}.env.example ]; then if [ ! -f /home/${var.username}/stack/${name}.env ]; then cp /home/${var.username}/stack/${name}.env.example /home/${var.username}/stack/${name}.env && chmod 600 /home/${var.username}/stack/${name}.env && sed -i 's|yourdomain.com|${var.domain}|g' /home/${var.username}/stack/${name}.env; fi; fi"
    ] : []
  ])
}

# Create server
resource "hcloud_server" "main" {
  name        = var.server_name
  image       = var.image
  server_type = var.server_type
  location    = var.location
  ssh_keys    = concat([hcloud_ssh_key.main.id], hcloud_ssh_key.extra[*].id)
  backups     = var.enable_backups
  user_data   = local.cloud_init_content

  labels = {
    environment = "development"
    managed_by  = "opentofu"
  }

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
}

# Attach firewall
resource "hcloud_firewall_attachment" "main" {
  count       = var.enable_firewall ? 1 : 0
  firewall_id = hcloud_firewall.main.id
  server_ids  = [hcloud_server.main.id]
}

# Wait for DNS to propagate before starting services
resource "null_resource" "wait_for_dns" {
  count      = var.wait_for_dns ? 1 : 0
  depends_on = [hcloud_server.main]

  triggers = {
    server_id = hcloud_server.main.id
    domain    = var.domain
    home_ip   = var.home_ip
    services  = jsonencode(var.services)
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/check-dns.sh '${hcloud_server.main.ipv4_address}' '${var.domain}' n8n ${join(" ", [for name, config in var.services : name if config.enabled])}"
  }
}

# Wait for repo to be cloned and Docker ready, then configure
resource "null_resource" "copy_env_file" {
  depends_on = [
    hcloud_server.main,
    null_resource.wait_for_dns
  ]

  # Re-run provisioner when any of these values change
  triggers = {
    server_id = hcloud_server.main.id
    domain    = var.domain
    home_ip   = var.home_ip
    services  = jsonencode(var.services)
  }

  provisioner "file" {
    source      = "${path.module}/configure-services.sh"
    destination = "/tmp/configure-services.sh"

    connection {
      type        = "ssh"
      user        = var.username
      private_key = file(replace(var.ssh_key_path, ".pub", ""))
      host        = hcloud_server.main.ipv4_address
      timeout     = "15m"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/configure-services.sh",
      "/tmp/configure-services.sh '${var.username}' '${var.domain}' '${replace(var.home_ip, "/32", "")}' '${jsonencode(var.services)}'"
    ]

    connection {
      type        = "ssh"
      user        = var.username
      private_key = file(replace(var.ssh_key_path, ".pub", ""))
      host        = hcloud_server.main.ipv4_address
      timeout     = "5m"
    }
  }
}

# Copy postiz env file to server (conditional)
resource "null_resource" "copy_postiz_env_file" {
  count      = var.services.postiz.enabled ? 1 : 0
  depends_on = [null_resource.copy_env_file]

  provisioner "remote-exec" {
    inline = [
      "cp /home/${var.username}/stack/postiz.env.example /home/${var.username}/stack/postiz.env",
      "chmod 600 /home/${var.username}/stack/postiz.env",
      "sed -i 's|yourdomain.com|${var.domain}|g' /home/${var.username}/stack/postiz.env",
      "cd /home/${var.username}/stack && docker compose up -d"
    ]

    connection {
      type        = "ssh"
      user        = var.username
      private_key = file(replace(var.ssh_key_path, ".pub", ""))
      host        = hcloud_server.main.ipv4_address
      timeout     = "5m"
    }
  }
}