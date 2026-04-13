#!/bin/bash
set -e
source ./env.sh 2>/dev/null || true

echo "🔧 Configuring HQ-CLI: obtaining address via DHCP..."

# Restart network to apply VLAN configuration
systemctl restart network 2>/dev/null || systemctl restart networking 2>/dev/null || true

# Obtain address on VLAN 200
if command -v dhcpcd &>/dev/null; then
    dhcpcd -4 ${HQ_CLI_IF:-eth0}.200 2>/dev/null || true
elif command -v dhclient &>/dev/null; then
    dhclient -4 ${HQ_CLI_IF:-eth0}.200 2>/dev/null || true
fi

# Verification
echo "📡 IP addresses:"
ip a show ${HQ_CLI_IF:-eth0}.200 2>/dev/null || ip a

echo "✅ HQ-CLI configured"
