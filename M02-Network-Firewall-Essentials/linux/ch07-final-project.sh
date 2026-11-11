#!/usr/bin/env bash
# โปรเจกต์จบเล่ม: Secure Network สำหรับ Web Server
# SysAdmin Pocket Series M02 Network & Firewall Essentials
#
# ไฟล์นี้รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# Lab บางข้อตั้งใจทำให้เครือข่ายพัง ห้ามรันทั้งไฟล์
# คำสั่งที่ไม่มีป้าย [client] หรือ [Ubuntu] รันบน server (Rocky Linux 10)
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── ตรวจผลบน server ─────────────────────────────────────────────
{
  hostnamectl --static
  ip -br addr
  ip route show default
  nmcli -g ipv4.dns con show enp0s3
  sudo firewall-cmd --get-active-zones
  sudo firewall-cmd --zone=public --list-all
  sudo firewall-cmd --zone=internal --list-rich-rules
  timedatectl | grep -E 'Time zone|synchronized'
  chronyc sources | grep '^\^\*'
  sudo fail2ban-client status sshd | grep -E 'Currently|Banned'
  sudo grep ^ignoreip /etc/fail2ban/jail.local
} 2>&1 | tee ~/web01-handover-$(date +%F).txt


# ── ตรวจผลจากภายนอก ─────────────────────────────────────────────
# [client]
ping -c 2 192.168.57.10
nmap -sT -p 22,80,443,2222,3306 192.168.57.10
ssh -p 2222 admin@192.168.56.10 hostname
