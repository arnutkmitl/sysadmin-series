#!/usr/bin/env bash
# Script แรกที่ใช้ได้จริง: Health Check Server
# SysAdmin Pocket Series M03 Shell Script Automation
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 1.1 เริ่มจากงานที่ทำทุกวัน ──────────────────────────────
uptime
free -h
df -h /
systemctl --failed
ss -tln

# ── 1.2 สร้าง Script ตัวแรก ─────────────────────────────────
cd ~/scripts/labs
nano health-check.sh
chmod +x health-check.sh
./health-check.sh

# ── 1.3 ปรับให้อ่านง่ายขึ้น ─────────────────────────────────
./health-check.sh

# ── 1.5 ShellCheck ผู้ช่วยตรวจ Script ───────────────────────
shellcheck health-check.sh
echo $?
# ⚠️ ไฟล์ clean-logs.sh ข้างล่างมีไว้ให้ ShellCheck ตรวจเท่านั้น ห้ามรัน ถ้ารันโดยไม่ใส่ argument ตัวแปรจะว่าง และคำสั่ง rm จะกลายเป็นการลบทุกไฟล์ใต้ / ที่ผู้ใช้มีสิทธิ์ลบ
shellcheck clean-logs.sh
