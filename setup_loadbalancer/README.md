chmod +x certbot/init.sh

echo '''
DOMAIN=yourdomain.com
EMAIL=youremail@example.com
''' > ./.env

docker run -d \
  --name holaweb \
  -p 8080:80 \
  nginx:alpine
