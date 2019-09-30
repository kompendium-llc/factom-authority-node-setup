#!/bin/bash
set -e
set -v

swarm_host='18.203.51.247'
expiry='exp_5-14-21.pem'

echo "Please specify required version"
echo "Latest releases here: https://hub.docker.com/r/factominc/factomd/tags"
read -p "Factom docker version (eg v6.2.2-alpine): " version



# Set iptables
iptables -A INPUT -s $swarm_host/32 -p tcp -m tcp --dport 2376 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -P INPUT DROP
iptables -I DOCKER-USER ! -s $swarm_host/32  -i eth0 -p tcp -m tcp --dport 8090 -j REJECT 
iptables -I DOCKER-USER ! -s $swarm_host/32  -i eth0 -p tcp -m tcp --dport 2222 -j REJECT 
iptables -I DOCKER-USER ! -s $swarm_host/32  -i eth0 -p tcp -m tcp --dport 8088 -j REJECT 

# Set Firewall persistence
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
apt -y install iptables-persistent


# Docker Swarm Keys
mkdir -p /etc/docker
wget https://raw.githubusercontent.com/FactomProject/factomd-authority-toolkit/master/tls/cert_exp_5-14-21.pem -O /etc/docker/factom-mainnet-cert.pem
wget https://raw.githubusercontent.com/FactomProject/factomd-authority-toolkit/master/tls/key_exp_5-14-21.pem -O /etc/docker/factom-mainnet-key.pem
wget https://raw.githubusercontent.com/FactomProject/factomd-authority-toolkit/master/tls/ca_exp_5-14-21.pem -O /etc/docker/factom-mainnet-ca.pem
chmod 644 /etc/docker/factom-mainnet-cert.pem
chmod 440 /etc/docker/factom-mainnet-key.pem
chgrp docker /etc/docker/*.pem


# Configure Docker
printf '{
  "tls": true,
  "tlscert": "/etc/docker/factom-mainnet-cert.pem",
  "tlskey": "/etc/docker/factom-mainnet-key.pem",
  "tlscacert": "/etc/docker/factom-mainnet-ca.pem",
  "hosts": ["tcp://0.0.0.0:2376", "unix:///var/run/docker.sock"]
}' >> /etc/docker/daemon.json

mkdir /etc/systemd/system/docker.service.d

printf "[Service]
ExecStart=
ExecStart=/usr/bin/dockerd
" > /etc/systemd/system/docker.service.d/override.conf


# Restart and check daemon is running
systemctl daemon-reload
sleep 2
systemctl restart docker
sleep 2
systemctl status dockerdocker

# Docker Volumes
docker volume create factom_database
docker volume create factom_keys

# Join Swarm
docker swarm join --token SWMTKN-1-5ct5plmbn1ombbjqp8ql8hq93jkof6246suzast5n1gfwa083b-1ui6w6fupe45tizz0tv6syzrs $swarm_host:2377


# Start testnet factomd
docker run -d --name "factomd" \
			-v "factom_database:/root/.factom/m2" \
			-v "factom_keys:/root/.factom/private" \
			--restart unless-stopped \
			-p "8088:8088" \
			-p "8090:8090" \
			-p "8108:8108" \
			-l "name=factomd" \
			factominc/factomd:$version \
			-startdelay=600 \
			-faulttimeout=120 \
			-config=/root/.factom/private/factomd.conf
			