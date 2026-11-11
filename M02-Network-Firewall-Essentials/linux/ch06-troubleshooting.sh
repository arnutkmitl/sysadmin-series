#!/usr/bin/env bash
# บทที่ 6 Troubleshooting Network เมื่อ Network ล่ม
# SysAdmin Pocket Series M02 Network & Firewall Essentials
#
# ไฟล์นี้รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# Lab บางข้อตั้งใจทำให้เครือข่ายพัง ห้ามรันทั้งไฟล์
# คำสั่งที่ไม่มีป้าย [client] หรือ [Ubuntu] รันบน server (Rocky Linux 10)
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── ตัวที่ 1: ip link และ ip addr การ์ดขึ้นหรือไม่ ──────────────
ip -br link
ip -br addr show enp0s9


# ── ตัวที่ 2: ping เชื่อมต่อถึงหรือไม่ ──────────────────────────
ping -c 4 10.0.2.2
ping -c 4 8.8.8.8
ping -c 4 google.com


# ── ตัวที่ 3: traceroute และ mtr ทางตันอยู่ตรงไหน ───────────────
traceroute -n 1.1.1.1
tracepath -n 1.1.1.1
mtr -rwc 20 1.1.1.1


# ── ตัวที่ 4: ss พอร์ตเปิดอยู่หรือไม่ ───────────────────────────
sudo ss -tlnp
sudo ss -tnp state established '( sport = :2222 )'
ss -s


# ── ตัวที่ 5: dig และ nslookup DNS ตอบถูกหรือไม่ ────────────────
dig +short rockylinux.org
dig @8.8.8.8 rockylinux.org
dig rockylinux.org | grep -E 'status|SERVER'


# ── ตัวที่ 6: tcpdump ดูแพ็กเก็ตจริง ────────────────────────────
# ⚠️ tcpdump บน server ที่มี traffic สูงใช้ CPU และดิสก์มาก ไฟล์ .pcap ที่ไม่จำกัดจำนวนแพ็กเก็ตจะโตจนดิสก์เต็มได้ ใส่ตัวกรองให้แคบและใช้ `-c` จำกัดจำนวนแพ็กเก็ตทุกครั้ง ไฟล์ .pcap อาจมีรหัสผ่านของโปรโตคอลที่ไม่เข้ารหัส ลบทิ้งเมื่อใช้เสร็จ
sudo tcpdump -i enp0s9 -n port 80
sudo tcpdump -i enp0s9 -n host 192.168.57.20 and port 2222
sudo tcpdump -i enp0s9 -n -c 200 -w /tmp/capture.pcap


# ── ตัวที่ 7: nmap มองจากภายนอก ─────────────────────────────────
# ⚠️ ใช้ nmap กับเครื่องที่คุณดูแลหรือได้รับอนุญาตเป็นลายลักษณ์อักษรเท่านั้น การสแกนระบบของผู้อื่นอาจเข้าข่ายความผิดตามพระราชบัญญัติว่าด้วยการกระทำความผิดเกี่ยวกับคอมพิวเตอร์ และระบบตรวจจับของผู้ให้บริการจะบล็อก IP ของคุณ
# [client]
nmap -sT -p 22,80,443,2222,3306 192.168.57.10
nmap -sV -p 80 192.168.57.10


# ── Lab 6.1 Network Troubleshooting Challenge ───────────────────
sudo nmcli con mod enp0s3 ipv4.dns 192.0.2.53
sudo nmcli con up enp0s3

sudo firewall-cmd --zone=internal --remove-rich-rule='rule family="ipv4" source address="192.168.56.0/24" accept'

# ⚠️ คำสั่งชุดนี้ทำให้ client ใช้ IP เดียวกับ server ทำใน Lab เท่านั้น ห้ามทดลองบนเครือข่ายจริง เพราะเครื่องอื่นในวงจะเชื่อมต่อผิดเครื่อง
# [client]
sudo nmcli con mod mgmt ipv4.addresses 192.168.56.10/24 ipv4.dad-timeout 0
sudo nmcli con up mgmt

sudo arping -D -I enp0s8 -c 3 192.168.56.10
