chmod +x certbot/init.sh

echo '''
DOMAIN=yourdomain.com
EMAIL=youremail@example.com
''' > ./.env

docker run -d \
  --name holaweb \
  -p 8080:80 \
  nginx:alpine


git clone https://github.com/juangh15/contabo-k8s-playground.git
cd ./contabo-k8s-playground
git checkout fb-k8s-6
cd ./setup_loadbalancer


# 1.
docker network create --driver bridge internal

# 2.
docker compose -f compose-test.yml up -d

# 3.
docker compose -f compose-main.yml up -d


# 4.

docker run --rm \
  --env-file .env \
  --entrypoint sh \
  -v "$PWD/certbot/www:/var/www/certbot" \
  -v "$PWD/certbot/conf:/etc/letsencrypt" \
  certbot/certbot:latest \
  -c 'certbot certonly --webroot --webroot-path /var/www/certbot/ \
  -d "$DOMAIN" \
  --email "$EMAIL" \
  --agree-tos \
  --non-interactive'

# 5.

docker compose -f compose-main.yml up -d --force-recreate nginx




docker compose -f compose-main.yml down