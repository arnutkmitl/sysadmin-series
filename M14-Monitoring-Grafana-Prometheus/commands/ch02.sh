#!/usr/bin/env bash
# บทที่ 2 Grafana Dashboard
# SysAdmin Pocket Series M14 Monitoring with Grafana & Prometheus
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 2.1 เพิ่ม Grafana เข้า Docker Compose ───────────────────
# บนเครื่อง mon
cd ~/monitoring
mkdir -p secrets
chmod 700 secrets
head -c 18 /dev/urandom | base64 | tr -d '\n' > secrets/grafana_admin_password
chmod 644 secrets/grafana_admin_password
ls -ld secrets secrets/grafana_admin_password
# ⚠️ ถ้า Grafana อ่านไฟล์ secret ไม่ได้ มันจะเริ่มทำงานต่อด้วยรหัสผ่านเริ่มต้น `admin` โดยไม่หยุด สิ่งที่บอกได้มีเพียงบรรทัด `Permission denied` บรรทัดเดียวใน log ใน Lab ของผู้เขียน ไฟล์ที่เป็น 600 ทำให้ Grafana เปิดใช้ admin/admin จริง ทุกครั้งที่ติดตั้งใหม่ให้ทดสอบว่ารหัส admin ใช้ไม่ได้ ตามคำสั่งท้าย Lab 2.1
mkdir -p grafana/provisioning/{datasources,dashboards,plugins,alerting} grafana/dashboards

# ── Lab 2.1 เปิด Grafana และ Login ครั้งแรก ─────────────────
# บนเครื่อง mon
docker compose up -d
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --reload
docker compose ps --format '{{.Name}} {{.Image}} {{.Status}}'
curl -s localhost:3000/api/health
curl -s -o /dev/null -w '%{http_code}\n' -u admin:admin localhost:3000/api/datasources

# ── 2.2 เชื่อม Data Source แบบไฟล์ ──────────────────────────
# บนเครื่อง mon
docker compose restart grafana
P=$(cat secrets/grafana_admin_password)
curl -s -u admin:$P localhost:3000/api/datasources/uid/prometheus/health
docker logs grafana 2>&1 | grep 'provisioning.datasources'

# ── Lab 2.2 Dashboard Server Overview 6 Panel ───────────────
# บนเครื่อง mon
curl -sLo grafana/dashboards/server-overview.json https://raw.githubusercontent.com/arnutkmitl/sysadmin-series/main/M14-Monitoring-Grafana-Prometheus/monitoring/grafana/dashboards/server-overview.json
docker compose restart grafana
curl -s -u admin:$P "localhost:3000/api/search?query=M14" | python3 -m json.tool | grep -E '"(title|uid|folderTitle)"'

# ── Export เก็บใน Git ───────────────────────────────────────
# บนเครื่อง mon
mkdir -p ~/dashboard-backup
curl -s -u admin:$P localhost:3000/api/dashboards/uid/rYdddlPWk | python3 -c "import sys,json; d=json.load(sys.stdin)['dashboard']; d.pop('id',None); json.dump(d, open('/home/admin/dashboard-backup/node-exporter-full.json','w'), indent=2)"
ls -l ~/dashboard-backup
