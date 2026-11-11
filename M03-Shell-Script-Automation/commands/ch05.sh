#!/usr/bin/env bash
# Cron และ systemd Timer: ตั้งเวลาให้ Script ทำงานเอง
# SysAdmin Pocket Series M03 Shell Script Automation
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 5.1 Cron ตัวตั้งเวลาคลาสสิก ─────────────────────────────
# ⚠️ crontab -r ลบตาราง cron ของคุณทั้งหมดทันทีโดยไม่ถาม ตัว r อยู่ติดกับตัว e บนแป้นพิมพ์ จึงพิมพ์พลาดได้ง่าย สำรองไว้ก่อนแก้ทุกครั้งด้วย crontab -l > ~/crontab.bak cronie รุ่นที่มากับ Rocky Linux 10 เก็บสำเนาล่าสุดไว้ที่ ~/.cache/crontab/crontab.bak ให้อีกชั้น
EDITOR=nano crontab -e
crontab -l

# ── 5.2 กับดักของ Cron ──────────────────────────────────────
cat /tmp/cron-env.txt
sudo grep CMDOUT /var/log/cron | tail -1

# ── 5.3 System Cron และ /etc/cron.d/ ────────────────────────
sudo tee /etc/cron.d/backup > /dev/null <<'EOF'
PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
0 2 * * * root /usr/local/bin/backup-config.sh >> /var/log/scripts/cron.log 2>&1
0 3 * * * root /usr/local/bin/backup-database.sh >> /var/log/scripts/cron.log 2>&1
EOF
ls /etc/cron.d/

# ── 5.4 systemd Timer ───────────────────────────────────────
sudo tee /etc/systemd/system/backup-config.service > /dev/null <<'EOF'
[Unit]
Description=Backup /etc
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup-config.sh
EOF
sudo tee /etc/systemd/system/backup-config.timer > /dev/null <<'EOF'
[Unit]
Description=Backup /etc ทุกวันตี 2

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true
RandomizedDelaySec=5min

[Install]
WantedBy=timers.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now backup-config.timer
systemctl list-timers backup-config.timer
sudo systemctl start backup-config.service
journalctl -u backup-config.service --since today
systemd-analyze calendar "Mon..Fri 08:30" --iterations=2

# ── Lab 5.2 systemd Timer สำหรับ Backup ─────────────────────
sudo systemctl start backup-config.service
journalctl -u backup-config.service --no-pager | tail -5
