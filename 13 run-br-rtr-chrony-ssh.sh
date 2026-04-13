#!/bin/bash
set -e
# Debian/Ubuntu - Identical to HQ-RTR, change AllowUsers if needed

echo "🔧 Configuring Chrony + SSH on BR-RTR..."

# === Chrony ===
apt-get update && apt-get install -y chrony
timedatectl set-ntp false 2>/dev/null || true

cp /etc/chrony/chrony.conf /etc/chrony/chrony.conf.bak 2>/dev/null || true
sed -i 's/^pool/#pool/' /etc/chrony/chrony.conf
sed -i 's/^rtcsync/#rtcsync/' /etc/chrony/chrony.conf

grep -q "server 172.16.1.1 iburst" /etc/chrony/chrony.conf || \
    echo "server 172.16.1.1 iburst" >> /etc/chrony/chrony.conf
grep -q "^makestep 1 -1" /etc/chrony/chrony.conf || \
    echo "makestep 1 -1" >> /etc/chrony/chrony.conf

systemctl enable --now chronyd

# === SSH ===
apt-get install -y openssh-server
systemctl daemon-reload

cat > /etc/ssh/sshd_config.d/20-custom.conf <<EOF
Port 2026
MaxAuthTries 2
PermitRootLogin no
AllowUsers net_admin
EOF

systemctl restart sshd

# === Crontab ===
cat > /root/fixafterreboot.sh <<'EOF'
#!/bin/bash
sleep 3
systemctl restart chronyd
systemctl restart sshd
EOF
chmod +x /root/fixafterreboot.sh
(crontab -l 2>/dev/null | grep -v "@reboot /root/fixafterreboot.sh"; echo "@reboot /root/fixafterreboot.sh") | crontab -

echo "✅ BR-RTR configured (Chrony + SSH)"
