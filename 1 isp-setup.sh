#!/bin/bash
set -e
source ./env.sh

# === Disable APT checks ===
mkdir -p /etc/apt/apt.conf.d
cat > /etc/apt/apt.conf.d/99-disable-checking <<'EOF'
Acquire::Check-Valid-Until "false";
Acquire::AllowInsecureRepositories "true";
Acquire::AllowDowngradeToInsecureRepositories "true";
Acquire::https::Verify-Peer "false";
Acquire::https::Verify-Host "false";
EOF

# === Basic configuration ===
hostnamectl set-hostname isp.au-team.irpo
timedatectl set-timezone "$TIMEZONE"

# === Network interfaces ===
cat > /etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

# WAN
auto $ISP_IF_WAN
iface $ISP_IF_WAN inet dhcp

# LAN BR
auto $ISP_IF_BR
iface $ISP_IF_BR inet static
    address 172.16.2.1/28

# LAN HQ
auto $ISP_IF_HQ
iface $ISP_IF_HQ inet static
    address 172.16.1.1/28
EOF

# === Enable IP forwarding and NAT ===
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

iptables -t nat -A POSTROUTING -o "$ISP_IF_WAN" -j MASQUERADE
mkdir -p /etc/iptables
iptables-save > /etc/iptables.rules

# === Restart network ===
systemctl restart networking || true
dhclient "$ISP_IF_WAN" 2>/dev/null || true

# === Create user ===
useradd -m -s /bin/bash "$USER_ADMIN" 2>/dev/null || true
echo "$USER_ADMIN ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USER_ADMIN
chmod 440 /etc/sudoers.d/$USER_ADMIN

echo "[ISP] Configuration complete"
