#!/bin/bash
set -e
# Debian 11/12 - HQ-SRV: Chrony (client) + RAID 0 + NFS Server

echo "🔧 Configuring HQ-SRV (Debian): Chrony + RAID + NFS..."

# === 1. Chrony (NTP client) ===
apt-get update && apt-get install -y chrony
timedatectl set-ntp false 2>/dev/null || true

cp /etc/chrony/chrony.conf /etc/chrony/chrony.conf.bak 2>/dev/null || true
sed -i 's/^pool/#pool/' /etc/chrony/chrony.conf
sed -i 's/^rtcsync/#rtcsync/' /etc/chrony/chrony.conf

grep -q "server 172.16.1.1 iburst" /etc/chrony/chrony.conf || \
    echo "server 172.16.1.1 iburst" >> /etc/chrony/chrony.conf
grep -q "^makestep 1 -1" /etc/chrony/chrony.conf || \
    echo "makestep 1 -1" >> /etc/chrony/chrony.conf

systemctl enable --now chrony

# === 2. RAID 0 ===
apt-get install -y mdadm parted e2fsprogs

if [ ! -b /dev/sdb ] || [ ! -b /dev/sdc ]; then
    echo "⚠️ Disks /dev/sdb or /dev/sdc not found. Skipping RAID."
elif [ ! -b /dev/md0 ]; then
    echo "🔨 Creating RAID 0..."
    echo "y" | mdadm --create /dev/md0 --level=0 --raid-devices=2 /dev/sdb /dev/sdc --run

    # Partitioning (automatic, non-interactive)
    parted /dev/md0 --script mklabel msdos mkpart primary ext4 1MiB 100%
    mkfs.ext4 -F /dev/md0p1

    # Save configuration (Debian standard)
    mkdir -p /etc/mdadm
    mdadm --detail --scan >> /etc/mdadm/mdadm.conf
    update-initramfs -u -k all  # Important for Debian: RAID will be detected at boot

    # Mounting
    mkdir -p /raid
    echo "/dev/md0p1 /raid ext4 defaults,noatime 0 2" >> /etc/fstab
    mount -a
    echo "✅ RAID 0 created and mounted at /raid"
else
    echo "✅ RAID already exists, skipping creation"
fi

# === 3. NFS Server ===
apt-get install -y nfs-kernel-server
mkdir -p /raid/nfs
chmod 777 /raid/nfs

# Export for HQ subnet (VLAN 200)
echo "/raid/nfs 192.168.2.0/28(rw,sync,no_subtree_check,no_root_squash)" > /etc/exports
exportfs -ra

systemctl enable --now nfs-kernel-server

# === 4. Crontab for post-reboot recovery ===
cat > /root/fixafterreboot.sh <<'EOF'
#!/bin/bash
sleep 3
systemctl restart chrony
mdadm --assemble --scan 2>/dev/null || true
mount -a
systemctl restart nfs-kernel-server
EOF
chmod +x /root/fixafterreboot.sh
(crontab -l 2>/dev/null | grep -v "@reboot /root/fixafterreboot.sh"; echo "@reboot /root/fixafterreboot.sh") | crontab -

echo "✅ HQ-SRV (Debian) configured (Chrony + RAID + NFS)"
