#!/bin/bash
# seed-prod.sh: สร้างระบบ production ตัวอย่างของเล่ม M17 บนเครื่อง prod (Rocky Linux 10)
# เว็บ Nginx ที่ /srv/www, ไฟล์ของผู้ใช้ที่ /srv/files, MariaDB ฐาน shop, PostgreSQL ฐาน ledger
# รันครั้งเดียวด้วย sudo บนเครื่องที่ติดตั้ง Minimal ใหม่ (Docker และ WordPress อยู่ในบทที่ 4)
set -euo pipefail

dnf -y -q install nginx mariadb-server postgresql-server tar rsync zstd policycoreutils-python-utils

# เว็บไซต์
mkdir -p /srv/www/shop
cat > /srv/www/shop/index.html <<'HTML'
<!doctype html><meta charset="utf-8"><title>Shop</title><h1>ร้านค้าตัวอย่างของ M17</h1>
HTML
cat > /etc/nginx/conf.d/shop.conf <<'CONF'
server {
    listen 80 default_server;
    root /srv/www/shop;
}
CONF
sed -i '/listen       80;/,/^    }/{/listen/d}' /etc/nginx/nginx.conf 2>/dev/null || true
semanage fcontext -a -t httpd_sys_content_t "/srv/www(/.*)?" 2>/dev/null || true
restorecon -R /srv/www
systemctl enable --now nginx
firewall-cmd -q --add-service=http --permanent && firewall-cmd -q --reload

# ไฟล์ของผู้ใช้: เอกสารข้อความ 300 ไฟล์ และไฟล์ binary 20 ไฟล์ ไฟล์ละ 1 MB
for d in sales hr it; do mkdir -p /srv/files/$d; done
for i in $(seq -w 1 100); do
  for d in sales hr it; do
    printf 'เอกสาร %s เลขที่ %s\nสร้างโดย seed-prod.sh\n' "$d" "$i" > /srv/files/$d/doc-$i.txt
    seq 1 400 | sed "s/^/บรรทัด $d-$i /" >> /srv/files/$d/doc-$i.txt
  done
done
for i in $(seq -w 1 20); do head -c 1M /dev/urandom > /srv/files/it/image-$i.bin; done

# MariaDB: ตั้งชุดอักขระเริ่มต้นเป็น utf8mb4 ทั้งเซิร์ฟเวอร์ (MariaDB 10.11 ของ Rocky เริ่มต้นเป็น latin1) แล้วสร้างฐาน shop
cat > /etc/my.cnf.d/utf8mb4.cnf <<'CNF'
[mariadbd]
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# ใส่เฉพาะโปรแกรมที่รู้จักตัวเลือกนี้ ถ้าใส่ใน [client] mariadb-binlog จะหยุดด้วย unknown variable
[mariadb-client]
default-character-set = utf8mb4

[mariadb-dump]
default-character-set = utf8mb4
CNF
systemctl enable mariadb
systemctl restart mariadb
mariadb <<'SQL'
CREATE DATABASE IF NOT EXISTS shop;
USE shop;
CREATE TABLE IF NOT EXISTS products (id INT PRIMARY KEY AUTO_INCREMENT, name VARCHAR(80), price DECIMAL(10,2));
CREATE TABLE IF NOT EXISTS orders (id INT PRIMARY KEY AUTO_INCREMENT, product_id INT, qty INT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP, FOREIGN KEY (product_id) REFERENCES products(id));
INSERT INTO products (name, price)
  SELECT CONCAT('สินค้า ', seq), ROUND(50 + seq * 7.5, 2) FROM seq_1_to_50;
INSERT INTO orders (product_id, qty)
  SELECT 1 + (seq % 50), 1 + (seq % 5) FROM seq_1_to_1000;
SQL

# PostgreSQL: ฐาน ledger
[ -f /var/lib/pgsql/data/PG_VERSION ] || postgresql-setup --initdb
systemctl enable --now postgresql
sudo -u postgres psql -q <<'SQL'
CREATE DATABASE ledger;
\c ledger
CREATE TABLE accounts (id serial PRIMARY KEY, name text NOT NULL);
CREATE TABLE entries (id serial PRIMARY KEY, account_id int REFERENCES accounts(id),
  amount numeric(12,2), created_at timestamptz DEFAULT now());
INSERT INTO accounts (name) SELECT 'บัญชี ' || g FROM generate_series(1, 20) g;
INSERT INTO entries (account_id, amount) SELECT 1 + g % 20, (g % 97) * 10.5 FROM generate_series(1, 1000) g;
SQL

echo "seed done: $(find /srv/files -type f | wc -l) files, shop.orders=$(mariadb -N -e 'SELECT COUNT(*) FROM shop.orders'), ledger.entries=$(sudo -u postgres psql -At -d ledger -c 'SELECT count(*) FROM entries')"
