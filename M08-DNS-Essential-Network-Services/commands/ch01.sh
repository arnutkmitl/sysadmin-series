#!/usr/bin/env bash
# DNS และ BIND 9: ตั้ง Authoritative Server
# SysAdmin Pocket Series M08 DNS & Essential Network Services
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 1.1 DNS ทำงานอย่างไร ────────────────────────────────────
dig -4 +trace +nodnssec www.kmitl.ac.th

# ── 1.2 ติดตั้ง BIND 9 ──────────────────────────────────────
sudo dnf install -y bind bind-utils
named -v
sudo systemctl enable --now named
sudo ss -tulnp | grep named

# ── named.conf สำหรับ authoritative server ──────────────────
sudo cp -a /etc/named.conf /etc/named.conf.orig

# ── zone file ───────────────────────────────────────────────
sudo chown root:named /var/named/example.com.zone
sudo chmod 640 /var/named/example.com.zone
sudo ls -lZ /var/named/example.com.zone
sudo named-checkconf && echo checkconf-ok
sudo named-checkzone example.com /var/named/example.com.zone

# ── เปิด firewall และทดสอบ ──────────────────────────────────
sudo systemctl reload named
sudo firewall-cmd --permanent --add-service=dns
sudo firewall-cmd --reload
dig @192.168.56.50 www.example.com
dig @192.168.56.50 example.com MX +short
dig @192.168.56.50 example.com NS +short
dig @192.168.56.50 www.rockylinux.org | grep -E "status|WARNING"

# ── checkzone ผ่าน ไม่ได้แปลว่าถูก ──────────────────────────
sudo named-checkzone example.com t2.zone
sudo named-checkzone example.com t1.zone
sudo named-checkzone -D example.com t1.zone 2>/dev/null | grep "^www"

# ── 1.4 Reverse Zone และ PTR ────────────────────────────────
sudo chown root:named /var/named/192.168.56.rev
sudo chmod 640 /var/named/192.168.56.rev
sudo named-checkzone 56.168.192.in-addr.arpa /var/named/192.168.56.rev
sudo named-checkconf && sudo rndc reload
dig @192.168.56.50 -x 192.168.56.40 +noall +answer
host 192.168.56.20 192.168.56.50
dig @192.168.56.50 -x 192.168.56.99 | grep -E "status|SOA"

# ── ปิดไว้ก่อน แล้วเปิดเฉพาะ secondary ──────────────────────
# บนเครื่อง ns2
sudo dnf install -y bind bind-utils
# บนเครื่อง ns2
dig @192.168.56.50 example.com AXFR
sudo named-checkconf && sudo rndc reload

# ── ตั้งค่า ns2 ─────────────────────────────────────────────
# บนเครื่อง ns2
sudo named-checkconf && echo ok
# บนเครื่อง ns2
sudo firewall-cmd --permanent --add-service=dns
# บนเครื่อง ns2
sudo firewall-cmd --reload
# บนเครื่อง ns2
sudo systemctl enable --now named
# บนเครื่อง ns2
sudo journalctl -u named -o cat | grep -E "transferred|Transfer completed"
# บนเครื่อง ns2
dig @192.168.56.51 db1.example.com +short

# ── ลืมเพิ่ม serial ─────────────────────────────────────────
echo "nas     IN  A    192.168.56.60" | sudo tee -a /var/named/example.com.zone
sudo rndc reload example.com
dig @192.168.56.50 nas.example.com +short
# บนเครื่อง ns2
dig @192.168.56.51 nas.example.com +short
# บนเครื่อง ns2
sudo journalctl -u named -o cat | grep notify | tail -2
sudo sed -i "s/2026111201 ; serial/2026111202 ; serial/" /var/named/example.com.zone
sudo rndc reload example.com
# บนเครื่อง ns2
dig @192.168.56.51 nas.example.com +short
# บนเครื่อง ns2
sudo journalctl -u named -o cat | grep -E "notify|transferred" | tail -2

# ── กล่อง Ubuntu ────────────────────────────────────────────
sudo apt install -y bind9 bind9-utils bind9-dnsutils
grep -v "^//" /etc/bind/named.conf
sudo ufw allow 53
