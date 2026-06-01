2) Примечание: В Debian для применения настроек VLAN и интерфейсов через ifupdown иногда требуется пакет vlan (apt install -y vlan). Если команда systemctl restart networking отработает некорректно, замените её на ifup -a или systemctl restart systemd-networkd (в зависимости от версии Debian).
3) Примечание: Как и в предыдущих скриптах, если systemctl restart networking не сработает в вашей версии Debian, используйте ifup -a или systemctl restart systemd-networkd. Остальное полностью готово к запуску.
4)  Примечание: Этот скрипт использует специфичную для ALT Linux/ALT Server структуру /etc/net/ifaces/. Если вы запускаете его на Debian/Ubuntu, пути и команды управления сетью могут отличаться. В таком случае потребуется адаптация под ifupdown или systemd-networkd. Если нужно — помогу с конвертацией.
5)  Примечание: Как и в предыдущем скрипте, здесь используется структура /etc/net/ifaces/, характерная для ALT Linux/ALT Server. При запуске на Debian/Ubuntu потребуется адаптация под ifupdown или systemd-networkd. Также обратите внимание, что в crontab добавлены команды docker restart — убедитесь, что контейнеры db и testapp действительно существуют на этой системе. Если нужна помощь с конвертацией под другой дистрибутив — обращайтесь.
6)  Примечание: Скрипт использует структуру /etc/net/ifaces/, характерную для ALT Linux/ALT Server. При запуске на Debian/Ubuntu потребуется адаптация под ifupdown или systemd-networkd. Если нужна помощь с конвертацией под другой дистрибутив — обращайтесь.
7)  Скрипт использует apt-key add, который устарел в новых версиях Debian. Для полной совместимости можно заменить на установку ключа через /etc/apt/trusted.gpg.d/.
Если ifup не работает, замените на ifup -a или используйте systemctl restart networking.
8) Скрипт использует apt-key add, который устарел в новых версиях Debian. Для полной совместимости можно заменить на установку ключа через /etc/apt/trusted.gpg.d/.
Если ifup не работает, замените на ifup -a или используйте systemctl restart networking.
Убедитесь, что на обоих концах туннеля (HQ-RTR и BR-RTR) настроены корректные внешние адреса для local/remote в настройках GRE.
9) Скрипт пытается использовать dhcpcd или dhclient в зависимости от того, что установлено в системе. Убедитесь, что хотя бы один из этих клиентов DHCP присутствует.
Структура /etc/net/ifaces/ (используемая в предыдущих скриптах для настройки VLAN) характерна для ALT Linux. При запуске на Debian/Ubuntu может потребоваться адаптация под ifupdown или systemd-networkd.
Если интерфейс .200 не поднимается, проверьте, загружен ли модуль 8021q (modprobe 8021q) и создан ли VLAN-интерфейс.

11) Небольшое примечание: на Debian/Ubuntu служба обычно называется chrony, а не chronyd (последнее характерно для RHEL/CentOS/Fedora). Если скрипт ругнётся на systemctl enable --now chronyd, замените chronyd на chrony. Остальное работает как задумано.
12) Служба NTP обычно называется chrony, а не chronyd.
SSH-демон в systemd называется ssh, а не sshd.
Если при выполнении возникнут ошибки Unit not found, замените chronyd → chrony и sshd → ssh. В остальном скрипт готов к использованию.
13) 💡 Напоминание для Debian/Ubuntu: если система ругнётся на Unit chronyd.service not found или Unit sshd.service not found, замените chronyd → chrony и sshd → ssh. На RHEL-семействе имена наоборот.


как скачать 

<img width="2487" height="761" alt="1" src="https://github.com/user-attachments/assets/17968fae-52b5-44bb-8252-06a301ab6b24" />

копируем <img width="1306" height="778" alt="image" src="https://github.com/user-attachments/assets/b777924b-5c13-4dc6-be99-2588566e25e7" />

и ввставлем в wget (ссылка)

chmod +x *-setup.sh

# На машине ISP:
./isp-setup.sh

# На машине HQ-RTR:
./hq-rtr-setup.sh

# И так далее...


nano /etc/apt/sources.list все закоментить

nano /etc/resolv.conf оставить только nameserver 1.1.1.1

apt instal iptables iptables-persistent

mkdir /home/sk cd /home/sk apt instal iptables iptables-persistent

chmod +x (скрипт) ./(скрипт)


https://github.com/Zoriss/Aboba

http://88.204.56.234
