#!/usr/bin/env bash
# web01-handover.sh ชุดตรวจส่งมอบจากโปรเจกต์จบเล่ม (บทที่ 7)
# รันบน server ด้วยผู้ใช้ที่มี sudo: bash web01-handover.sh
# อ่านค่าอย่างเดียว ไม่แก้ค่าใด ๆ ในเครื่อง ผลบันทึกที่ ~/web01-handover-วันที่.txt
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
