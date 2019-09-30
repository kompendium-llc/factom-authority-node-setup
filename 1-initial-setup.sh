#!/bin/bash

# Prompts for non-root user
read -p "Enter new user name: " username
read -p "Please enter users public ssh key (no newlines): " ssh_key
read -p "Choose non-standard ssh port: " ssh_port

# Update and install fail2ban
echo "Updating.."
apt update
apt -y upgrade
apt install -y fail2ban unattended-upgrades


# Setup non-root user
echo "Adding User.."
adduser $username
usermod -aG sudo $username

# Add ssh key
echo "Setting up ssh key.."
mkdir /home/$username/.ssh &&
chmod 700 /home/$username/.ssh &&
echo  $ssh_key >> /home/$username/.ssh/authorized_keys &&
chmod 600 /home/$username/.ssh/authorized_keys &&
chown $username:$username -R /home/$username/.ssh/ 

# Backup sshd_config
echo "Backing up and modifying sshd_config..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

#Modify sshd params
sed -i "s/#Port 22/Port $ssh_port/" /etc/ssh/sshd_config
sed -i '/PubkeyAuthentication/c\PubkeyAuthentication yes' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i '/AuthorizedKeysFile/c\AuthorizedKeysFile %h/.ssh/authorized_keys' /etc/ssh/sshd_config
sed -i '0,/PermitRootLogin/s/.*PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config

echo "Restarting SSH..."
service ssh restart

echo "
#### Please login with username $username on port $ssh_port using the key provided before logging out of this session to confirm. ####
"