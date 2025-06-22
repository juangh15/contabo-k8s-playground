#!/bin/sh

# Usa las variables pasadas por Docker
echo "Using domain: $DOMAIN"
echo "Using email: $EMAIL"

# Espera a que nginx esté listo (opcional pero útil)
sleep 10

# Certbot en modo standalone
certbot certonly --standalone --non-interactive --agree-tos \
  -m "$EMAIL" -d "$DOMAIN"
