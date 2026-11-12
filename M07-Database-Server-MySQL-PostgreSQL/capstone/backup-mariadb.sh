#!/bin/bash
# สำรองทุก database ของ MariaDB แบบ logical วันละครั้ง เก็บไว้ KEEP_DAYS วัน
# รันด้วย root ผ่าน cron (root เข้า MariaDB ด้วย unix_socket ไม่ต้องใส่รหัสผ่านในไฟล์)
set -euo pipefail

BACKUP_DIR=/backup/mariadb
KEEP_DAYS=7
STAMP=$(date +%F-%H%M)
LOG=/var/log/backup-mariadb.log

mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

DBS=$(mariadb -N -e "SELECT schema_name FROM information_schema.schemata
      WHERE schema_name NOT IN ('information_schema','performance_schema','sys')")

for db in $DBS; do
    out="$BACKUP_DIR/$db-$STAMP.sql.gz"
    mariadb-dump --single-transaction --routines --triggers --events "$db" | gzip > "$out"
    echo "$(date '+%F %T') OK $db $(du -h "$out" | cut -f1)" >> "$LOG"
done

find "$BACKUP_DIR" -name '*.sql.gz' -mtime +"$KEEP_DAYS" -delete
