#!/bin/bash
set -e
# Debian 11/12 - Realm Join + NFS Client + Chrony + SSH

echo "🔧 Configuring HQ-CLI (Debian): Chrony + Realm + NFS + SSH..."

# === Chrony ===
apt-get update && apt-get install -y chrony
timedatectl set-ntp false 2>/dev/null || true
cp /etc/chrony/chrony.conf /etc/chrony/chrony.conf.bak
sed -i 's/^pool/#pool/' /etc/chrony/chrony.conf
sed -i 's/^rtcsync/#rtcsync/' /etc/chrony/chrony.conf
grep -q "server 172.16.1.1 iburst" /etc/chrony/chrony.conf || \
    echo "server 172.16.1.1 iburst" >> /etc/chrony/chrony.conf
grep -q "^makestep 1 -1" /etc/chrony/chrony.conf || \
    echo "makestep 1 -1" >> /etc/chrony/chrony.conf
systemctl enable --now chrony

# === Realm Join (SSSD) ===
apt-get install -y realmd sssd sssd-tools adcli packagekit
echo 'P@ssw0rd' | realm join -U Administrator AU-TEAM.IRPO

# PAM: Auto-create home directories (Debian uses common-session)
grep -q "pam_mkhomedir" /etc/pam.d/common-session || \
    echo "session optional pam_mkhomedir.so skel=/etc/skel umask=0077" >> /etc/pam.d/common-session

# SSSD configuration
sed -i 's/ad_enable_gc = True/ad_enable_gc = False/' /etc/sssd/sssd.conf 2>/dev/null || true
sed -i 's/names = True/names = False/' /etc/sssd/sssd.conf 2>/dev/null || true
sed -i 's/%u@%D/%u/' /etc/sssd/sssd.conf 2>/dev/null || true
chmod 600 /etc/sssd/sssd.conf
systemctl enable --now sssd

# Sudo for domain group (Debian uses sudo group, not wheel)
mkdir -p /etc/sudoers.d
echo "%hq ALL=(ALL) NOPASSWD: /usr/bin/cat, /bin/grep, /usr/bin/id" > /etc/sudoers.d/hq
chmod 440 /etc/sudoers.d/hq
visudo -c

# === NFS Client ===
apt-get install -y nfs-common
mkdir -p /mnt/nfs
echo "192.168.1.2:/raid/nfs /mnt/nfs nfs defaults,_netdev 0 0" >> /etc/fstab
mount -a
touch /mnt/nfs/test_demo2026 && echo "test" >> /mnt/nfs/test_demo2026

# === SSH Server ===
apt-get install -y openssh-server
useradd -m -u 2026 -s /bin/bash sshuser 2>/dev/null || true
echo 'sshuser:P@ssw0rd' | chpasswd
usermod -aG sudo sshuser

cat > /etc/ssh/sshd_config.d/20-custom.conf <<EOF
Port 2026
MaxAuthTries 2
PermitRootLogin no
AllowUsers sshuser
EOF
systemctl restart ssh

# Crontab for recovery
cat > /root/fixafterreboot.sh <<'EOF'
#!/bin/bash
sleep 3
systemctl restart chrony
systemctl restart sssd
mount -a
systemctl restart ssh
EOF
chmod +x /root/fixafterreboot.sh
(crontab -l 2>/dev/null | grep -v "@reboot /root/fixafterreboot.sh"; echo "@reboot /root/fixafterreboot.sh") | crontab -

echo "✅ HQ-CLI (Debian) configured"
