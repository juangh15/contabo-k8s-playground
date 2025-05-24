sudo apt install onedrive -y

mkdir -p ~/registry-data

sudo docker run -d \
  --name registry-server \
  -p 5000:5000 \
  -v ~/OneDrive/docker-registry:/var/lib/registry \
  registry:2

sudo docker rm -f registry-server

sudo docker pull alpine
sudo docker tag alpine localhost:5000/alpine
sudo docker push localhost:5000/alpine


onedrive

run login url on a GUI pc
login with onedrive creds
authorize
get the response uri

mkdir -p ~/OneDrive/docker-registry

mkdir -p $(dirname ~/.config/onedrive/config)

cat << 'EOF' > ~/.config/onedrive/config
sync_dir = "~/OneDrive"
EOF

cat ~/.config/onedrive/config

onedrive --synchronize --single-directory docker-registry