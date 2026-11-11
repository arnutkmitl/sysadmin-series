#!/usr/bin/env bash
# ภาคผนวก ค รวมการแก้ไขปัญหา (Troubleshooting)
# SysAdmin Pocket Series M01 Linux Server Quickstart
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# "หน้า N" คือเลขหน้าที่พิมพ์ในหนังสือ
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── หน้า 227 ────────────────────────────────────────
sudo journalctl -p err --since today
sudo journalctl -u [service] -n 50
systemctl status [service]
systemctl --failed
ip addr (มี IP ไหม)
ping 8.8.8.8 (Network ออกได้ไหม)
ss -tlnp (Port เปิดอยู่ไหม)
firewall-cmd --list-all
getenforce
sealert -a /var/log/audit/audit.log

# ── หน้า 228 ────────────────────────────────────────
ls -la [path]
ls -Z [path] (SELinux Context)
