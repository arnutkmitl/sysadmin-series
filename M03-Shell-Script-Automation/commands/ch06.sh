#!/usr/bin/env bash
# 10 Ready-Made Scripts: คัดลอกไปใช้ได้เลย
# SysAdmin Pocket Series M03 Shell Script Automation
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 6.1 ติดตั้งส่วนกลาง lib.sh ──────────────────────────────
# ⚠️ sudo ของ Rocky Linux ใช้ PATH ตามค่า secure_path ใน /etc/sudoers ซึ่งไม่มี /usr/local/bin คำสั่ง sudo server-health.sh จะได้ command not found ให้เรียกด้วย path เต็ม sudo /usr/local/bin/server-health.sh ทุกครั้ง อย่าแก้ secure_path เพื่อความสะดวก เพราะเป็นการเปิดให้โปรแกรมที่ผู้ใช้วางไว้ถูกรันด้วยสิทธิ์ root
sudo mkdir -p /usr/local/lib/sysadmin
sudo install -m 644 lib.sh /usr/local/lib/sysadmin/lib.sh
sudo install -m 755 server-health.sh /usr/local/bin/
shellcheck -x /usr/local/bin/server-health.sh

# ── Script #1 server-health.sh (ระดับง่าย) ──────────────────
sudo /usr/local/bin/server-health.sh

# ── Script #2 disk-alert.sh (ระดับง่าย) ─────────────────────
sudo /usr/local/bin/disk-alert.sh

# ── Script #3 backup-config.sh (ระดับง่าย) ──────────────────
# ⚠️ find ที่มี -delete ลบไฟล์ทันทีโดยไม่ถาม ถ้า DEST ชี้ผิดโฟลเดอร์ ไฟล์ .tar.gz อื่นที่ชื่อขึ้นต้นด้วย config- จะหายไปด้วย ทดสอบโดยลบ -delete ออกก่อน ให้ find แสดงรายชื่อไฟล์ที่จะถูกลบ ตรวจแล้วจึงใส่กลับ
sudo /usr/local/bin/backup-config.sh

# ── Script #4 backup-database.sh (ระดับกลาง) ────────────────
sudo /usr/local/bin/backup-database.sh

# ── Script #5 log-rotate-custom.sh (ระดับง่าย) ──────────────
ls /opt/myapp/logs
sudo /usr/local/bin/log-rotate-custom.sh
ls /opt/myapp/logs

# ── Script #6 user-audit.sh (ระดับกลาง) ─────────────────────
sudo /usr/local/bin/user-audit.sh

# ── Script #7 service-restart.sh (ระดับง่าย) ────────────────
sudo systemctl stop chronyd
sudo /usr/local/bin/service-restart.sh

# ── Script #8 ssl-cert-check.sh (ระดับกลาง) ─────────────────
sudo /usr/local/bin/ssl-cert-check.sh

# ── Script #9 system-update.sh (ระดับกลาง) ──────────────────
# ⚠️ REBOOT=yes ทำให้ server reboot เองหลังอัปเดต kernel หรือ glibc ทุกบริการจะหยุดราว 1 นาที ใช้กับเครื่องที่ตกลงช่วงเวลาบำรุงรักษากับผู้ใช้แล้วเท่านั้น ถ้าเห็นข้อความเตือนก่อนครบ 5 นาที ยกเลิกได้ด้วย sudo shutdown -c
sudo /usr/local/bin/system-update.sh

# ── Script #10 quick-deploy.sh (ระดับยาก) ───────────────────
# ⚠️ git reset --hard ลบการแก้ไขที่ยังไม่ commit ในโฟลเดอร์แอปทิ้งทั้งหมด โฟลเดอร์ APP_DIR ต้องเป็นสำเนาที่ deploy อย่างเดียว ห้ามแก้โค้ดในโฟลเดอร์นี้ด้วยมือ
sudo /usr/local/bin/quick-deploy.sh staging
sudo /usr/local/bin/quick-deploy.sh staging
