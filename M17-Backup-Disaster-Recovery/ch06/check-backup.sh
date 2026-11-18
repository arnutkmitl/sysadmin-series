#!/bin/bash
# check-backup.sh: รันบน prod ด้วย root ตรวจทั้งระบบ backup ในคำสั่งเดียว (โปรเจกต์จบเล่ม)
# ออกด้วยรหัส 0 เมื่อผ่านทุกข้อ ใช้หลังติดตั้งระบบใหม่ หลังกู้คืน และทุกเช้าถ้าต้องการ
set -uo pipefail
pass=0; fail=0
ok()  { echo "[PASS] $*"; pass=$((pass + 1)); }
bad() { echo "[FAIL] $*"; fail=$((fail + 1)); }
chk() { local msg=$1; shift; if "$@" >/dev/null 2>&1; then ok "$msg"; else bad "$msg"; fi; }

echo "== บริการ"
for s in nginx mariadb postgresql docker node_exporter; do chk "$s ทำงาน" systemctl is-active --quiet $s; done
chk "เว็บร้านค้าตอบ 200" curl -sf -o /dev/null http://localhost/
chk "WordPress มีบทความประกาศวันหยุดสิ้นปี" bash -c 'curl -s http://localhost:8080/ | grep -q "ประกาศวันหยุดสิ้นปี"'

echo "== ข้อมูล"
n=$(mariadb -N -e "SELECT COUNT(*) FROM shop.orders" 2>/dev/null); [ "${n:-0}" -gt 0 ] && ok "shop.orders มี $n แถว" || bad "shop.orders ว่าง"
n=$(sudo -u postgres psql -At -d ledger -c "SELECT count(*) FROM entries" 2>/dev/null); [ "${n:-0}" -gt 0 ] && ok "ledger.entries มี $n แถว" || bad "ledger.entries ว่าง"
chk "MariaDB ใช้ utf8mb4" bash -c '[ "$(mariadb -N -e "SELECT @@character_set_server")" = utf8mb4 ]'
chk "binlog เปิดอยู่" bash -c '[ "$(mariadb -N -e "SELECT @@log_bin")" = 1 ]'
chk "PostgreSQL archive_mode = on" bash -c '[ "$(sudo -u postgres psql -At -c "SHOW archive_mode")" = on ]'

echo "== งานอัตโนมัติ"
for t in backup.timer restore-test.timer; do chk "$t เปิดใช้" systemctl is-enabled --quiet $t; done
# บริการที่ยังไม่เคยรันก็รายงาน Result=success จึงต้องดูว่ามีเวลาที่จบงานจริงด้วย
chk "backup รอบล่าสุดสำเร็จ (รันแล้วหลังบูต)" bash -c '[ "$(systemctl show backup.service -p Result --value)" = success ] && [ "$(systemctl show backup.service -p ExecMainExitTimestampMonotonic --value)" != 0 ]'
prom=/var/lib/node_exporter/textfile/backup.prom
chk "ทุกงานใน backup.prom สถานะ 0" bash -c "grep '^backup_last_status' $prom && ! grep -q '^backup_last_status.* 1$' $prom"
now=$(date +%s)
oldest=$(awk '/^backup_last_success_timestamp_seconds/{print int($2)}' $prom 2>/dev/null | sort -n | head -1)
[ -n "$oldest" ] && [ $((now - oldest)) -lt 93600 ] && ok "backup สำเร็จล่าสุดไม่เกิน 26 ชั่วโมง" || bad "มีงานที่ไม่สำเร็จเกิน 26 ชั่วโมง"

echo "== ปลายทาง"
# source อยู่ใน bash -c เพื่อไม่ให้ตัวแปรของ repository หนึ่งปนกับอีกอันและตัวนับยังอยู่ใน shell หลัก
chk "restic บน rest-server มี snapshot" bash -c 'source /root/.config/restic/env && restic snapshots --no-lock latest'
chk "restic บน S3 มี snapshot" bash -c 'source /root/.config/restic/s3-env && restic snapshots --no-lock latest'
chk "Borg มี archive" bash -c 'source /root/.config/borg-env && [ -n "$(borg list --short --last 1)" ]'
chk "ฐานข้อมูลกู้จาก dump ล่าสุดได้" /usr/local/sbin/db-verify.sh

echo "ผ่าน $pass ข้อ ไม่ผ่าน $fail ข้อ"
[ "$fail" -eq 0 ]
