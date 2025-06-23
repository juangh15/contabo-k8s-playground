#!/bin/sh

echo "Using domain: $DOMAIN"
echo "Using email: $EMAIL"

# Wait for 80
while lsof -i :80 >/dev/null 2>&1; do
  echo "Waiting for 80..."
  sleep 2
done

# Use --staging for tests)
certbot certonly --standalone --non-interactive --agree-tos --staging \
  --preferred-challenges http \
  --http-01-port 80 \
  --email "$EMAIL" -d "$DOMAIN" || exit 1

# Mark certs are ready
touch /certs/.ready
