#!/usr/bin/env bash
# Production และการแก้ปัญหา
# SysAdmin Pocket Series M07 Database Server: MySQL & PostgreSQL
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── บัญชีผู้ดูแลเข้าได้จากในเครื่องเท่านั้น ─────────────────
sudo mariadb -e "SELECT User, Host FROM mysql.user WHERE User = 'root';"
sudo grep -E "^host.*postgres" /var/lib/pgsql/data/pg_hba.conf

# ── TLS ของ MariaDB ─────────────────────────────────────────
sudo mariadb -e "SHOW GLOBAL STATUS LIKE 'Ssl_server_not_%';"
sudo mariadb -e "ALTER USER 'shopapp'@'192.168.56.%' REQUIRE SSL;"
# บนเครื่อง db2
mariadb -h 192.168.56.40 -u shopapp -pShop-App-2569 -e "status" | grep -E "SSL|Connection:"
# บนเครื่อง db2
mariadb -h 192.168.56.40 -u shopapp -pShop-App-2569 --skip-ssl -e "SELECT 1"

# ── TLS ของ PostgreSQL ──────────────────────────────────────
sudo dnf install -y openssl
sudo -u postgres openssl req -new -x509 -days 3650 -nodes -subj "/CN=db1" -addext "subjectAltName=IP:192.168.56.40" -keyout /var/lib/pgsql/data/server.key -out /var/lib/pgsql/data/server.crt 2>/dev/null
sudo -u postgres psql -c "ALTER SYSTEM SET ssl = on" -c "SELECT pg_reload_conf()"
sudo -u postgres psql -c "SELECT pg_reload_conf()"
# บนเครื่อง db2
export PGPASSWORD=Shop-App-2569
# บนเครื่อง db2
psql "host=192.168.56.40 dbname=shop user=shopapp sslmode=disable" -c "select 1"
# บนเครื่อง db2
psql "host=192.168.56.40 dbname=shop user=shopapp" -c "SELECT ssl, version, cipher FROM pg_stat_ssl WHERE pid = pg_backend_pid();"
# บนเครื่อง db2
psql "host=192.168.56.40 dbname=shop user=shopapp sslmode=verify-full" -c "select 1"
sudo cat /var/lib/pgsql/data/server.crt > /tmp/db1-root.crt
scp -P 2222 /tmp/db1-root.crt admin@192.168.56.41:/tmp/
# บนเครื่อง db2
mkdir -p ~/.postgresql && cp /tmp/db1-root.crt ~/.postgresql/root.crt
# บนเครื่อง db2
psql "host=192.168.56.40 dbname=shop user=shopapp sslmode=verify-full" -c "SELECT ssl, version FROM pg_stat_ssl WHERE pid = pg_backend_pid();"
# บนเครื่อง db2
sudo systemctl restart postgresql
sudo -u postgres psql -c "SELECT a.application_name, a.client_addr, s.ssl, s.version FROM pg_stat_ssl s JOIN pg_stat_activity a USING (pid) WHERE a.backend_type = 'walsender';"

# ── บันทึกว่าใครทำอะไร ──────────────────────────────────────
sudo systemctl restart mariadb
sudo tail -9 /var/log/mariadb/audit.log
sudo -u postgres psql -c "ALTER SYSTEM SET log_connections = 'on'" -c "ALTER SYSTEM SET log_disconnections = on" -c "ALTER SYSTEM SET log_statement = 'ddl'" -c "SELECT pg_reload_conf()"
sudo sh -c "tail -14 /var/lib/pgsql/data/log/postgresql-*.log"

# ── 3.2 Monitoring ──────────────────────────────────────────
sudo mariadb -e "SHOW PROCESSLIST; SHOW GLOBAL STATUS WHERE Variable_name IN ('Threads_connected','Threads_running','Questions','Slow_queries','Aborted_connects','Uptime');"
sudo -u postgres psql -d shop -c "SELECT pid, usename, client_addr, state, now() - query_start AS running_for, left(query, 40) AS query FROM pg_stat_activity WHERE backend_type = 'client backend';"
sudo -u postgres psql -d shop -c "SELECT relname, n_live_tup, n_dead_tup, last_autovacuum, last_autoanalyze FROM pg_stat_user_tables ORDER BY n_dead_tup DESC;"
sudo -u postgres psql -c "SELECT datname, pg_size_pretty(pg_database_size(datname)) AS size FROM pg_database ORDER BY pg_database_size(datname) DESC;"

# ── VACUUM ของ PostgreSQL ───────────────────────────────────
sudo -u postgres psql -d shop -c "UPDATE app.orders SET qty = qty + 1 WHERE id <= 200000;" -c "SELECT relname, n_live_tup, n_dead_tup, pg_size_pretty(pg_total_relation_size('app.orders')) AS size FROM pg_stat_user_tables WHERE relname = 'orders';"
sudo -u postgres psql -d shop -c "VACUUM (ANALYZE, VERBOSE) app.orders;" 2>&1 | grep -E "tuples:|elapsed"
sudo -u postgres psql -d shop -c "SELECT relname, n_live_tup, n_dead_tup, pg_size_pretty(pg_total_relation_size('app.orders')) AS size FROM pg_stat_user_tables WHERE relname = 'orders';"

# ── OPTIMIZE TABLE ของ MariaDB ──────────────────────────────
sudo mariadb -e "SELECT ROUND((data_length+index_length)/1024/1024,1) AS mb, ROUND(data_free/1024/1024,1) AS free_mb FROM information_schema.tables WHERE table_schema='shop' AND table_name='orders';
  DELETE FROM shop.orders WHERE id > 100000;
  OPTIMIZE TABLE shop.orders;"
sudo mariadb -e "SELECT ROUND((data_length+index_length)/1024/1024,1) AS mb, ROUND(data_free/1024/1024,1) AS free_mb FROM information_schema.tables WHERE table_schema='shop' AND table_name='orders';"

# ── script บำรุงรักษาประจำสัปดาห์ ───────────────────────────
sudo chmod 700 /usr/local/bin/db-maintenance.sh
echo "0 3 * * 0 root /usr/local/bin/db-maintenance.sh" | sudo tee /etc/cron.d/db-maintenance
sudo /usr/local/bin/db-maintenance.sh
sudo cat /var/log/db-maintenance.log
# บนเครื่อง db2
sudo cat /var/log/db-maintenance.log

# ── เชื่อมต่อไม่ได้ ─────────────────────────────────────────
# บนเครื่อง db2
mariadb -h 192.168.56.40 -u shopapp -pShop-App-2569 -e "select 1"
# บนเครื่อง db2
psql "host=192.168.56.40 dbname=shop user=shopapp" -c "select 1"

# ── การเชื่อมต่อเต็ม ────────────────────────────────────────
sudo mariadb -e "SET GLOBAL max_connections = 3; SHOW WARNINGS; SELECT @@max_connections;"
for i in $(seq 1 12); do (mariadb -h 192.168.56.40 -u shopapp -pShop-App-2569 -e "SELECT SLEEP(6)" >/dev/null 2>&1 &); done
mariadb -h 192.168.56.40 -u shopapp -pShop-App-2569 -e "SELECT 1"
sudo mariadb -e "SELECT 'root still works'"
sudo mariadb -e "SET GLOBAL max_connections = 200"
psql "host=192.168.56.40 dbname=shop user=shopapp" -c "select 1"

# ── replica หยุดตาม ─────────────────────────────────────────
# บนเครื่อง db2
sudo mariadb -e "SHOW SLAVE STATUS\G" | grep -E "Slave_IO_Running|Slave_SQL_Running:|Seconds_Behind|Last_IO_Error"

# ── ดิสก์เต็มจาก log ของ replication ────────────────────────
sudo mariadb -e "SELECT @@binlog_expire_logs_seconds, @@expire_logs_days;"
# บนเครื่อง db2
sudo systemctl stop postgresql
sudo -u postgres psql -d shop -c "UPDATE app.orders SET qty = qty + 1;" -c "UPDATE app.orders SET qty = qty - 1;" -c "SELECT slot_name, active, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS retained FROM pg_replication_slots;"
sudo -u postgres psql -c "ALTER SYSTEM SET max_slot_wal_keep_size = '2GB'" -c "SELECT pg_reload_conf()" -c "SHOW max_slot_wal_keep_size"
