#!/bin/bash
set -e

USERNAME="$1"
DOMAIN="$2"
HOME_IP="$3"
SERVICES_JSON="$4"

echo "Waiting for Docker and repo to be ready..."
while ! docker ps >/dev/null 2>&1 || [ ! -f "/home/$USERNAME/stack/secrets/production.env.example" ]; do
  sleep 2
done
echo "System ready"

# Only generate secrets if .env doesn't exist
if [ ! -f /home/$USERNAME/stack/.env ]; then
  cp /home/$USERNAME/stack/secrets/production.env.example /home/$USERNAME/stack/.env
  chmod 600 /home/$USERNAME/stack/.env
  
  # Remove example warning since all secrets are auto-generated
  sed -i '/# The below is for example purposes only/d' /home/$USERNAME/stack/.env
  
  sed -i "s|DOMAIN=yourdomain.com|DOMAIN=$DOMAIN|g" /home/$USERNAME/stack/.env
  sed -i "s|HOME_IP=192.168.1.100|HOME_IP=$HOME_IP|g" /home/$USERNAME/stack/.env
  
  # Core N8N secrets
  sed -i "s|N8N_ENCRYPTION_KEY=.*|N8N_ENCRYPTION_KEY=$(openssl rand -base64 24 | tr -d '/+=')|g" /home/$USERNAME/stack/.env
  sed -i "s|N8N_USER_MANAGEMENT_JWT_SECRET=.*|N8N_USER_MANAGEMENT_JWT_SECRET=$(openssl rand -base64 24 | tr -d '/+=')|g" /home/$USERNAME/stack/.env
  sed -i "s|N8N_BASIC_AUTH_PASSWORD=.*|N8N_BASIC_AUTH_PASSWORD=$(openssl rand -base64 18 | tr -d '/+=')|g" /home/$USERNAME/stack/.env
  sed -i "s|POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$(openssl rand -base64 24 | tr -d '/+=')|g" /home/$USERNAME/stack/.env
  
  # Generate ALL service secrets upfront (regardless of enabled status)
  # This ensures secure passwords even if services are enabled later
  echo "$SERVICES_JSON" | jq -r '.[] | .secrets[] | @text' | sort -u | while read secret; do
    sed -i "s|${secret}=.*|${secret}=$(openssl rand -base64 24 | tr -d '/+=')|g" /home/$USERNAME/stack/.env
  done
  
  echo "Secrets generated!"
else
  echo ".env already exists - preserving secrets"
  sed -i "s|DOMAIN=.*|DOMAIN=$DOMAIN|g" /home/$USERNAME/stack/.env
  sed -i "s|HOME_IP=.*|HOME_IP=$HOME_IP|g" /home/$USERNAME/stack/.env
fi

# Toggle services
echo "$SERVICES_JSON" | jq -r 'to_entries[] | "\(.key) \(.value.enabled)"' | while read name enabled; do
  if [ "$enabled" = "true" ]; then
    sed -i "s|^#  - docker-compose.${name}.yml|  - docker-compose.${name}.yml|" /home/$USERNAME/stack/docker-compose.yml
  else
    sed -i "s|^  - docker-compose.${name}.yml|#  - docker-compose.${name}.yml|" /home/$USERNAME/stack/docker-compose.yml
  fi
done

# Copy service env files
echo "$SERVICES_JSON" | jq -r 'to_entries[] | select(.value.enabled) | .key' | while read name; do
  if [ -f /home/$USERNAME/stack/${name}.env.example ] && [ ! -f /home/$USERNAME/stack/${name}.env ]; then
    cp /home/$USERNAME/stack/${name}.env.example /home/$USERNAME/stack/${name}.env
    chmod 600 /home/$USERNAME/stack/${name}.env
    sed -i "s|yourdomain.com|$DOMAIN|g" /home/$USERNAME/stack/${name}.env
  fi
done

cd /home/$USERNAME/stack && docker compose up -d --quiet-pull --remove-orphans
