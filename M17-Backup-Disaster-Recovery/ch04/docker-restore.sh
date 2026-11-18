#!/bin/bash
# docker-restore.sh: รันบน prod ด้วย root กู้ WordPress stack จากโฟลเดอร์ที่ docker-backup.sh สร้าง
# ใช้: docker-restore.sh /var/backup/docker/wordpress-YYYY-MM-DD_HHMM
# ⚠️ ต้องไม่มี volume ชื่อเดียวกันอยู่ก่อน สคริปต์หยุดเองถ้าพบ เพื่อไม่เขียนทับข้อมูลที่ยังใช้งาน
set -euo pipefail
B=${1:?ระบุโฟลเดอร์ backup}
STACK=/opt/wordpress
PROJECT=wordpress
DC="docker compose --project-directory $STACK"

for v in ${PROJECT}_wp_db ${PROJECT}_wp_html; do
  if docker volume inspect "$v" >/dev/null 2>&1; then echo "volume $v ยังอยู่ หยุด"; exit 1; fi
done

# 1 ค่าตั้งของ stack
install -d -m 750 "$STACK"
cp -a "$B/compose.yaml" "$B/.env" "$STACK/"

# 2 ไฟล์ของ WordPress กลับเข้า volume ใหม่
docker volume create ${PROJECT}_wp_html >/dev/null
docker run --rm -v ${PROJECT}_wp_html:/data -v "$B":/backup:ro alpine \
  tar -xzf /backup/wp_html.tar.gz -C /data

# 3 เปิดเฉพาะฐานข้อมูล รอให้พร้อม แล้วนำ dump เข้า
$DC up -d db
until $DC exec -T db sh -c 'mariadb -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" -e "SELECT 1" "$MARIADB_DATABASE"' >/dev/null 2>&1; do sleep 2; done
zstdcat "$B/db.sql.zst" | $DC exec -T db sh -c 'mariadb -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" "$MARIADB_DATABASE"'

# 4 เปิดทั้ง stack
$DC up -d
$DC ps --format '{{.Service}} {{.Status}}'
