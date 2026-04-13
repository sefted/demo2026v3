10)
11) Небольшое примечание: на Debian/Ubuntu служба обычно называется chrony, а не chronyd (последнее характерно для RHEL/CentOS/Fedora). Если скрипт ругнётся на systemctl enable --now chronyd, замените chronyd на chrony. Остальное работает как задумано.
12) Служба NTP обычно называется chrony, а не chronyd.
SSH-демон в systemd называется ssh, а не sshd.
Если при выполнении возникнут ошибки Unit not found, замените chronyd → chrony и sshd → ssh. В остальном скрипт готов к использованию.
13) 💡 Напоминание для Debian/Ubuntu: если система ругнётся на Unit chronyd.service not found или Unit sshd.service not found, замените chronyd → chrony и sshd → ssh. На RHEL-семействе имена наоборот.
14) 
