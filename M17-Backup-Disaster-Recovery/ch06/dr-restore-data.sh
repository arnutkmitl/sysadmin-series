#!/bin/bash
# dr-restore-data.sh: รันด้วย root บนเครื่องที่ ReaR เพิ่งกู้ระบบเสร็จ (บทที่ 6)
# ReaR คืนระบบปฏิบัติการและค่าตั้ง สคริปต์นี้คืนข้อมูลที่ local.conf ไม่ได้เก็บไว้จาก restic บน bkp
# ลำดับ: ไฟล์และ dump จาก restic -> MariaDB -> PostgreSQL -> WordPress -> ตรวจผล
set -euo pipefail
source /root/.config/restic/env
T() { date '+%T'; }

echo "$(T) 1 restic: /srv/files และ /var/backup จาก snapshot ล่าสุด"
restic restore latest --target / --include /srv/files --include /var/backup/db --include /var/backup/docker | tail -1
restorecon -R /srv/files /var/backup

echo "$(T) 2 MariaDB: ฐานว่างที่ระบบสร้างให้ตอนบูต แล้วนำ dump ล่าสุดเข้า"
systemctl is-active --quiet mariadb || systemctl start mariadb
f=$(ls -1t /var/backup/db/shop-*.sql.zst | head -1)
zstdcat "$f" | mariadb
echo "   $f -> shop.orders=$(mariadb -N -e 'SELECT COUNT(*) FROM shop.orders')"

echo "$(T) 3 PostgreSQL: initdb ใหม่ คืนค่า WAL archive แล้วนำ dump เข้า"
if [ ! -f /var/lib/pgsql/data/PG_VERSION ]; then
  postgresql-setup --initdb
  install -d -o postgres -g postgres -m 700 /var/lib/pgsql/data/conf.d /var/lib/pgsql/wal-archive
  install -o postgres -g postgres -m 600 /root/dr/wal-archive.conf /var/lib/pgsql/data/conf.d/
  echo "include_dir = 'conf.d'" >> /var/lib/pgsql/data/postgresql.conf
  restorecon -R /var/lib/pgsql
fi
systemctl start postgresql
f=$(ls -1t /var/backup/db/ledger-*.dump | head -1)
sudo -u postgres createdb ledger
sudo -u postgres pg_restore -d ledger < "$f"
echo "   $f -> ledger.entries=$(sudo -u postgres psql -At -d ledger -c 'SELECT count(*) FROM entries')"

echo "$(T) 4 WordPress: รอ Docker แล้วกู้ stack จาก backup ล่าสุด"
systemctl is-active --quiet docker || systemctl start docker
b=$(ls -1dt /var/backup/docker/wordpress-* | head -1)
/usr/local/sbin/docker-restore.sh "$b" | tail -2

echo "$(T) 5 เสร็จ"
