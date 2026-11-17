#!/usr/bin/env bash
# บทที่ 4 เฝ้าทั้งระบบ: Docker, Nginx, MariaDB และแอปของเราเอง
# SysAdmin Pocket Series M14 Monitoring with Grafana & Prometheus
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── Lab 4.1 ใคร container ไหนกินทรัพยากร ────────────────────
# บนเครื่อง mon
docker compose up -d
curl -s -X POST localhost:9090/-/reload

# ── 4.2 Nginx ───────────────────────────────────────────────
# บนเครื่อง app
sudo dnf install -y nginx
sudo install -m 644 stub_status.conf /etc/nginx/conf.d/
sudo nginx -t
sudo systemctl enable --now nginx
curl -s http://127.0.0.1:8080/stub_status

# ── ติดตั้ง nginx-prometheus-exporter ───────────────────────
# บนเครื่อง app
curl -sLO https://github.com/nginx/nginx-prometheus-exporter/releases/download/v1.5.3/nginx-prometheus-exporter_1.5.3_linux_amd64.tar.gz
curl -sL https://github.com/nginx/nginx-prometheus-exporter/releases/download/v1.5.3/nginx-prometheus-exporter_1.5.3_checksums.txt | grep linux_amd64.tar.gz$ | sha256sum -c
mkdir nginx-exporter && tar xzf nginx-prometheus-exporter_1.5.3_linux_amd64.tar.gz -C nginx-exporter
sudo install -m 755 nginx-exporter/nginx-prometheus-exporter /usr/local/bin/
sudo install -m 644 nginx_exporter.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now nginx_exporter
curl -s localhost:9113/metrics | grep -E "^nginx_(up|connections_active|http_requests_total)"

# ── 4.3 MariaDB ─────────────────────────────────────────────
# บนเครื่อง app
sudo dnf install -y mariadb-server
sudo systemctl enable --now mariadb
sudo mariadb < exporter-user.sql
sudo mariadb -e "SHOW GRANTS FOR 'exporter'@'localhost'"

# ── ติดตั้ง mysqld_exporter ─────────────────────────────────
# บนเครื่อง app
curl -sLO https://github.com/prometheus/mysqld_exporter/releases/download/v0.21.0/mysqld_exporter-0.21.0.linux-amd64.tar.gz
curl -sL https://github.com/prometheus/mysqld_exporter/releases/download/v0.21.0/sha256sums.txt | grep linux-amd64 | sha256sum -c
tar xzf mysqld_exporter-0.21.0.linux-amd64.tar.gz
sudo install -m 755 mysqld_exporter-0.21.0.linux-amd64/mysqld_exporter /usr/local/bin/
sudo useradd --system --no-create-home --shell /sbin/nologin mysqld_exporter
sudo install -d -m 750 -o root -g mysqld_exporter /etc/mysqld_exporter
sudo nano /etc/mysqld_exporter/my.cnf
sudo chown root:mysqld_exporter /etc/mysqld_exporter/my.cnf
sudo chmod 640 /etc/mysqld_exporter/my.cnf
ls -l /etc/mysqld_exporter/my.cnf
sudo install -m 644 mysqld_exporter.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now mysqld_exporter
curl -s localhost:9104/metrics | grep -E "^mysql_(up|global_status_threads_connected|version_info)"

# ── ติดตั้งแอปเป็นบริการ ────────────────────────────────────
# บนเครื่อง app
sudo useradd --system --home-dir /opt/shop --shell /sbin/nologin shop
sudo install -d -o shop -g shop /opt/shop
sudo install -m 644 -o shop -g shop shop/shop.py /opt/shop/shop.py
sudo -u shop python3 -m venv /opt/shop/venv
sudo -u shop /opt/shop/venv/bin/pip install -q prometheus_client==0.26.0
sudo install -m 644 shop/shop.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now shop
for i in $(seq 1 20); do curl -s -o /dev/null localhost:8000/order; done
curl -s localhost:8001/metrics | grep -E "^shop_(orders_total|active|request_duration_seconds_(bucket|count))"

# ── Lab 4.2 ตอบคำถามธุรกิจด้วย PromQL ───────────────────────
# บนเครื่อง app
sudo firewall-cmd --permanent --add-service=http
for p in 9113 9104 8001 8000; do sudo firewall-cmd --permanent --add-rich-rule="rule family=ipv4 source address=192.168.56.55/32 port port=$p protocol=tcp accept"; done
sudo firewall-cmd --reload
# บนเครื่อง mon
curl -s -X POST localhost:9090/-/reload

# ── 4.5 blackbox_exporter: มองจากฝั่งผู้ใช้ ─────────────────
# บนเครื่อง mon
docker compose exec prometheus wget -qO- 'http://blackbox:9115/probe?module=http_2xx&target=http://192.168.56.56/' | grep -E '^probe_(success|http_status_code|duration_seconds|http_version)'

# ── 4.6 Pushgateway: งานที่รันแล้วจบ ────────────────────────
# บนเครื่อง mon
sudo firewall-cmd --permanent --add-rich-rule="rule family=ipv4 source address=192.168.56.56/32 port port=9091 protocol=tcp accept"
sudo firewall-cmd --reload
# บนเครื่อง app
sudo install -m 755 backup-with-metrics.sh /usr/local/bin/
sudo /usr/local/bin/backup-with-metrics.sh
curl -s 192.168.56.55:9091/metrics | grep "^backup_"

# ── 4.7 Alert และ Dashboard ของบริการ ───────────────────────
# บนเครื่อง mon
docker compose exec prometheus promtool check rules /etc/prometheus/alert_rules.yml
