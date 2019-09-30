#!/bin/bash

# Ensure factomd is running
docker start factomd

# Install factom-cli and factom-walletd
wget https://github.com/FactomProject/distribution/releases/download/v6.1.0/factom-amd64.deb
dpkg -i factom-amd64.deb
rm factom-amd64

# Open factom-walletd in subshell
exec factom-walletd

# Generate new entry credit address
factom-cli newecaddress

# Set environmental variables
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH
printf "export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
" >> ~/.profile

# Compile serveridentity
mkdir -p $GOPATH/src/github.com/FactomProject/
cd $GOPATH/src/github.com/FactomProject/
git clone https://github.com/FactomProject/serveridentity.git
cd serveridentity 
glide install
go install
cd signwithed25519
go install

# Get private key for entry credit address
ec_secret=$(factom-cli exportaddresses | cut -d' ' -f1)

# Run serveridentity program
cd $GOPATH/bin
./serveridentity full elements $ec_secret -f

# Remove private key variable
unset ec_secret

# Run fullidentity bash script
chmod +x fullidentity.sh
./fullidentity.sh

# Backup factomd.conf
config_path="/var/lib/docker/volumes/factom_keys/_data/factomd.conf"
cp $config_path $config_path.bak

# Replace identity information in config file
head -n -2 $config_path > $config_path
sed 1d fullidentity.conf >> $config_path

# Restart factomd
docker stop factomd
docker start factomd

