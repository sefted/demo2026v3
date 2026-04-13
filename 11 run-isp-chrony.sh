#!/bin/bash
set -e
# Debian/Ubuntu

echo "🔧 Configuring Chrony on ISP (NTP server)..."

# Installation
apt-get update && apt-get install -y chrony

# Configuration: local time source
cp /etc/chrony/chrony.conf /etc/chrony/chrony.conf.bak 2>/dev/null || true
sed -i 's/^pool/#pool/' /etc/chrony/chrony.conf
sed -i 's/^rtcsync/#rtcsync/' /etc/chrony/chrony.conf

# Add local stratum and allow clients
grep -q "^local stratum 5" /etc/chrony/chrony.conf || echo "local stratum 5" >> /etc/chrony/chrony.conf
grep -q "^allow all" /etc/chrony/chrony.conf || echo "allow all" >> /etc/chrony/chrony.conf

# Restart service
systemctl enable --now chronyd

# Verification
chronyc sources -v
echo "✅ ISP configured as NTP server (172.16.1.1)"
