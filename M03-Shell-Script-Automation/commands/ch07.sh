#!/usr/bin/env bash
# โปรเจกต์จบเล่ม: Server Automation Suite
# SysAdmin Pocket Series M03 Shell Script Automation
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── ลำดับงาน ────────────────────────────────────────────────
sudo install -D -m 644 lib.sh /usr/local/lib/sysadmin/lib.sh
for s in server-health disk-alert backup-config backup-database log-rotate-custom service-restart; do sudo install -m 755 "$s.sh" /usr/local/bin/; done
sudo nano /usr/local/bin/service-restart.sh

# ── ตรวจรับงาน ──────────────────────────────────────────────
sudo ./acceptance.sh | cut -d' ' -f1 | sort | uniq -c
