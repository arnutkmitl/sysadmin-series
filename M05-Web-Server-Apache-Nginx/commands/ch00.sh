#!/usr/bin/env bash
# ก่อนเริ่ม: วิธีใช้หนังสือและเตรียมเครื่อง
# SysAdmin Pocket Series M05 Web Server: Apache & Nginx
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── สิ่งที่ต้องเตรียม ───────────────────────────────────────
sudo hostnamectl set-hostname web
sudo firewall-cmd --permanent --add-service={http,https}
sudo firewall-cmd --reload
sudo firewall-cmd --list-services
sudo dnf install -y tar policycoreutils-python-utils

# ── ชื่อเว็บสำหรับ Lab ──────────────────────────────────────
echo "192.168.56.20  site1.lab.test site2.lab.test wp.lab.test app.lab.test static.lab.test" | sudo tee -a /etc/hosts
getent hosts site1.lab.test
