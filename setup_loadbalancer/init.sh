#!/bin/sh

echo "Using domain: $DOMAIN"
echo "Using email: $EMAIL"

# Use --staging for tests)
certbot certonly --standalone --non-interactive --agree-tos --staging \
  --preferred-challenges http \
  --http-01-port 80 \
  --email "$EMAIL" -d "$DOMAIN" || exit 1

# Mark certs are ready
touch /certs/.ready
