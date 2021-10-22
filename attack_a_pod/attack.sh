wget https://github.com/xmrig/xmrig/releases/download/v6.15.0/xmrig-6.15.0-linux-static-x64.tar.gz
tar -xvf xmrig-6.15.0-linux-static-x64.tar.gz
cd xmrig-6.15.0
chmod +x xmrig
(sleep 60; (ps -ef | grep xmrig | grep -v grep | awk '{print $2}' | xargs kill -9)) &
./xmrig