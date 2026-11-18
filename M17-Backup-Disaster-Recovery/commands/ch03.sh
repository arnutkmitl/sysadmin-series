#!/usr/bin/env bash
# บทที่ 3 Backup ฐานข้อมูล MariaDB และ PostgreSQL
# SysAdmin Pocket Series M17 Backup & Disaster Recovery
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── Lab 3.1 dump และกู้ลงฐานใหม่ ────────────────────────────
# บนเครื่อง prod
sudo /usr/local/sbin/db-dump.sh
sudo install -m 644 binlog.cnf /etc/my.cnf.d/ && sudo systemctl restart mariadb
sudo install -m 750 db-dump.sh /usr/local/sbin/ && sudo /usr/local/sbin/db-dump.sh
sudo bash -c 'zstdcat /var/backup/db/shop-*.sql.zst | grep -E "CHANGE MASTER|^CREATE DATABASE"'
sudo mariadb -e "CREATE DATABASE shop_test"
sudo bash -c 'f=$(ls /var/backup/db/shop-*.sql.zst | tail -1); zstdcat $f | sed "/^CREATE DATABASE/d; s/^USE \`shop\`;/USE \`shop_test\`;/" | mariadb shop_test'
sudo mariadb -t -e "SELECT 'shop' AS db, COUNT(*) AS orders FROM shop.orders UNION ALL SELECT 'shop_test', COUNT(*) FROM shop_test.orders; CHECKSUM TABLE shop.orders, shop_test.orders"
sudo mariadb -e "DROP DATABASE shop_test"

# ── 3.2 mariadb-backup แบบ full และ incremental ─────────────
# บนเครื่อง prod
sudo dnf -y install mariadb-backup
B=/var/backup/mariabackup; sudo install -d -m 700 $B
sudo mariadb-backup --backup --target-dir=$B/full 2>&1 | tail -1
sudo mariadb shop -e "INSERT INTO shop.orders (product_id, qty) SELECT 1 + (seq % 50), 2 FROM seq_1_to_200"
sudo mariadb-backup --backup --target-dir=$B/inc1 --incremental-basedir=$B/full 2>&1 | tail -1
sudo du -sh $B/full $B/inc1
sudo mariadb-backup --prepare --target-dir=$B/full 2>&1 | tail -1
sudo mariadb-backup --prepare --target-dir=$B/full --incremental-dir=$B/inc1 2>&1 | tail -1
# ⚠️ copy-back ต้องการ datadir ที่ว่าง คำสั่งชุดนี้หยุด MariaDB และย้าย datadir เดิมออก ระหว่างนั้นทุกแอปที่ใช้ฐานจะหยุดทำงาน
sudo systemctl stop mariadb
sudo mv /var/lib/mysql /var/lib/mysql.broken
sudo mariadb-backup --copy-back --target-dir=$B/full 2>&1 | tail -1
sudo chown -R mysql:mysql /var/lib/mysql && sudo restorecon -R /var/lib/mysql
sudo systemctl start mariadb
sudo mariadb -e "SELECT COUNT(*) AS orders_after_restore FROM shop.orders"
ls -ldZ /var/lib/mysql

# ── Lab 3.2 ลบตารางผิดแล้วกู้ถึงวินาทีก่อนลบ ────────────────
# บนเครื่อง prod
for i in 1 2 3 4 5; do sudo mariadb -e "INSERT INTO shop.orders (product_id, qty) VALUES ($i, 9)"; done
sudo mariadb -e "SELECT COUNT(*) AS orders_before_mistake FROM shop.orders"
sudo mariadb -e "DROP TABLE shop.orders"
sudo mariadb-binlog --start-position=481 /var/lib/mysql/binlog.000001 | grep -n -E "^# at |DROP TABLE" | tail -3
for p in mariadb mariadb-dump mariadb-binlog; do printf "%-15s " $p; $p --print-defaults; done
sudo mariadb-binlog --start-position=481 /var/lib/mysql/binlog.000001 | grep -n "DROP TABLE \`shop\`"
sudo mariadb-binlog --start-position=481 /var/lib/mysql/binlog.000001 | sed -n "1673,1683p"
# ⚠️ การนำ dump เข้าฐาน shop เขียนทับตารางทั้งหมดในฐานนั้น ให้หยุดแอปที่เขียนลงฐานก่อน และ dump สภาพปัจจุบันเก็บไว้อีกชุดเผื่อต้องย้อน
sudo bash -c 'f=$(ls /var/backup/db/shop-*.sql.zst | tail -1); zstdcat $f | mariadb --init-command="SET sql_log_bin=0"'
sudo mariadb -e "SELECT COUNT(*) AS after_dump FROM shop.orders"
sudo mariadb-binlog --database=shop --start-position=481 --stop-position=59653 /var/lib/mysql/binlog.000001 | sudo mariadb --init-command="SET sql_log_bin=0"
sudo mariadb -t -e "SELECT COUNT(*) AS after_pitr FROM shop.orders; SELECT id, product_id, qty FROM shop.orders ORDER BY id DESC LIMIT 2"

# ── pg_dump และ pg_restore ──────────────────────────────────
# บนเครื่อง prod
sudo -u postgres pg_restore -l /var/backup/db/ledger-2026-11-18_0639.dump
sudo bash -c 'f=$(ls /var/backup/db/ledger-*.dump | tail -1); sudo -u postgres pg_restore -l < $f' | grep -E "TABLE " | head -2
sudo -u postgres createdb ledger_test
sudo bash -c 'f=$(ls /var/backup/db/ledger-*.dump | tail -1); sudo -u postgres pg_restore -d ledger_test < $f'
for d in ledger ledger_test; do sudo -u postgres psql -At -c "SELECT '$d', count(*), sum(amount) FROM entries" $d; done
sudo -u postgres dropdb ledger_test

# ── WAL archive และ base backup ─────────────────────────────
# บนเครื่อง prod
sudo install -d -o postgres -g postgres -m 700 /var/lib/pgsql/wal-archive /var/lib/pgsql/data/conf.d
sudo install -o postgres -g postgres -m 600 wal-archive.conf /var/lib/pgsql/data/conf.d/
echo "include_dir = 'conf.d'" | sudo tee -a /var/lib/pgsql/data/postgresql.conf
sudo restorecon -R /var/lib/pgsql && sudo systemctl restart postgresql
sudo -u postgres psql -At -c "SHOW archive_mode" -c "SHOW wal_level"
sudo install -d -o postgres -g postgres -m 700 /var/backup/pgbase
sudo -u postgres pg_basebackup -D /var/backup/pgbase/base -Ft -z -Xs -P
sudo ls /var/lib/pgsql/wal-archive

# ── Lab 3.3 ลบข้อมูลผิดแล้วกู้ถึงเวลาก่อนลบ ─────────────────
# บนเครื่อง prod
sudo -u postgres psql -At -d ledger -c "INSERT INTO entries (account_id, amount) SELECT 1, 99.99 FROM generate_series(1, 50)"
sudo -u postgres psql -At -d ledger -c "SELECT now()::timestamp(0)"
sudo -u postgres psql -At -d ledger -c "DELETE FROM entries"
sudo -u postgres psql -At -d ledger -c "SELECT pg_switch_wal()"
# ⚠️ คำสั่งชุดนี้หยุด PostgreSQL และแทนที่ datadir ทั้งก้อนด้วย base backup ให้ย้าย datadir เดิมไปเก็บไว้ ไม่ลบทิ้ง จนกว่าจะตรวจผลการกู้เสร็จ
sudo systemctl stop postgresql
sudo mv /var/lib/pgsql/data /var/lib/pgsql/data.broken
sudo install -d -o postgres -g postgres -m 700 /var/lib/pgsql/data
sudo tar -xzf /var/backup/pgbase/base/base.tar.gz -C /var/lib/pgsql/data
sudo tee /var/lib/pgsql/data/conf.d/recovery.conf <<'EOF'
restore_command = 'cp /var/lib/pgsql/wal-archive/%f %p'
recovery_target_time = '2026-11-18 06:41:40'
recovery_target_action = 'promote'
EOF
sudo touch /var/lib/pgsql/data/recovery.signal
sudo chown -R postgres:postgres /var/lib/pgsql/data && sudo restorecon -R /var/lib/pgsql/data
sudo systemctl start postgresql
sudo -u postgres psql -At -d ledger -c "SELECT count(*) FROM entries"
sudo grep -hE "restored log|stopping before|archive recovery complete" /var/lib/pgsql/data/log/*.log

# ── 3.5 สคริปต์ตรวจ backup ฐานข้อมูล ────────────────────────
# บนเครื่อง prod
sudo install -m 750 db-verify.sh /usr/local/sbin/ && sudo /usr/local/sbin/db-verify.sh
sudo bash -c 'cd /var/backup/db; f=$(ls -1t shop-*.sql.zst | head -1); head -c 1500 $f > shop-9999-broken.sql.zst'
sudo /usr/local/sbin/db-verify.sh 2>&1 | grep -v NOTICE
sudo /usr/local/sbin/db-verify.sh >/dev/null 2>&1; echo rc=$?
sudo rm /var/backup/db/shop-9999-broken.sql.zst
