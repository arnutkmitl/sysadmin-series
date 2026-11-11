#!/usr/bin/env bash
# Error Handling และ Logging: Script ระดับ Production
# SysAdmin Pocket Series M03 Shell Script Automation
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 4.1 set -euo pipefail ───────────────────────────────────
# ⚠️ Script ที่ไม่มี set -e จะทำงานต่อหลังคำสั่งล้มเหลว คำสั่งลบไฟล์หรือเขียนทับที่อยู่บรรทัดถัดไปจึงทำงานกับข้อมูลผิดชุดได้ ใส่ set -euo pipefail ทุก Script ที่มี rm, mv หรือการเขียนไฟล์
./no-safety.sh
./with-safety.sh
echo $?
bash -uc 'BACKUP_DIR=/backup; echo "เก็บที่ $BACKUP_DRI"'

# ── 4.2 Exit code ภาษากลางของ Script ────────────────────────
ls /etc/hostname; echo "exit=$?"
ls /nofile 2>/dev/null; echo "exit=$?"
./backup.sh || echo "backup ล้ม" | mailx -s "backup failed" admin@example.lan

# ── 4.3 trap ดักจับก่อนจบ ───────────────────────────────────
./trap-demo.sh
echo $?

# ── 4.4 Logging บันทึกทุกอย่างที่ Script ทำ ─────────────────
grep -h '\[WARN\]\|\[ERROR\]' /var/log/scripts/*.log | tail -3
sudo tee /etc/logrotate.d/scripts > /dev/null <<'EOF'
/var/log/scripts/*.log {
    weekly
    rotate 8
    compress
    missingok
    notifempty
}
EOF
sudo logrotate -d /etc/logrotate.d/scripts 2>&1 | grep -m2 rotating

# ── 4.5 Template Script ระดับ Production ────────────────────
sudo ./template.sh
./template.sh
sudo cat /var/log/scripts/template.log
