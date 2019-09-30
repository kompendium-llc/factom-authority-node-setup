# Factom Authority Node Setup

A set of scripts for partially automating the setup of an authority node on a fresh server.

## 1) Initial Setup

*Skip this if you already have ssh and a non-root user setup.*

Adds a user and their ssh key, hardens the server with fail2ban and sshd_config changes. Will need to log out and log back in after this script.

## 2) Docker install

Installs docker and factom binaries.

## 3) Factomd install
Requests current dockerhub images and asks which on to install. Downloads certs and updates firewall policies for docker swarm and factomd. Adds docker as a systemd service,

**Modify swarm_host and expiry variables if needed**

## 4) Server Identiy
Starts factom-walletd. Clones, builds then runs serveridentity and fullidentity programs. Backs up then updates factomd.conf with the server identity data. Restarts factomd container.
