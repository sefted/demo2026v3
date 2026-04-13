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
hostnamectl set-hostname br-rtr.au-team.irpo
timedatectl set-timezone "$TIMEZONE"

# === Network interfaces ===
cat > /etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

auto $BR_IF_WAN
iface $BR_IF_WAN inet static
    address 172.16.2.2/28
    gateway 172.16.2.1

auto $BR_IF_LAN
iface $BR_IF_LAN inet static
    address 192.168.3.1/28
EOF

# === IP forwarding and NAT ===
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

iptables -t nat -A POSTROUTING -o "$BR_IF_WAN" -j MASQUERADE
iptables-save > /etc/iptables.rules

systemctl restart networking || true

# === Create user ===
useradd -m -s /bin/bash "$USER_ADMIN" 2>/dev/null || true
echo "$USER_ADMIN:$PASS" | chpasswd
echo "$USER_ADMIN ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER_ADMIN
chmod 440 /etc/sudoers.d/$USER_ADMIN

# === Crontab for recovery ===
cat > /root/fixafterreboot.sh <<'EOF'
#!/bin/bash
sleep 3
iptables-restore < /etc/iptables.rules
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
EOF
chmod +x /root/fixafterreboot.sh
echo "@reboot /root/fixafterreboot.sh" | crontab -

echo "[BR-RTR] Configuration complete"
