#!/usr/bin/env bash
# PostgreSQL: ติดตั้ง ตั้งค่า สำรองข้อมูล และ Streaming Replication
# SysAdmin Pocket Series M07 Database Server: MySQL & PostgreSQL
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 2.1 ติดตั้ง PostgreSQL ──────────────────────────────────
sudo dnf install -y postgresql18-server
sudo systemctl start postgresql
sudo postgresql-setup --initdb
sudo systemctl enable --now postgresql
sudo ss -tlnp | grep 5432

# ── เข้า psql ───────────────────────────────────────────────
sudo -u postgres psql -c "SELECT version();"
sudo -u postgres psql -c "\du"
psql -U postgres -c "select 1"

# ── listen_addresses ────────────────────────────────────────
sudo -u postgres psql -c "ALTER SYSTEM SET listen_addresses = 'localhost, 192.168.56.40'"
sudo cat /var/lib/pgsql/data/postgresql.auto.conf
sudo systemctl restart postgresql
sudo ss -tlnp | grep 5432

# ── pg_hba.conf คือ firewall ของ PostgreSQL ─────────────────
sudo grep -vE "^\s*#|^\s*$" /var/lib/pgsql/data/pg_hba.conf
psql -h 127.0.0.1 -U tester -d postgres -c "select 1"
sudo -u postgres cp /var/lib/pgsql/data/pg_hba.conf /var/lib/pgsql/data/pg_hba.conf.orig
# ⚠️ trust ทำให้ใครก็ตามที่เชื่อมต่อได้ตามเงื่อนไขของบรรทัดนั้นเข้าเป็น role ใดก็ได้ รวมถึง postgres ซึ่งเป็น superuser บทความแก้ปัญหาหลายแห่งแนะนำให้เปลี่ยนเป็น trust ชั่วคราว ถ้าจำเป็นจริง ให้ใช้กับ local เท่านั้นและเปลี่ยนกลับทันที
sudo -u postgres psql -c "SELECT pg_reload_conf()"
sudo -u postgres psql -c "SELECT line_number, type, database, user_name, address, auth_method, error FROM pg_hba_file_rules"
sudo firewall-cmd --permanent --add-rich-rule='rule family=ipv4 source address=192.168.56.0/24 port port=5432 protocol=tcp accept'
sudo firewall-cmd --reload

# ── 2.3 Role และสิทธิ์ ──────────────────────────────────────
sudo -u postgres psql < roles.sql
sudo -u postgres psql -d shop -c "\dp app.*"
sudo -u postgres psql -d shop -c "SET ROLE shopowner;
  CREATE TABLE app.orders (id bigserial PRIMARY KEY, product_id int REFERENCES app.products(id), qty int NOT NULL, created_at timestamptz DEFAULT now());
  RESET ROLE;" -c "\dp app.orders"

# ── ทดสอบจาก db2 ────────────────────────────────────────────
# บนเครื่อง db2
sudo dnf install -y postgresql18-server
# บนเครื่อง db2
export PGPASSWORD=Shop-App-2569
# บนเครื่อง db2
psql -h 192.168.56.40 -U shopapp -d shop -c "INSERT INTO app.orders (product_id, qty) VALUES (1, 2) RETURNING *;"
# บนเครื่อง db2
psql -h 192.168.56.40 -U shopapp -d shop -c "DELETE FROM app.products;"
# บนเครื่อง db2
psql -h 192.168.56.40 -U shopapp -d postgres -c "select 1"
PGPASSWORD=Report-2569 psql -U reporter -d shop -c "SELECT name, price FROM app.products;" -c "INSERT INTO app.products (name) VALUES ('x');"

# ── 2.4 สำรองข้อมูล: pg_dump และ pg_basebackup ──────────────
sudo -u postgres psql -d shop -c "INSERT INTO app.orders (product_id, qty, created_at)
  SELECT 1 + (g % 2), 1 + (g % 5), now() - (g || ' minutes')::interval FROM generate_series(1, 499999) g;"
sudo -u postgres pg_dump -Fc -d shop -f /var/lib/pgsql/backups/shop-$(date +%F).dump
sudo -u postgres pg_dumpall --globals-only -f /var/lib/pgsql/backups/globals-$(date +%F).sql
sudo ls -lh /var/lib/pgsql/backups/
sudo -u postgres pg_restore -l /var/lib/pgsql/backups/shop-$(date +%F).dump | grep -E "TABLE|SCHEMA|ACL" | head -6
sudo -u postgres createdb -O shopowner shop_restore
sudo -u postgres pg_restore -d shop_restore /var/lib/pgsql/backups/shop-$(date +%F).dump
sudo -u postgres psql -d shop_restore -c "SELECT (SELECT count(*) FROM app.orders) AS orders, (SELECT count(*) FROM app.products) AS products;"
sudo -u postgres dropdb shop_restore

# ── primary (db1) ───────────────────────────────────────────
sudo -u postgres psql -c "CREATE ROLE replicator REPLICATION LOGIN PASSWORD 'Repl-Lab-2569'"
echo "host    replication     replicator      192.168.56.41/32        scram-sha-256" | sudo -u postgres tee -a /var/lib/pgsql/data/pg_hba.conf
sudo -u postgres psql -c "SELECT pg_reload_conf()"

# ── standby (db2) ───────────────────────────────────────────
# บนเครื่อง db2
sudo -u postgres env PGPASSWORD=Repl-Lab-2569 pg_basebackup -h 192.168.56.40 -U replicator -D /var/lib/pgsql/data -R -P -C -S db2_slot
# บนเครื่อง db2
sudo ls /var/lib/pgsql/data | grep -E "signal|auto"
# บนเครื่อง db2
sudo cat /var/lib/pgsql/data/postgresql.auto.conf
# บนเครื่อง db2
sudo systemctl enable --now postgresql
# บนเครื่อง db2
sudo -u postgres psql -c "ALTER SYSTEM SET listen_addresses = 'localhost, 192.168.56.41'"
# บนเครื่อง db2
sudo systemctl restart postgresql
# บนเครื่อง db2
sudo ss -tlnp | grep 5432

# ── ตรวจสถานะ ───────────────────────────────────────────────
sudo -u postgres psql -c "SELECT client_addr, application_name, state, sync_state, sent_lsn, replay_lsn, replay_lag FROM pg_stat_replication;"
sudo -u postgres psql -d shop -c "INSERT INTO app.products (name, price) VALUES ('เมาส์ไร้สาย', 390.00);"
# บนเครื่อง db2
sudo -u postgres psql -d shop -c "SELECT pg_is_in_recovery();" -c "SELECT id, name, price FROM app.products ORDER BY id;" -c "INSERT INTO app.products (name) VALUES ('test');"

# ── ถ้า pg_basebackup ล้มเหลวกลางทาง ────────────────────────
# บนเครื่อง db2
sudo -u postgres env PGPASSWORD=Repl-Lab-2569 pg_basebackup -h 192.168.56.40 -U replicator -D /var/lib/pgsql/data -R -P -C -S db2_slot
sudo -u postgres psql -c "SELECT pg_drop_replication_slot('db2_slot')"

# ── 2.6 ปรับประสิทธิภาพเบื้องต้น ────────────────────────────
sudo -u postgres psql -c "ALTER SYSTEM SET shared_buffers = '512MB'" -c "ALTER SYSTEM SET effective_cache_size = '1536MB'" -c "ALTER SYSTEM SET work_mem = '16MB'" -c "ALTER SYSTEM SET maintenance_work_mem = '128MB'"
sudo systemctl restart postgresql
sudo -u postgres psql -At -c "SHOW shared_buffers" -c "SHOW effective_cache_size" -c "SHOW work_mem" -c "SHOW maintenance_work_mem"

# ── EXPLAIN ANALYZE ─────────────────────────────────────────
sudo -u postgres psql -d shop -c "ALTER TABLE app.orders ADD COLUMN customer_id int;" -c "UPDATE app.orders SET customer_id = id % 50000;" -c "VACUUM ANALYZE app.orders;"
sudo -u postgres psql -d shop -c "EXPLAIN (ANALYZE, COSTS OFF) SELECT count(*), sum(qty) FROM app.orders WHERE customer_id = 1234;"
sudo -u postgres psql -d shop -c "CREATE INDEX idx_orders_customer ON app.orders (customer_id);"
sudo -u postgres psql -d shop -c "EXPLAIN (ANALYZE, COSTS OFF) SELECT count(*), sum(qty) FROM app.orders WHERE customer_id = 1234;"

# ── กล่อง Ubuntu ────────────────────────────────────────────
sudo apt install -y postgresql
grep -vE "^\s*#|^\s*$" /etc/postgresql/18/main/pg_hba.conf
grep -E "^(ssl|ssl_cert_file|ssl_key_file)" /etc/postgresql/18/main/postgresql.conf
