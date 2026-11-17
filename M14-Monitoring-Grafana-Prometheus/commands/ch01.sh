#!/usr/bin/env bash
# บทที่ 1 Prometheus และ PromQL
# SysAdmin Pocket Series M14 Monitoring with Grafana & Prometheus
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 1.2 เปิด Prometheus ด้วย Docker Compose ─────────────────
# บนเครื่อง mon
mkdir -p ~/monitoring/prometheus
cd ~/monitoring

# ── Lab 1.1 เปิด Stack และดูหน้าเว็บ ────────────────────────
# บนเครื่อง mon
docker compose up -d
docker compose ps
sudo firewall-cmd --permanent --add-port=9090/tcp --add-port=9100/tcp
sudo firewall-cmd --reload
sudo firewall-cmd --list-ports
curl -s localhost:9100/metrics | grep -c '^node_'
curl -s localhost:9100/metrics | grep -E '^node_load1 |^node_memory_MemTotal_bytes'

# ── 1.3 prometheus.yml และการโหลดค่าใหม่ ────────────────────
# บนเครื่อง mon
docker compose exec prometheus promtool check config /etc/prometheus/prometheus.yml
curl -s -X POST localhost:9090/-/reload

# ── 1.4 node_exporter บนเครื่อง app ─────────────────────────
# บนเครื่อง app
sudo dnf install -y tar
cd /tmp
curl -sLO https://github.com/prometheus/node_exporter/releases/download/v1.12.1/node_exporter-1.12.1.linux-amd64.tar.gz
curl -sL https://github.com/prometheus/node_exporter/releases/download/v1.12.1/sha256sums.txt | grep linux-amd64 | sha256sum -c
tar xzf node_exporter-1.12.1.linux-amd64.tar.gz
sudo install -m 755 node_exporter-1.12.1.linux-amd64/node_exporter /usr/local/bin/
ls -Z /usr/local/bin/node_exporter
sudo useradd --system --no-create-home --shell /sbin/nologin node_exporter
sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter
systemctl status node_exporter --no-pager | head -3
/usr/local/bin/node_exporter --version | head -1
sudo firewall-cmd --permanent --add-rich-rule='rule family=ipv4 source address=192.168.56.55/32 port port=9100 protocol=tcp accept'
sudo firewall-cmd --reload
curl -s localhost:9100/metrics | grep -c '^node_systemd_unit_state'

# ── Lab 1.2 เพิ่ม app เป็น Target ───────────────────────────
# บนเครื่อง mon
docker compose exec prometheus promtool check config /etc/prometheus/prometheus.yml
curl -s -X POST localhost:9090/-/reload
curl -s localhost:9090/api/v1/targets | python3 -m json.tool | grep -E '"(instance|health)"'
