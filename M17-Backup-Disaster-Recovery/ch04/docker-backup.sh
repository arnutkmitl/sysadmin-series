#!/bin/bash
# docker-backup.sh: รันบน prod ด้วย root backup WordPress stack ใน /opt/wordpress ไว้ที่ /var/backup/docker
# ฐานข้อมูลใช้ dump จาก container ที่ยังทำงาน ไม่ tar volume ของ MariaDB ขณะเปิดอยู่
set -euo pipefail
umask 077
STACK=/opt/wordpress
PROJECT=wordpress
OUT=/var/backup/docker/$PROJECT-$(date +%F_%H%M%S)
mkdir -p "$OUT"

# 1 ค่าตั้งของ stack: ถ้าไม่มีไฟล์สองไฟล์นี้ volume ที่กู้มาก็ใช้ไม่ได้
cp -a "$STACK/compose.yaml" "$STACK/.env" "$OUT/"

# 2 ฐานข้อมูล: ใช้ผู้ใช้และรหัสผ่านจากตัวแปรของ container เอง
docker compose --project-directory "$STACK" exec -T db \
  sh -c 'mariadb-dump -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" --single-transaction "$MARIADB_DATABASE"' \
  | zstd -q -o "$OUT/db.sql.zst"

# 3 ไฟล์ของ WordPress (theme, plugin, uploads) จาก volume ผ่าน container ชั่วคราว แบบอ่านอย่างเดียว
docker run --rm -v ${PROJECT}_wp_html:/data:ro -v "$OUT":/backup alpine \
  tar -czf /backup/wp_html.tar.gz -C /data .

# เก็บ 7 ชุดล่าสุด
ls -1d /var/backup/docker/$PROJECT-* | head -n -7 | xargs -r rm -rf
ls -l "$OUT"
