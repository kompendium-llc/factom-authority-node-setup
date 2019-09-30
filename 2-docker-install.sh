#!/bin/bash

# Exit on error
set -e

# First up
apt update

# Dependencies 
apt -y install apt-transport-https \
				ca-certificates \
				curl \
				gnupg-agent \
				software-properties-common \
				git \
				golang-go \
				golang-glide

# Install factom-walletd and factom-cli
wget https://github.com/FactomProject/distribution/releases/download/v6.1.0/factom-amd64.deb
dpkg -i factom-amd64.deb
rm factom-amd64.deb

# Docker key
echo "Checking docker gpg key validity..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -


# Add repo for ubuntu
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt update


#Install Docker
apt install -y docker-ce docker-ce-cli containerd.io


# Add user to Docker group
# For root user variable should be $USER
# For regular user running script with sudo it should be $SUDO_USER
usermod -aG docker $SUDO_USER

echo "Log out to recalculate group permissions and continue"