#!/usr/bin/env bash
# backup-database.sh  dump ทุกฐานข้อมูลของ MariaDB/MySQL หรือ PostgreSQL แล้วบีบอัด
# ---- ตัวแปรที่ต้องแก้ ----
DB_TYPE=mariadb                            # mariadb หรือ postgres
DEST=/backup/db
KEEP_DAYS=7
# shellcheck source=/usr/local/lib/sysadmin/lib.sh
source /usr/local/lib/sysadmin/lib.sh
need_root; lock

mkdir -p "$DEST"
file="$DEST/$DB_TYPE-$(hostname -s)-$(date +%Y%m%d-%H%M).sql.gz"
case $DB_TYPE in
  mariadb)  need_cmd mysqldump
            mysqldump --all-databases --single-transaction --routines --events \
              | gzip > "$TMP_DIR/dump.gz" ;;
  postgres) need_cmd pg_dumpall
            (cd / && runuser -u postgres -- pg_dumpall) | gzip > "$TMP_DIR/dump.gz" ;;
  *)        die "DB_TYPE ต้องเป็น mariadb หรือ postgres" ;;
esac
gzip -t "$TMP_DIR/dump.gz" || die "ไฟล์ dump เสีย"
mv "$TMP_DIR/dump.gz" "$file"
ok "dump $DB_TYPE ได้ $file ขนาด $(du -h "$file" | cut -f1)"

deleted=$(find "$DEST" -name "$DB_TYPE-*.sql.gz" -mtime +"$KEEP_DAYS" -print -delete | wc -l)
log "ลบ dump ที่เก่ากว่า $KEEP_DAYS วัน $deleted ไฟล์"
