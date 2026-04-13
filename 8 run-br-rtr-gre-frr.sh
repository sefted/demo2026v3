#!/bin/bash
set -e
source ./env.sh 2>/dev/null || true

echo "🔧 Configuring BR-RTR: GRE + FRR..."

# === GRE tunnel ===
if ! grep -q "iface gre1" /etc/network/interfaces; then
cat >> /etc/network/interfaces <<EOF

auto gre1
iface gre1 inet static
    address 10.10.10.2
    netmask 255.255.255.252
    pre-up ip tunnel add gre1 mode gre remote 172.16.1.2 local 172.16.2.2 ttl 255 || true
    up ip link set gre1 up
    post-down ip tunnel del gre1 || true
EOF
fi

ifup gre1 2>/dev/null || ip link set gre1 up 2>/dev/null || true

# === FRR (routing) ===
if ! command -v vtysh &>/dev/null; then
    echo "deb https://deb.frrouting.org/frr $(lsb_release -cs 2>/dev/null || echo 'stretch') frr-8" > /etc/apt/sources.list.d/frr.list
    curl -s https://deb.frrouting.org/frr/keys.asc | apt-key add - 2>/dev/null || true
    apt-get update
    apt-get install -y frr --allow-unauthenticated
fi

sed -i 's/ospfd=no/ospfd=yes/' /etc/frr/daemons 2>/dev/null || true

cat > /etc/frr/frr.conf <<EOF
frr version 8.5
frr defaults traditional
hostname $(hostname)
log syslog informational
no ipv6 forwarding
service integrated-vtysh-config
!
interface gre1
 ip ospf authentication message-digest
 ip ospf message-digest-key 1 md5 demo2026
exit
!
router ospf
 passive-interface default
 no passive-interface gre1
 network 10.10.10.0/30 area 0
 network 192.168.3.0/28 area 0
exit
!
EOF

systemctl enable --now frr 2>/dev/null || service frr restart

# === Crontab for recovery ===
cat > /root/fixafterreboot.sh <<'EOF'
#!/bin/bash
sleep 3
ip link set gre1 up 2>/dev/null || true
iptables-restore < /etc/iptables.rules 2>/dev/null || true
sysctl -w net.ipv4.ip_forward=1
systemctl restart frr 2>/dev/null || service frr restart
EOF
chmod +x /root/fixafterreboot.sh
(crontab -l 2>/dev/null | grep -v "@reboot /root/fixafterreboot.sh"; echo "@reboot /root/fixafterreboot.sh") | crontab -

echo "✅ BR-RTR configured (GRE + FRR)"
