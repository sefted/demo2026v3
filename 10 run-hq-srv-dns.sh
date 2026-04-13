#!/bin/bash
set -e
# ⚠️ This script is for Debian/Ubuntu

echo "🔧 Configuring DNS server on HQ-SRV (Debian)..."

# === Install BIND9 ===
if ! command -v named &>/dev/null; then
    apt-get update
    apt-get install -y bind9 dnsutils
fi

# === Disable AppArmor for BIND (if it interferes) ===
# ⚠️ In production, it's better to configure AppArmor correctly instead of disabling it
if command -v aa-status &>/dev/null && aa-status --enabled &>/dev/null; then
    ln -s /etc/apparmor.d/usr.sbin.named /etc/apparmor.d/disable/ 2>/dev/null || true
    apparmor_parser -R /etc/apparmor.d/usr.sbin.named 2>/dev/null || true
fi

# === Main config (options) ===
cat > /etc/bind/named.conf.options <<'EOF'
options {
    directory "/var/cache/bind";
    dump-file "/var/cache/bind/named_dump.db";
    statistics-file "/var/cache/bind/named.stats";
    listen-on { any; };
    allow-query { any; };
    recursion yes;
    allow-recursion { any; };
    allow-query-cache { any; };
    forwarders { 8.8.8.8; 8.8.4.4; };
    dnssec-validation no;
    auth-nxdomain no;
};

logging {
    channel default_log {
        file "/var/log/bind/default.log" versions 3 size 5m;
        severity info;
        print-time yes;
        print-severity yes;
        print-category yes;
    };
    category default { default_log; };
    category general { default_log; };
};
EOF

# === Local zones ===
cat > /etc/bind/named.conf.local <<'EOF'
zone "au-team.irpo" {
    type master;
    file "/etc/bind/db.au-team.irpo";
};
zone "1.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.1.168.192.in-addr.arpa";
};
zone "2.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.2.168.192.in-addr.arpa";
};
EOF

# === Forward zone ===
cat > /etc/bind/db.au-team.irpo <<'EOF'
$TTL 86400
@   IN  SOA ns.au-team.irpo. admin.au-team.irpo. (
            2025020103 ; Serial
            3600       ; Refresh
            1800       ; Retry
            604800     ; Expire
            86400 )    ; Minimum

@       IN  NS      ns.au-team.irpo.
ns      IN  A       192.168.1.2
hq-srv  IN  A       192.168.1.2
br-srv  IN  A       192.168.3.2
hq-rtr  IN  A       192.168.1.1
br-rtr  IN  A       192.168.3.1
hq-cli  IN  A       192.168.2.2
web     IN  A       172.16.2.1
docker  IN  A       172.16.1.1

; SRV records
_ldap._tcp               600 IN SRV 0 100 389   br-srv
_kerberos._tcp           600 IN SRV 0 100 88    br-srv
_kerberos._udp           600 IN SRV 0 100 88    br-srv
_ldap._tcp.dc._msdcs     600 IN SRV 0 100 389   br-srv
_ldap._tcp.gc._msdcs     600 IN SRV 0 100 3268  br-srv
EOF

# === Reverse zones ===
cat > /etc/bind/db.1.168.192.in-addr.arpa <<'EOF'
$TTL 1D
@  IN  SOA ns.au-team.irpo admin.au-team.irpo (
           2025291603 ; Serial
           3600       ; Refresh
           1800       ; Retry
           604800     ; Expire
           86400 )    ; Minimum
        IN  NS      ns.au-team.irpo.
1       IN  PTR     hq-rtr.au-team.irpo.
2       IN  PTR     hq-srv.au-team.irpo.
EOF

cat > /etc/bind/db.2.168.192.in-addr.arpa <<'EOF'
$TTL 1D
@  IN  SOA ns.au-team.irpo admin.au-team.irpo (
           2025291603 ; Serial
           3600       ; Refresh
           1800       ; Retry
           604800     ; Expire
           86400 )    ; Minimum
        IN  NS      ns.au-team.irpo.
1       IN  PTR     hq-rtr.au-team.irpo.
2       IN  PTR     hq-cli.au-team.irpo.
EOF

# === File permissions (Debian: bind user) ===
chown root:bind /etc/bind/db.* 2>/dev/null || true
chmod 640 /etc/bind/db.*

# === Configuration check ===
named-checkconf /etc/bind/named.conf 2>/dev/null || named-checkconf
named-checkzone au-team.irpo /etc/bind/db.au-team.irpo
named-checkzone 1.168.192.in-addr.arpa /etc/bind/db.1.168.192.in-addr.arpa
named-checkzone 2.168.192.in-addr.arpa /etc/bind/db.2.168.192.in-addr.arpa

# === Start service ===
systemctl enable --now bind9 2>/dev/null || service bind9 restart

# === Crontab for recovery ===
cat > /root/fixafterreboot.sh <<'EOF'
#!/bin/bash
sleep 3
systemctl restart bind9 2>/dev/null || service bind9 restart
EOF
chmod +x /root/fixafterreboot.sh
(crontab -l 2>/dev/null | grep -v "@reboot /root/fixafterreboot.sh"; echo "@reboot /root/fixafterreboot.sh") | crontab -

echo "✅ DNS server configured on HQ-SRV (Debian)"
