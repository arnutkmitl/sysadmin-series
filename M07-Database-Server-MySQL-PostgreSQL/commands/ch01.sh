#!/usr/bin/env bash
# MariaDB: ติดตั้ง ตั้งค่า สำรองข้อมูล และ Replication
# SysAdmin Pocket Series M07 Database Server: MySQL & PostgreSQL
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 1.1 ติดตั้ง MariaDB ─────────────────────────────────────
sudo dnf install -y mariadb11.8-server
sudo systemctl enable --now mariadb
mariadb --version
sudo ss -tlnp | grep 3306
sudo firewall-cmd --list-all | grep -E "services|ports"

# ── mariadb-secure-installation ─────────────────────────────
sudo mariadb-secure-installation
mariadb -u root -e "SELECT 1"
sudo mariadb -e "SELECT VERSION(); SHOW DATABASES;"

# ── 1.2 ตั้งค่าด้วยไฟล์ใน /etc/my.cnf.d ─────────────────────
sudo systemctl restart mariadb
sudo ss -tlnp | grep 3306
sudo mariadb -e "SHOW VARIABLES WHERE Variable_name IN ('bind_address','max_connections','innodb_buffer_pool_size','character_set_server');"
# ⚠️ อย่าปล่อย bind-address ว่างหรือเป็น 0.0.0.0 บน server ที่มีการ์ดเครือข่ายต่อ Internet ถ้าวันหนึ่งมีคนเปิด port 3306 บน firewall เพื่อทดสอบแล้วลืมปิด ทุกคนบน Internet จะเริ่มเดารหัสผ่านได้ทันที ให้ผูกกับ IP ของวงภายในเท่านั้น
sudo mariadb -e "CREATE DATABASE shop; USE shop;
  CREATE TABLE products (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(100), price DECIMAL(10,2));
  INSERT INTO products (name, price) VALUES ('คีย์บอร์ด', 590.00), ('จอ 24 นิ้ว', 4290.00);
  SHOW CREATE TABLE products\G"

# ── 1.3 ผู้ใช้และสิทธิ์ ─────────────────────────────────────
sudo mariadb -B -e "CREATE USER 'shopapp'@'192.168.56.%' IDENTIFIED BY 'Shop-App-2569';
  GRANT SELECT, INSERT, UPDATE, DELETE ON shop.* TO 'shopapp'@'192.168.56.%';
  SHOW GRANTS FOR 'shopapp'@'192.168.56.%';"

# ── ทดสอบจากเครื่องอื่น ─────────────────────────────────────
# บนเครื่อง db2
sudo dnf install -y mariadb11.8-server
# บนเครื่อง db2
mariadb -h 192.168.56.40 -u shopapp -pShop-App-2569 -e "SELECT 1"
sudo firewall-cmd --permanent --add-rich-rule='rule family=ipv4 source address=192.168.56.0/24 port port=3306 protocol=tcp accept'
sudo firewall-cmd --reload
# บนเครื่อง db2
mariadb -h 192.168.56.40 -u shopapp -pShop-App-2569 -e "SELECT * FROM shop.products; SELECT CURRENT_USER(), USER();"
# บนเครื่อง db2
mariadb -h 192.168.56.40 -u shopapp -pShop-App-2569 -e "DROP TABLE shop.products"
# บนเครื่อง db2
mariadb -h 192.168.56.40 -u shopapp -pwrong -e "SELECT 1"
# บนเครื่อง db2
mariadb -h 192.168.56.40 -u root -e "SELECT 1"

# ── ถอนสิทธิ์ ───────────────────────────────────────────────
sudo mariadb -B -e "REVOKE DELETE ON shop.* FROM 'shopapp'@'192.168.56.%';
  SHOW GRANTS FOR 'shopapp'@'192.168.56.%';"
sudo mariadb -e "CREATE DATABASE wordpress;
  CREATE USER 'wpuser'@'localhost' IDENTIFIED BY 'Wp-Lab-2569';
  GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';"
mariadb -u wpuser -pWp-Lab-2569 -e "SHOW DATABASES;"

# ── logical backup ──────────────────────────────────────────
sudo mariadb shop -e "CREATE TABLE orders (id INT AUTO_INCREMENT PRIMARY KEY, product_id INT, qty INT, created_at DATETIME DEFAULT CURRENT_TIMESTAMP);
  INSERT INTO orders (product_id, qty) SELECT 1 + (seq % 2), 1 + (seq % 5) FROM seq_1_to_5000;"
sudo mkdir -p /backup/mariadb && sudo chmod 700 /backup/mariadb
sudo mariadb-dump --single-transaction --routines --triggers --events shop | gzip | sudo tee /backup/mariadb/shop-$(date +%F).sql.gz >/dev/null
sudo ls -lh /backup/mariadb/
sudo mariadb -e "CREATE DATABASE shop_restore"
sudo zcat /backup/mariadb/shop-$(date +%F).sql.gz | sudo mariadb shop_restore
sudo mariadb -e "SELECT (SELECT COUNT(*) FROM shop.orders) AS shop, (SELECT COUNT(*) FROM shop_restore.orders) AS restored;
  CHECKSUM TABLE shop.orders, shop_restore.orders;"
sudo mariadb -e "DROP DATABASE shop_restore"

# ── physical backup ─────────────────────────────────────────
sudo mariadb-backup --backup --target-dir=/backup/mariadb/full-$(date +%F) 2>&1 | tail -1
sudo mariadb-backup --prepare --target-dir=/backup/mariadb/full-$(date +%F) 2>&1 | tail -1
sudo du -sh /backup/mariadb/full-$(date +%F)
# ⚠️ คำสั่งชุดนี้ลบฐานข้อมูล shop และย้ายข้อมูลทั้ง server ออกจากที่เดิม ทำบนเครื่องทดลองเท่านั้น บน server จริง ให้ restore ลงเครื่องอื่นก่อนทุกครั้ง
sudo mariadb -e "DROP DATABASE shop"
sudo systemctl stop mariadb
sudo mv /var/lib/mysql /var/lib/mysql.broken
sudo mariadb-backup --copy-back --target-dir=/backup/mariadb/full-$(date +%F) 2>&1 | tail -1
sudo chown -R mysql:mysql /var/lib/mysql
sudo restorecon -R /var/lib/mysql
sudo systemctl start mariadb
sudo mariadb -e "SELECT COUNT(*) FROM shop.orders;"

# ── script สำรองข้อมูลอัตโนมัติ ─────────────────────────────
sudo chmod 700 /usr/local/bin/backup-mariadb.sh
sudo /usr/local/bin/backup-mariadb.sh
sudo cat /var/log/backup-mariadb.log
echo "30 2 * * * root /usr/local/bin/backup-mariadb.sh" | sudo tee /etc/cron.d/backup-mariadb

# ── ตั้งค่า master (db1) ────────────────────────────────────
sudo systemctl restart mariadb
sudo mariadb -e "CREATE USER 'repl'@'192.168.56.41' IDENTIFIED BY 'Repl-Lab-2569';
  GRANT REPLICATION SLAVE ON *.* TO 'repl'@'192.168.56.41';
  SHOW MASTER STATUS;"
sudo mariadb-dump --all-databases --single-transaction --master-data=2 --gtid --routines --triggers --events > /tmp/full.sql
grep "^-- SET GLOBAL gtid_slave_pos" /tmp/full.sql
scp -P 2222 /tmp/full.sql admin@192.168.56.41:/tmp/

# ── ตั้งค่า replica (db2) ───────────────────────────────────
# บนเครื่อง db2
sudo systemctl enable --now mariadb
# บนเครื่อง db2
sudo mariadb < /tmp/full.sql
# บนเครื่อง db2
sudo mariadb -e "FLUSH PRIVILEGES"
# บนเครื่อง db2
sudo mariadb -e "SET GLOBAL gtid_slave_pos = '0-1-51';
  CHANGE MASTER TO MASTER_HOST='192.168.56.40', MASTER_USER='repl',
    MASTER_PASSWORD='Repl-Lab-2569', MASTER_USE_GTID=slave_pos;
  START SLAVE;"
# บนเครื่อง db2
sudo mariadb -e "SHOW SLAVE STATUS\G" | grep -E "Slave_IO_State|Master_Host|Slave_IO_Running|Slave_SQL_Running:|Seconds_Behind|Last_IO_Error|Last_SQL_Error|Using_Gtid|Gtid_IO_Pos"
# บนเครื่อง db2
sudo mariadb -e "STOP SLAVE; SET GLOBAL gtid_slave_pos = '0-1-51'; START SLAVE;"

# ── ทดสอบ ───────────────────────────────────────────────────
sudo mariadb -e "INSERT INTO shop.products (name, price) VALUES ('หูฟัง', 1290.00)"
# บนเครื่อง db2
sudo mariadb -e "SELECT id, name, price FROM shop.products"
# บนเครื่อง db2
sudo firewall-cmd --permanent --add-rich-rule='rule family=ipv4 source address=192.168.56.0/24 port port=3306 protocol=tcp accept'
# บนเครื่อง db2
sudo firewall-cmd --reload
mariadb -h 192.168.56.41 -u shopapp -pShop-App-2569 -e "INSERT INTO shop.products (name, price) VALUES ('test', 1)"

# ── innodb_buffer_pool_size ─────────────────────────────────
sudo mariadb -e "SHOW GLOBAL STATUS WHERE Variable_name IN ('Innodb_buffer_pool_read_requests','Innodb_buffer_pool_reads','Innodb_buffer_pool_pages_total','Innodb_buffer_pool_pages_free');"

# ── slow query log ──────────────────────────────────────────
sudo systemctl restart mariadb
sudo mariadb shop -e "INSERT INTO orders (product_id, qty) SELECT 1 + (seq % 3), 1 + (seq % 5) FROM seq_1_to_495000;
  ALTER TABLE orders ADD customer_id INT;
  UPDATE orders SET customer_id = id % 50000;"
sudo mariadb -e "SET GLOBAL long_query_time = 0.1"
sudo mariadb -vvv shop -e "SELECT COUNT(*), SUM(qty) FROM orders WHERE customer_id = 1234;" | grep "in set"
sudo grep -E "Query_time|^SELECT" /var/log/mariadb/slow.log

# ── EXPLAIN ─────────────────────────────────────────────────
sudo mariadb shop -e "EXPLAIN SELECT COUNT(*), SUM(qty) FROM orders WHERE customer_id = 1234;"
sudo mariadb shop -e "CREATE INDEX idx_customer ON orders (customer_id);"
sudo mariadb shop -e "EXPLAIN SELECT COUNT(*), SUM(qty) FROM orders WHERE customer_id = 1234;"
sudo mariadb -vvv shop -e "SELECT COUNT(*), SUM(qty) FROM orders WHERE customer_id = 1234;" | grep "in set"
sudo mariadb -e "SET GLOBAL long_query_time = 1"

# ── กล่อง Ubuntu ────────────────────────────────────────────
sudo apt install -y mariadb-server mariadb-backup
grep -vE "^\s*#|^\s*$" /etc/mysql/mariadb.conf.d/50-server.cnf
sudo ufw allow from 192.168.56.0/24 to any port 3306 proto tcp

# ── ถ้าใช้ MySQL 8.4 ────────────────────────────────────────
sudo mysql -e "CHANGE MASTER TO MASTER_HOST='192.168.56.40'"
sudo mysql -e "SHOW SLAVE STATUS"
