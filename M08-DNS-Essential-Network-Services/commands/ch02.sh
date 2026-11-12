#!/usr/bin/env bash
# Unbound และ Split DNS
# SysAdmin Pocket Series M08 DNS & Essential Network Services
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 2.1 Unbound Recursive Resolver ──────────────────────────
sudo sed -i "s/listen-on port 53 { 127.0.0.1; 192.168.56.50; };/listen-on port 53 { 192.168.56.50; };/" /etc/named.conf
sudo named-checkconf && sudo systemctl restart named
sudo dnf install -y unbound
unbound -V | head -1
sudo unbound-checkconf
sudo systemctl enable --now unbound
sudo ss -tulnp | grep ":53 " | sort -u -k5,5
sudo journalctl -u unbound -o cat | grep error

# ── ทดสอบ cache ─────────────────────────────────────────────
dig @127.0.0.1 www.isc.org | grep -E "flags:|Query time"
dig @127.0.0.1 www.isc.org | grep -E "flags:|Query time"
sudo unbound-control stats_noreset | grep -E "^total.num.(queries|cachehits|cachemiss)="
dig @127.0.0.1 dnssec-failed.org | grep -E "status|EDE"

# ── ค่าที่ต้องปรับบน Rocky Linux ────────────────────────────
sudo systemctl restart unbound
dig @127.0.0.1 www.rockylinux.org | grep -oE "status: [A-Z]+"
dig @127.0.0.1 www.rockylinux.org +cd | grep -oE "status: [A-Z]+"
sudo systemctl restart unbound
dig @127.0.0.1 www.rockylinux.org | grep -oE "status: [A-Z]+|Query time: [0-9]+ msec"

# ── ส่ง example.com ไปหา BIND ───────────────────────────────
sudo systemctl restart unbound
dig @127.0.0.1 db1.example.com | grep -E "status|EDE"
dig @127.0.0.1 example.com DS +short
sudo unbound-checkconf && sudo systemctl restart unbound
dig @127.0.0.1 db1.example.com +short
dig @127.0.0.1 -x 192.168.56.40 +short
sudo unbound-control list_stubs

# ── Forward ไปที่ upstream ──────────────────────────────────
sudo systemctl restart unbound
sudo unbound-control list_forwards
dig @127.0.0.1 db2.example.com +short

# ── กุญแจสำหรับ zone transfer ───────────────────────────────
(tsig-keygen -a hmac-sha256 internal-xfer; tsig-keygen -a hmac-sha256 external-xfer) | sudo tee /etc/named.xfer.key
sudo chown root:named /etc/named.xfer.key
sudo chmod 640 /etc/named.xfer.key
sudo scp -P 2222 /etc/named.xfer.key admin@192.168.56.51:/tmp/
# บนเครื่อง ns2
sudo install -o root -g named -m 640 /tmp/named.xfer.key /etc/named.xfer.key
# บนเครื่อง ns2
rm /tmp/named.xfer.key
# บนเครื่อง ns2
sudo ls -l /etc/named.xfer.key

# ── view บน ns1 ─────────────────────────────────────────────
sudo chown root:named /var/named/example.com.external.zone
sudo chmod 640 /var/named/example.com.external.zone
sudo named-checkconf && echo checkconf-ok
sudo systemctl restart named
dig @127.0.0.1 www.example.com +short
# บนเครื่อง ns2
dig @192.168.56.50 www.example.com +short
# บนเครื่อง ns2
dig @192.168.56.50 db1.example.com | grep status
# บนเครื่อง ns2
dig @192.168.56.50 -x 192.168.56.40 | grep status

# ── view บน ns2 ─────────────────────────────────────────────
# บนเครื่อง ns2
sudo named-checkconf && echo checkconf-ok
# บนเครื่อง ns2
sudo sh -c "rm -f /var/named/slaves/*"
# บนเครื่อง ns2
sudo systemctl restart named
# บนเครื่อง ns2
sudo journalctl -u named -o cat | grep "transferred serial"
# บนเครื่อง ns2
dig @192.168.56.50 example.com AXFR | tail -1

# ── แก้ข้อมูลใน view เดียว ──────────────────────────────────
sudo sed -i -e "s/2026111201 3600/2026111202 3600/" -e "s/^www     IN  A    203.0.113.20/www     IN  A    203.0.113.21/" /var/named/example.com.external.zone
sudo rndc reload example.com IN external
# บนเครื่อง ns2
sudo journalctl -u named -o cat | grep -E "received notify|notify from|transferred serial" | grep external | tail -3
# บนเครื่อง ns2
sudo journalctl -u named -o cat | grep notify | tail -2
# บนเครื่อง ns2
dig -y hmac-sha256:external-xfer:kfccaI2CPlGeZiPypigefMOm0z7ivuVrA0IqhdPOnIE= @192.168.56.51 www.example.com +short

# ── 2.3 Pi-hole (Bonus) ─────────────────────────────────────
# บนเครื่อง docker
cd ~/pihole && docker compose up -d
# บนเครื่อง docker
docker ps --format "{{.Names}} {{.Status}}"
# บนเครื่อง docker
docker exec pihole pihole version
# บนเครื่อง docker
sudo firewall-cmd --permanent --add-service=dns
# บนเครื่อง docker
sudo firewall-cmd --permanent --add-port=8080/tcp
# บนเครื่อง docker
sudo firewall-cmd --reload
dig @192.168.56.30 doubleclick.net +short
dig @192.168.56.30 ads.google.com +short
dig @192.168.56.30 www.isc.org +short
# บนเครื่อง docker
docker exec pihole pihole deny ads.example.org
dig @192.168.56.30 ads.example.org +short

# ── กล่อง Ubuntu ────────────────────────────────────────────
sudo apt install -y unbound
sudo cp lan.conf /etc/unbound/unbound.conf.d/
sudo unbound-checkconf
sudo systemctl restart unbound
sudo named-checkconf
