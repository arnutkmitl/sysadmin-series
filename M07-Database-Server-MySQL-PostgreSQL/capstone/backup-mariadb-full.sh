#!/bin/bash
# physical backup ทั้ง server ด้วย mariadb-backup สัปดาห์ละครั้ง prepare ทันทีให้พร้อม restore
# เก็บไว้ KEEP_WEEKS ชุด รันด้วย root ผ่าน cron
set -euo pipefail

BACKUP_DIR=/backup/mariadb
KEEP_WEEKS=4
TARGET="$BACKUP_DIR/full-$(date +%F)"
LOG=/var/log/backup-mariadb.log

mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"
rm -rf "$TARGET"

if mariadb-backup --backup --target-dir="$TARGET" >"$TARGET.log" 2>&1 &&
   mariadb-backup --prepare --target-dir="$TARGET" >>"$TARGET.log" 2>&1; then
    echo "$(date '+%F %T') OK full $(du -sh "$TARGET" | cut -f1)" >> "$LOG"
else
    echo "$(date '+%F %T') FAILED full, see $TARGET.log" >> "$LOG"
    exit 1
fi

# ลบชุดที่เก่ากว่า KEEP_WEEKS สัปดาห์
find "$BACKUP_DIR" -maxdepth 1 -name 'full-*' -mtime +$((KEEP_WEEKS * 7)) -exec rm -rf {} +
