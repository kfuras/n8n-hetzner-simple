#!/bin/bash
set -e

SERVER_IP="$1"
DOMAIN="$2"
shift 2
SERVICES=("$@")

echo "Checking DNS propagation for $DOMAIN (checking subdomain records OR *.$DOMAIN wildcard)..."

MAX_ATTEMPTS=60
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  ALL_RESOLVED=true
  
  for service in "${SERVICES[@]}"; do
    FQDN="$service.$DOMAIN"
    RESOLVED_IP=$(dig +short "$FQDN" @1.1.1.1 2>/dev/null | head -n1)
    
    if [ "$RESOLVED_IP" != "$SERVER_IP" ]; then
      ALL_RESOLVED=false
      if [ $ATTEMPT -eq 0 ]; then
        echo "  Waiting for $FQDN → $SERVER_IP"
      fi
    fi
  done
  
  if [ "$ALL_RESOLVED" = true ]; then
    echo "DNS verified - all records point to $SERVER_IP"
    exit 0
  fi
  
  ATTEMPT=$((ATTEMPT + 1))
  
  if [ $ATTEMPT -lt $MAX_ATTEMPTS ]; then
    sleep 30
  else
    echo "Timeout: DNS not fully propagated. Continuing anyway..."
  fi
done

exit 0
