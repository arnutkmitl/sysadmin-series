#!/usr/bin/env bash
# Log Analysis และ Report: อ่าน Log แล้วสร้างรายงาน
# SysAdmin Pocket Series M04 Python for SysAdmin
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ──  ────────────────────────────────────────────────────────
sudo dnf install -y nginx
sudo systemctl enable --now nginx
sudo firewall-cmd --add-service=http
# [client]
for p in / / / /health /wp-login.php /.env /admin /missing; do curl -s -o /dev/null http://192.168.56.10$p; done

# ── 5.3 นับและจัดกลุ่ม: Counter และ defaultdict ─────────────
sudo ~/python-admin/.venv/bin/python log-stats.py

# ── Lab 5.1 Nginx Log Analyzer ส่งเข้า LINE ─────────────────
sudo ~/python-admin/.venv/bin/python ~/python-admin/scripts/log-report.py
