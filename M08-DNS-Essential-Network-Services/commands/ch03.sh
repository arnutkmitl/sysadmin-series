#!/usr/bin/env bash
# DHCP และ NTP Server
# SysAdmin Pocket Series M08 DNS & Essential Network Services
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── ติดตั้งและตั้งค่า ───────────────────────────────────────
sudo dnf install -y kea
sudo cp -a /etc/kea/kea-dhcp4.conf /etc/kea/kea-dhcp4.conf.orig
sudo kea-dhcp4 -t /etc/kea/kea-dhcp4.conf > /dev/null && echo config-ok
sudo firewall-cmd --permanent --add-service=dhcp
sudo firewall-cmd --reload
sudo systemctl enable --now kea-dhcp4
sudo ss -ulnp | grep ":67 "

# ── ดูการแจก IP ─────────────────────────────────────────────
sudo journalctl -u kea-dhcp4 -o cat | grep -E "DHCPDISCOVER|DHCPOFFER|DHCPREQUEST|LEASE_ALLOC|DHCPACK"
sudo cat /var/lib/kea/kea-leases4.csv
# บนเครื่อง pc1
ip -br -4 a show enp0s9
# บนเครื่อง pc1
ip route | grep default
# บนเครื่อง pc1
grep -v "^#" /etc/resolv.conf
# บนเครื่อง pc1
dig www.example.com +short
# บนเครื่อง pc1
dig db1 +short +search

# ── จอง IP ให้เครื่องเฉพาะ ──────────────────────────────────
sudo kea-dhcp4 -t /etc/kea/kea-dhcp4.conf > /dev/null && echo config-ok
sudo systemctl reload kea-dhcp4
sudo journalctl -u kea-dhcp4 -o cat | grep -o "DHCP4_DYNAMIC_RECONFIGURATION_SUCCESS.*"
# บนเครื่อง pc1
sudo nmcli con up "Wired connection 1"
# บนเครื่อง pc1
ip -br -4 a show enp0s9
sudo journalctl -u kea-dhcp4 -o cat | grep -E "DHCPNAK|LEASE_ALLOC" | tail -2

# ── แยก zone ของเครื่อง DHCP ────────────────────────────────
tsig-keygen -a hmac-sha256 ddns-key | sudo tee /etc/named.ddns.key
sudo chown root:named /etc/named.ddns.key
sudo chmod 640 /etc/named.ddns.key
sudo chown named:named /var/named/dynamic/lan.example.com.zone /var/named/dynamic/10.8.0.rev
sudo named-checkconf && echo checkconf-ok
sudo rndc reconfig
sudo rndc reload example.com IN internal
dig @192.168.56.50 lan.example.com SOA +short

# ── ns2 และ Unbound ─────────────────────────────────────────
# บนเครื่อง ns2
sudo named-checkconf && sudo rndc reconfig
# บนเครื่อง ns2
sudo journalctl -u named -o cat | grep "transferred serial" | tail -2
sudo unbound-checkconf && sudo systemctl restart unbound
dig @127.0.0.1 -x 10.8.0.1 +short

# ── ตั้งค่า D2 และเปิดใน kea-dhcp4 ──────────────────────────
sudo chown root:kea /etc/kea/kea-dhcp-ddns.conf
sudo chmod 640 /etc/kea/kea-dhcp-ddns.conf
sudo kea-dhcp-ddns -t /etc/kea/kea-dhcp-ddns.conf 2>&1 | grep -o "result: success.*"
sudo kea-dhcp4 -t /etc/kea/kea-dhcp4.conf > /dev/null && echo config-ok
sudo systemctl enable --now kea-dhcp-ddns
sudo systemctl reload kea-dhcp4
sudo journalctl -u kea-dhcp4 -o cat | grep -o "DHCP4_CONFIG_COMPLETE.*" | tail -1

# ── ทดสอบ ───────────────────────────────────────────────────
# บนเครื่อง pc1
sudo nmcli con up "Wired connection 1"
# บนเครื่อง pc1
grep -v "^#" /etc/resolv.conf
sudo journalctl -u named -o cat | grep approved
dig @192.168.56.50 pc1.lan.example.com +short
dig @192.168.56.50 -x 10.8.0.20 +short
dig @192.168.56.50 pc1.lan.example.com DHCID +short
# บนเครื่อง ns2
dig @127.0.0.1 pc1.lan.example.com +short
# บนเครื่อง pc1
ping -c1 pc1 | head -1

# ── แก้ zone ที่เปิดให้ update ด้วยมือ ──────────────────────
sudo ls -l /var/named/dynamic/ | grep lan
sudo grep -c pc1 /var/named/dynamic/lan.example.com.zone
printf "manual\t\t\tA\t10.8.0.31\n" | sudo tee -a /var/named/dynamic/lan.example.com.zone
sudo rndc reload lan.example.com IN internal
sudo systemctl restart named
dig @192.168.56.50 manual.lan.example.com +short
sudo grep -c manual /var/named/dynamic/lan.example.com.zone
sudo rndc freeze lan.example.com IN internal
sudo grep -E "serial|pc1" /var/named/dynamic/lan.example.com.zone
printf "printer\t\t\tA\t10.8.0.30\n" | sudo tee -a /var/named/dynamic/lan.example.com.zone
sudo sed -i "s/^\(\s*\)2026111202 /\12026111203 /" /var/named/dynamic/lan.example.com.zone
sudo named-checkzone lan.example.com /var/named/dynamic/lan.example.com.zone | tail -1
sudo rndc thaw lan.example.com IN internal
dig @192.168.56.50 printer.lan.example.com +short

# ── 3.3 NTP Server ด้วย Chrony ──────────────────────────────
chronyc sources
sudo cp -a /etc/chrony.conf /etc/chrony.conf.orig
printf "allow 10.8.0.0/24\nallow 192.168.56.0/24\nlocal stratum 10\n" | sudo tee -a /etc/chrony.conf
sudo systemctl restart chronyd
sudo firewall-cmd --permanent --add-service=ntp
sudo firewall-cmd --reload
sudo ss -ulnp | grep ":123 "

# ── เครื่องลูกข่าย ──────────────────────────────────────────
# บนเครื่อง pc1
cat /run/chrony-dhcp/enp0s9.sources
# บนเครื่อง pc1
sudo systemctl restart chronyd
# บนเครื่อง pc1
chronyc sources
# บนเครื่อง pc1
chronyc tracking | grep -E "Reference ID|Stratum|System time"
sudo chronyc clients
# บนเครื่อง ns2
sudo sed -i "s/^pool 2.rocky.pool.ntp.org iburst/server 192.168.56.50 iburst/" /etc/chrony.conf
# บนเครื่อง ns2
sudo systemctl restart chronyd
# บนเครื่อง ns2
chronyc sources | tail -1

# ── กล่อง Ubuntu ────────────────────────────────────────────
sudo apt install -y kea-dhcp4-server kea-dhcp-ddns-server
sudo systemctl restart kea-dhcp4-server kea-dhcp-ddns-server
