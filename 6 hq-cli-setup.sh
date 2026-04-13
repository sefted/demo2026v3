#!/bin/bash
set -e
source ./env.sh

# === Basic configuration ===
hostnamectl set-hostname hq-cli.au-team.irpo
timedatectl set-timezone "$TIMEZONE"

# === Network with VLAN 200 ===
mkdir -p /etc/net/ifaces/"$HQ_CLI_IF".200

cat > /etc/net/ifaces/"$HQ_CLI_IF"/options <<EOF
DISABLED=no
ONBOOT=yes
TYPE=eth
EOF

cat > /etc/net/ifaces/"$HQ_CLI_IF".200/options <<EOF
TYPE=vlan
BOOTPROTO=dhcp
ONBOOT=yes
DISABLED=no
VID=200
HOST=$HQ_CLI_IF
EOF

cat > /etc/net/ifaces/"$HQ_CLI_IF".200/resolv.conf <<EOF
nameserver 192.168.1.2
nameserver 8.8.8.8
EOF

systemctl restart network 2>/dev/null || systemctl restart networking 2>/dev/null || true
resolvconf -u 2>/dev/null || true

echo "[HQ-CLI] Configuration complete"
