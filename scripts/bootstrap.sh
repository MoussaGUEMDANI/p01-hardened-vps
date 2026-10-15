#!/usr/bin/env bash

# bootstrap.sh - harden a fresh Ubuntu 24.04 server from this repo.
# Usage: sudo ./bootstrap.sh <repo-dir>
set -euo pipefail

REPO_DIR="${1:?usage: bootstrap.sh <repo-dir>}"
ADMIN_USER="deploy"
log() { printf '\n==> %s\n' "$*"; }

[[ $EUID -eq 0 ]] || { echo "Run as root (sudo)." >&2; exit 1; }

log "Packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get full-upgrade -yq
apt-get install -yq ufw fail2ban unattended-upgrades

log "Add user $ADMIN_USER" 
id "$ADMIN_USER" &>/dev/null || adduser --disabled-password --gecos "" "$ADMIN_USER"
usermod -aG sudo "$ADMIN_USER"
echo "$ADMIN_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/90-$ADMIN_USER"
chmod 440 "/etc/sudoers.d/90-$ADMIN_USER"
visudo -cq
install -d -m 700 -o "$ADMIN_USER" -g "$ADMIN_USER" "/home/$ADMIN_USER/.ssh"
install -m 600 -o "$ADMIN_USER" -g "$ADMIN_USER" \
    "$REPO_DIR/configs/keys/deploy.pub" "/home/$ADMIN_USER/.ssh/authorized_keys"

log "SSH hardening"
install -m 644 "$REPO_DIR/configs/sshd/01-hardening.conf" /etc/ssh/sshd_config.d/
mkdir -p /run/sshd            # needed for 'sshd -t' when ssh is socket-activated
sshd -t
systemctl restart ssh

log "Firewall"
ufw default deny incoming
ufw default allow outgoing
ufw limit OpenSSH
ufw --force enable

log "fail2ban"
install -m 644 "$REPO_DIR/configs/fail2ban/sshd.local" /etc/fail2ban/jail.d/
systemctl enable fail2ban
systemctl restart fail2ban

log "Automatic updates"
install -m 644 "$REPO_DIR/configs/apt/20auto-upgrades" \
               "$REPO_DIR/configs/apt/52unattended-upgrades-local" /etc/apt/apt.conf.d/

log "Done — log in with: ssh $ADMIN_USER@<server-ip>"