#!/bin/bash
# db-verify.sh: รันบน prod ด้วย root กู้ dump ล่าสุดลงฐานชั่วคราว นับแถวเทียบกับฐานจริง แล้วลบฐานชั่วคราวทิ้ง
# ออกด้วยรหัส 0 เมื่อผ่านทุกข้อ 1 เมื่อมีข้อใดไม่ผ่าน (ใช้ต่อกับระบบแจ้งเตือนในบทที่ 5)
set -uo pipefail
OUT=/var/backup/db
fail=0
check() {  # check <ชื่อ> <ค่าในฐานจริง> <ค่าในฐานที่กู้>
  if [ "$2" = "$3" ] && [ -n "$3" ]; then echo "[PASS] $1 live=$2 restored=$3"
  else echo "[FAIL] $1 live=$2 restored=$3"; fail=1; fi
}

f=$(ls -1t "$OUT"/shop-*.sql.zst 2>/dev/null | head -1)
if [ -z "$f" ]; then echo "[FAIL] ไม่พบ dump ของ shop"; fail=1; else
  mariadb -e "DROP DATABASE IF EXISTS verify_shop; CREATE DATABASE verify_shop"
  zstdcat "$f" | sed '/^CREATE DATABASE/d; s/^USE `shop`;/USE `verify_shop`;/' \
    | mariadb --init-command="SET sql_log_bin=0" verify_shop
  # ฐานจริงอาจมีแถวเพิ่มหลังเวลาที่ dump จึงนับเฉพาะแถวที่สร้างก่อนเวลาของไฟล์ dump
  t=$(date -r "$f" '+%F %T')
  live=$(mariadb -N -e "SELECT COUNT(*) FROM shop.orders WHERE created_at <= '$t'")
  got=$(mariadb -N -e "SELECT COUNT(*) FROM verify_shop.orders")
  check "shop.orders ($(basename "$f"))" "$live" "$got"
  mariadb -e "DROP DATABASE verify_shop"
fi

f=$(ls -1t "$OUT"/ledger-*.dump 2>/dev/null | head -1)
if [ -z "$f" ]; then echo "[FAIL] ไม่พบ dump ของ ledger"; fail=1; else
  sudo -u postgres dropdb --if-exists verify_ledger
  sudo -u postgres createdb verify_ledger
  sudo -u postgres pg_restore -d verify_ledger < "$f"
  t=$(date -r "$f" '+%F %T')
  live=$(sudo -u postgres psql -At -d ledger -c "SELECT count(*) FROM entries WHERE created_at <= '$t'")
  got=$(sudo -u postgres psql -At -d verify_ledger -c "SELECT count(*) FROM entries")
  check "ledger.entries ($(basename "$f"))" "$live" "$got"
  sudo -u postgres dropdb verify_ledger
fi
exit $fail
