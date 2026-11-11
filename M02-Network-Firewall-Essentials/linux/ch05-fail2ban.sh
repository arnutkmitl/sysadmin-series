#!/usr/bin/env bash
# บทที่ 5 Fail2ban ป้องกัน Brute Force อัตโนมัติ
# SysAdmin Pocket Series M02 Network & Firewall Essentials
#
# ไฟล์นี้รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# Lab บางข้อตั้งใจทำให้เครือข่ายพัง ห้ามรันทั้งไฟล์
# คำสั่งที่ไม่มีป้าย [client] หรือ [Ubuntu] รันบน server (Rocky Linux 10)
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 5.1 Brute Force Attack ดูจาก Log จริง ───────────────────────
sudo journalctl -u sshd --since today | grep -E 'Failed password|Invalid user'

sudo journalctl -u sshd --since "24 hours ago" | grep -oE 'from [0-9.]+' | sort | uniq -c | sort -rn | head -5


# ── 5.2 ติดตั้ง Fail2ban ────────────────────────────────────────
sudo dnf install -y epel-release
sudo dnf install -y fail2ban
sudo systemctl enable --now fail2ban
sudo fail2ban-client version


# ── 5.3 ตั้งค่า Jail ────────────────────────────────────────────
# ไฟล์ตั้งค่าของหัวข้อนี้อยู่ที่ configs/rocky/etc/fail2ban/jail.local ในชุดดาวน์โหลด
sudo fail2ban-client -t
sudo systemctl restart fail2ban


# ── 5.4 เพิ่ม Jail สำหรับบริการอื่น ─────────────────────────────
# ⚠️ เปิด jail เฉพาะบริการที่ติดตั้งจริง ถ้าเปิด jail ของ nginx บนเครื่องที่ไม่มี nginx ไฟล์ log จะไม่มีอยู่ และ Fail2ban จะไม่ยอมเริ่มทำงานทั้งหมด รวมถึง jail ของ SSH ด้วย
# ตัวอย่างค่าหรือรูปแบบในเล่ม (ไม่ใช่คำสั่ง):
#   [nginx-http-auth]
#   enabled = true
#
#   [nginx-botsearch]
#   enabled = true

# ── 5.5 จัดการ Fail2ban ในงานประจำวัน ───────────────────────────
sudo fail2ban-client status
sudo fail2ban-client status sshd

sudo fail2ban-client set sshd unbanip 192.168.57.20
sudo fail2ban-client set sshd banip 203.0.113.77
sudo fail2ban-client banned

sudo firewall-cmd --list-rich-rules


# ── 5.6 Whitelist อย่าแบนตัวเอง ─────────────────────────────────
# ⚠️ ใส่ IP ของตัวเองใน ignoreip ก่อนเริ่มทดสอบเสมอ ไม่อย่างนั้นอาจถูกล็อกอยู่นอก server ของตัวเอง ถ้าเกิดขึ้นแล้ว ให้เข้าทาง Console แล้วสั่ง `fail2ban-client set sshd unbanip IP ของคุณ`
# ตัวอย่างค่าหรือรูปแบบในเล่ม (ไม่ใช่คำสั่ง):
#   ignoreip = 127.0.0.1/8 ::1 192.168.56.0/24 192.168.57.1
#   ignoreip = 127.0.0.1/8 ::1 10.20.0.0/16 203.0.113.200

# ── Lab 5.1 ติดตั้ง Fail2ban และทดสอบ Brute Force ───────────────
sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.57.0/24" port port="2222" protocol="tcp" accept'

for i in 1 2 3 4; do ssh -p 2222 -o BatchMode=yes -o ConnectTimeout=5 hacker@192.168.57.10; sleep 2; done

sudo fail2ban-client status sshd | grep 'Banned IP'
sudo firewall-cmd --list-rich-rules | grep 192.168.57.20
sudo fail2ban-client set sshd unbanip 192.168.57.20
sudo firewall-cmd --reload


# ── กล่อง Ubuntu ────────────────────────────────────────────────
# ไฟล์ตั้งค่าของหัวข้อนี้อยู่ที่ configs/ubuntu/etc/fail2ban/jail.local ในชุดดาวน์โหลด
# [Ubuntu]
sudo apt install -y fail2ban
sudo fail2ban-client -t && sudo systemctl restart fail2ban
sudo journalctl -u ssh --since today | grep 'Invalid user'
