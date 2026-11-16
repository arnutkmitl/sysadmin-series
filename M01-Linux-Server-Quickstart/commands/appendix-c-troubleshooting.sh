#!/usr/bin/env bash
# ภาคผนวก ค รวมการแก้ไขปัญหา
# SysAdmin Pocket Series M01 Linux Server Quickstart ฉบับปรับปรุง (Rocky Linux 10.2)
#
# ไฟล์นี้รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# คำสั่งที่ไม่มีป้ายรันบน server ส่วนบรรทัดที่มีป้าย [Host PC] รันใน PowerShell บน Windows
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── ลำดับการไล่ปัญหา ────────────────────────────────────────────
sudo journalctl -p err --since today --no-pager
sudo journalctl -u sshd -n 50 --no-pager
systemctl status sshd
systemctl --failed
ip -br addr
ip route get 1.1.1.1
sudo ss -tlnp
sudo firewall-cmd --list-all
getenforce
sudo ausearch -m avc -ts recent
ls -la /path/ที่มีปัญหา
ls -Z /path/ที่มีปัญหา
df -h

systemctl --failed


# ── SSH ─────────────────────────────────────────────────────────
# [Host PC] ssh -v server
