#!/usr/bin/env bash
# Troubleshooting และการใช้งานจริง
# SysAdmin Pocket Series M08 DNS & Essential Network Services
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── nslookup และ host ───────────────────────────────────────
# บนเครื่อง pc1
nslookup db1.example.com
# บนเครื่อง pc1
nslookup -type=mx example.com | grep mail
# บนเครื่อง pc1
host 192.168.56.40
# บนเครื่อง pc1
host -t ns example.com
# บนเครื่อง pc1
host nosuch.example.com; echo rc=$?

# ── tcpdump port 53 ─────────────────────────────────────────
sudo tcpdump -ni any -l "port 53 and not host 127.0.0.1"

# ── SERVFAIL ทั้งที่ Internet ใช้ได้ ────────────────────────
dig @127.0.0.1 www.rockylinux.org | grep -E "status|Query time"
dig @198.41.0.4 . NS +tries=1 +time=3 | grep status
sudo journalctl -u named -o cat | grep -E "timed out|hung"
ping -6 -c1 -W2 2001:4860:4860::8888 | tail -1
echo 'OPTIONS="-4"' | sudo tee -a /etc/sysconfig/named
sudo systemctl restart named
dig @127.0.0.1 www.rockylinux.org | grep -E "status|Query time"

# ── SERVFAIL จาก zone file ที่ผิด ───────────────────────────
sudo sed -i "s/^mail    IN  A    203.0.113.25$/mail    IN  A    203.0.113.256/" /var/named/example.com.external.zone
sudo rndc reload example.com IN external
sudo journalctl -u named -o cat | grep external | tail -3
# บนเครื่อง ns2
dig @192.168.56.50 www.example.com +short
sudo systemctl restart named
sudo journalctl -u named -o cat | grep "bad dotted quad" | tail -1
grep ExecStartPre /usr/lib/systemd/system/named.service
# ⚠️ ตรวจ zone ด้วย named-checkzone ทุกครั้งก่อน reload และอ่าน log หลัง reload ทุกครั้ง อย่าเชื่อว่า reload สำเร็จเพียงเพราะ dig ยังได้คำตอบ ถ้า restart ในสภาพนี้ named จะไม่ขึ้นทั้งตัว
sudo sed -i "s/203.0.113.256/203.0.113.25/" /var/named/example.com.external.zone
sudo named-checkzone example.com /var/named/example.com.external.zone | tail -1
sudo systemctl start named

# ── NXDOMAIN ทั้งที่เพิ่ม record แล้ว ───────────────────────
# บนเครื่อง pc1
dig backup.example.com | grep status
echo "backup  IN  A    192.168.56.70" | sudo tee -a /var/named/example.com.zone
sudo sed -i "s/2026111203 ; serial/2026111204 ; serial/" /var/named/example.com.zone
sudo rndc reload example.com IN internal
dig @192.168.56.50 backup.example.com +short
# บนเครื่อง pc1
dig backup.example.com | grep -E "status|SOA"
sudo unbound-control flush_negative
# บนเครื่อง pc1
dig backup.example.com +short

# ── Zone transfer ล้มเหลวเพราะ firewall ─────────────────────
sudo firewall-cmd --remove-service=dns
sudo firewall-cmd --add-port=53/udp
# บนเครื่อง ns2
dig @192.168.56.50 www.example.com +short
# บนเครื่อง ns2
sudo rndc retransfer example.com IN internal
# บนเครื่อง ns2
sudo journalctl -u named -o cat | grep "example.com/IN/internal" | tail -3
# บนเครื่อง ns2
dig @192.168.56.50 example.com SOA +tcp +tries=1 +time=3 | grep reached
sudo firewall-cmd --reload
# บนเครื่อง ns2
sudo rndc retransfer example.com IN internal
# บนเครื่อง ns2
sudo journalctl -u named -o cat | grep "Transfer completed" | tail -1

# ── Query log สำหรับตรวจสอบ ─────────────────────────────────
sudo rndc querylog on
dig @192.168.56.50 www.example.com +short
# บนเครื่อง ns2
dig @192.168.56.50 www.example.com +short
sudo journalctl -u named -o cat | grep "query:" | tail -2
sudo rndc querylog off

# ── สถิติด้วย rndc stats ────────────────────────────────────
sudo rndc stats
sudo grep -A6 "Incoming Queries" /var/named/data/named_stats.txt

# ── ตรวจเวลาตอบ ─────────────────────────────────────────────
dig @192.168.56.50 www.example.com | grep -E "status|Query time"
