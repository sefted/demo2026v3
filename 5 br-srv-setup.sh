#!/bin/bash
set -e
source ./env.sh

# === Basic configuration ===
hostnamectl set-hostname br-srv.au-team.irpo
timedatectl set-timezone "$TIMEZONE"

# === Network ===
mkdir -p /etc/net/ifaces/"$BR_SRV_IF"
cat > /etc/net/ifaces/"$BR_SRV_IF"/options <<EOF
TYPE=eth
BOOTPROTO=static
ONBOOT=yes
DISABLED=no
EOF
echo "192.168.3.2/28" > /etc/net/ifaces/"$BR_SRV_IF"/ipv4address
echo "192.168.3.1" > /etc/net/ifaces/"$BR_SRV_IF"/ipv4route

# === DNS ===
sed -i 's/127.0.0.53//' /etc/resolvconf.conf 2>/dev/null || true
cat > /etc/net/ifaces/"$BR_SRV_IF"/resolv.conf <<EOF
nameserver 192.168.1.2
nameserver 8.8.8.8
EOF

systemctl disable --now systemd-resolved.service 2>/dev/null || true
rm -f /etc/resolv.conf
ln -s /etc/net/ifaces/"$BR_SRV_IF"/resolv.conf /etc/resolv.conf 2>/dev/null || true

systemctl restart network 2>/dev/null || systemctl restart networking 2>/dev/null || true
ip route add default via 192.168.3.1 2>/dev/null || true

# === User and SSH ===
useradd -m -u 2026 -s /bin/bash "$USER_SSH" 2>/dev/null || true
echo "$USER_SSH:$PASS" | chpasswd
echo "$USER_SSH ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER_SSH
chmod 440 /etc/sudoers.d/$USER_SSH
chmod 4755 /usr/bin/sudo 2>/dev/null || true

apt-get update && apt-get install -y openssh-server
cat >> /etc/ssh/sshd_config <<EOF
Port 2026
MaxAuthTries 2
PermitRootLogin no
Banner /etc/banner
AllowUsers $USER_SSH
EOF
echo "Authorized access only" > /etc/banner
systemctl restart sshd
systemctl enable --now sshd

# === Crontab for recovery ===
cat > /root/fixafterreboot.sh <<'EOF'
#!/bin/bash
sleep 3
systemctl restart network 2>/dev/null || systemctl restart networking 2>/dev/null || true
ip route add default via 192.168.3.1 2>/dev/null || true
resolvconf -u 2>/dev/null || true
docker restart db 2>/dev/null || true
docker restart testapp 2>/dev/null || true
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
EOF
chmod +x /root/fixafterreboot.sh
echo "@reboot /root/fixafterreboot.sh" | crontab -

echo "[BR-SRV] Configuration complete"
