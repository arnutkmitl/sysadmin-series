#!/usr/bin/env bash
# โปรเจกต์จบเล่ม: Complete DNS Infrastructure
# SysAdmin Pocket Series M08 DNS & Essential Network Services
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── ขั้นที่ 1 เพิ่ม server ใหม่ให้ครบทั้งสองทาง ─────────────
sudo named-checkzone example.com /var/named/example.com.zone | tail -1
sudo named-checkzone 56.168.192.in-addr.arpa /var/named/192.168.56.rev | tail -1
sudo rndc reload example.com IN internal
sudo rndc reload 56.168.192.in-addr.arpa IN internal

# ── ขั้นที่ 2 ตรวจรับด้วย check-dns.sh ──────────────────────
chmod +x check-dns.sh
sudo ./check-dns.sh primary
# บนเครื่อง ns2
sudo ./check-dns.sh secondary
# บนเครื่อง pc1
./check-dns.sh client

# ── ขั้นที่ 3 ซ้อมให้ script จับความผิดปกติ ─────────────────
sudo firewall-cmd --remove-service=dns
sudo firewall-cmd --add-port=53/udp
printf "files   IN  A    192.168.56.80\n" | sudo tee -a /var/named/example.com.zone
sudo sed -i "s/2026111204 ; serial/2026111205 ; serial/" /var/named/example.com.zone
sudo rndc reload example.com IN internal
sudo ./check-dns.sh primary | grep -E "^FAIL|^ผ่าน"
# บนเครื่อง ns2
sudo ./check-dns.sh secondary | grep -E "^FAIL|^ผ่าน"
sudo firewall-cmd --reload
printf "80      IN  PTR  files.example.com.\n" | sudo tee -a /var/named/192.168.56.rev
sudo sed -i "0,/2026111203 3600/s//2026111204 3600/" /var/named/192.168.56.rev
sudo rndc reload 56.168.192.in-addr.arpa IN internal
sudo ./check-dns.sh primary | grep -E "^FAIL|^ผ่าน"
# บนเครื่อง ns2
sudo ./check-dns.sh secondary | grep -E "^FAIL|^ผ่าน"
# บนเครื่อง ns2
sudo journalctl -u named -o cat | grep unreachable | tail -1
# บนเครื่อง ns2
sudo systemctl restart named
sudo rndc notify example.com IN internal
# บนเครื่อง ns2
sudo journalctl -u named -o cat | grep "transferred serial" | tail -1
# บนเครื่อง ns2
sudo ./check-dns.sh secondary | grep -E "^FAIL|^ผ่าน"

# ── ขั้นที่ 4 ซ้อม ns1 ดับ ──────────────────────────────────
sudo unbound-control flush_zone example.com
sudo systemctl stop named
# บนเครื่อง pc1
dig db1.example.com | grep -E "status|Query time"
# บนเครื่อง pc1
dig www.example.com +short
sudo systemctl start named
