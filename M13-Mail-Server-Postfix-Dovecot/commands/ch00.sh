#!/usr/bin/env bash
# ก่อนเริ่ม: วิธีใช้หนังสือและเตรียมเครื่อง
# SysAdmin Pocket Series M13 Mail Server
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── ให้ ns1 ตอบ mail server ด้วยข้อมูลภายใน ─────────────────
# บนเครื่อง ns1
sudo grep -n '^acl "lan"' /etc/named.conf
sudo sed -i 's|^acl "lan" { localhost; 10.8.0.0/24; };|acl "lan" { localhost; 10.8.0.0/24; 192.168.56.25; 192.168.56.26; };|' /etc/named.conf
sudo grep -n '^acl "lan"' /etc/named.conf
sudo named-checkconf && sudo rndc reload

# ── ตั้งชื่อเครื่อง ─────────────────────────────────────────
# บนเครื่อง mail1
sudo hostnamectl set-hostname mail.example.com
hostname

# ── เปิด EPEL ───────────────────────────────────────────────
# บนเครื่อง mail2
sudo dnf install -y epel-release

# ── resolver ของ mail server เอง ────────────────────────────
# บนเครื่อง mail1
sudo dnf install -y bind-utils unbound
sudo tee /etc/unbound/conf.d/lab.conf > /dev/null <<'END'
# โดเมนของ Lab ถาม ns1 ส่วนชื่ออื่น unbound ค้นเองจาก root server
server:
    domain-insecure: "example.com"
    domain-insecure: "example.org"
    domain-insecure: "56.168.192.in-addr.arpa"
    local-zone: "168.192.in-addr.arpa." nodefault
stub-zone:
    name: "example.com"
    stub-addr: 192.168.56.50
stub-zone:
    name: "example.org"
    stub-addr: 192.168.56.50
stub-zone:
    name: "56.168.192.in-addr.arpa"
    stub-addr: 192.168.56.50
END
sudo unbound-checkconf
sudo systemctl enable --now unbound
dig +short @127.0.0.1 mail.example.com
sudo nmcli con mod enp0s3 ipv4.ignore-auto-dns yes ipv6.ignore-auto-dns yes
sudo nmcli con mod enp0s8 ipv4.dns 127.0.0.1 ipv4.dns-search example.com
sudo nmcli con up enp0s3 > /dev/null; sudo nmcli con up enp0s8 > /dev/null
grep -v "^#" /etc/resolv.conf
dig +short mx example.com
dig +short -x 192.168.56.25
dig +short mx gmail.com | head -2
dig +short 2.0.0.127.zen.spamhaus.org
