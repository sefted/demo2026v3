#!/bin/bash
set -e
# Debian 11/12 - Samba AD DC + Chrony + NFS + Ansible

echo "🔧 Configuring BR-SRV (Debian): Chrony + Samba DC + NFS + Ansible..."

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

# === Samba AD DC ===
apt-get install -y samba samba-ad-dc adcli samba-common-bin rng-tools5
systemctl enable --now rngd

[ -f /etc/samba/smb.conf ] && cp /etc/samba/smb.conf /etc/samba/smb.conf.bak
rm -f /etc/samba/smb.conf

samba-tool domain provision \
    --realm=AU-TEAM.IRPO \
    --domain=AU-TEAM \
    --server-role=dc \
    --dns-backend=SAMBA_INTERNAL \
    --adminpass='P@ssw0rd' \
    --use-rfc2307 \
    --host-ip=192.168.3.2 \
    --host-name=br-srv \
    --option="interfaces=lo ${BR_SRV_IF:-eth0}" \
    --option="bind interfaces only=yes"

systemctl stop smbd nmbd  # Disable standalone Samba
systemctl disable --now smbd nmbd
systemctl enable --now samba-ad-dc
ln -sf /var/lib/samba/private/krb5.conf /etc/krb5.conf

# Users and group
for i in 1 2 3 4 5; do
    samba-tool user create hquser$i 'P@ssw0rd' 2>/dev/null || true
done
samba-tool group add hq 2>/dev/null || true
samba-tool group addmembers hq hquser1,hquser2,hquser3,hquser4,hquser5 2>/dev/null || true

# === NFS Server ===
apt-get install -y nfs-kernel-server
mkdir -p /raid/nfs
chmod 777 /raid/nfs
echo "/raid/nfs 192.168.2.0/28(rw,sync,no_subtree_check,no_root_squash)" > /etc/exports
exportfs -ra
systemctl enable --now nfs-kernel-server

# === Ansible + SSH Keys ===
apt-get install -y ansible sshpass openssh-server

cat > /etc/ansible/hosts <<EOF
[clients]
hq-rtr  ansible_host=192.168.1.1  ansible_user=net_admin  ansible_port=2026
br-rtr  ansible_host=192.168.3.1  ansible_user=net_admin  ansible_port=2026
hq-srv  ansible_host=192.168.1.2  ansible_user=sshuser    ansible_port=2026
hq-cli  ansible_host=192.168.2.2  ansible_user=sshuser    ansible_port=2026
EOF

if [ ! -f /root/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -f /root/.ssh/id_rsa -N "" -q
fi

for pair in "192.168.1.1:net_admin" "192.168.3.1:net_admin" "192.168.1.2:sshuser" "192.168.2.2:sshuser"; do
    ip="${pair%%:*}"; user="${pair##*:}"
    sshpass -p 'P@ssw0rd' ssh-copy-id -o StrictHostKeyChecking=no -i /root/.ssh/id_rsa.pub -p 2026 ${user}@${ip} 2>/dev/null || true
done

cat > /etc/ansible/ansible.cfg <<EOF
[defaults]
interpreter_python = python3
host_key_checking = False
inventory = /etc/ansible/hosts
EOF

# Crontab for recovery
cat > /root/fixafterreboot.sh <<'EOF'
#!/bin/bash
sleep 3
systemctl restart chrony
systemctl restart samba-ad-dc
systemctl restart nfs-kernel-server
EOF
chmod +x /root/fixafterreboot.sh
(crontab -l 2>/dev/null | grep -v "@reboot /root/fixafterreboot.sh"; echo "@reboot /root/fixafterreboot.sh") | crontab -

echo "✅ BR-SRV (Debian) configured"
