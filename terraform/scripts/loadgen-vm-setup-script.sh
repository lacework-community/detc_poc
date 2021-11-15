#!/bin/bash

apt-get update
apt-get install nodejs npm unzip wget -y

mkdir /traffic-driver
cd /traffic-driver

wget -P /traffic-driver/ https://github.com/lacework-community/detc_poc/archive/refs/heads/main.zip
unzip /traffic-driver/main.zip

cd /traffic-driver/detc_poc-main/loadgen

npm install
chmod +x loadgen.js

echo '{"vote_app": "${VOTE_URL}"}' > vote_urls.json
echo '{"results_app": "${RESULT_URL}"}' > result_urls.json

cat > /etc/systemd/system/loadgen.service << 'EOFBASH'
[Unit]
Description=Loadgen web traffic driver

[Service]
PIDFile=/tmp/loadgen-99.pid
Restart=always
KillSignal=SIGQUIT
WorkingDirectory=/traffic-driver/detc_poc-main/loadgen
ExecStart=/usr/bin/node /traffic-driver/detc_poc-main/loadgen/loadgen.js

[Install]
WantedBy=multi-user.target
EOFBASH

sudo systemctl enable loadgen.service
sudo systemctl restart loadgen.service
