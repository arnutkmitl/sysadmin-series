#!/bin/bash
# db-dump.sh: รันบน prod ด้วย root dump ฐาน shop (MariaDB) และ ledger (PostgreSQL) ไว้ที่ /var/backup/db
# ไฟล์ dump ถูกส่งออกจากเครื่องโดย borg-backup.sh และ restic-backup.sh ในรอบถัดไป
set -euo pipefail
umask 077
OUT=/var/backup/db
KEEP_DAYS=7
now=$(date +%F_%H%M%S)
mkdir -p "$OUT"

# --single-transaction อ่านตาราง InnoDB จาก snapshot เดียวโดยไม่ล็อกตาราง
# --master-data=2 จดตำแหน่ง binlog ไว้เป็น comment สำหรับ Point-in-Time Recovery
mariadb-dump --single-transaction --master-data=2 --routines --triggers --events \
     --databases shop | zstd -q -o "$OUT/shop-$now.sql.zst"

# -Fc คือ custom format ใช้กับ pg_restore ได้ทั้งฐานหรือเลือกเฉพาะตาราง
sudo -u postgres pg_dump -Fc ledger > "$OUT/ledger-$now.dump"

find "$OUT" -type f -mtime +"$KEEP_DAYS" -delete
ls -l "$OUT"
