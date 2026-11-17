#!/usr/bin/env bash
# บทที่ 5 ดูแล Monitoring ให้พร้อมใช้งานจริง
# SysAdmin Pocket Series M14 Monitoring with Grafana & Prometheus
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 5.1 ขนาดฐานข้อมูลและ Retention ──────────────────────────
# บนเครื่อง mon
curl -s -u "admin:$(cat secrets/prometheus_password)" localhost:9090/api/v1/status/tsdb | python3 -c "
import sys,json
d=json.load(sys.stdin)['data']
print('series', d['headStats']['numSeries'])
for x in d['seriesCountByMetricName'][:3]: print(x['name'], x['value'])"

# ── 5.2 Recording Rules ─────────────────────────────────────
# บนเครื่อง mon
docker compose exec prometheus promtool check rules /etc/prometheus/recording_rules.yml

# ── Docker ข้าม firewalld ───────────────────────────────────
# บนเครื่อง mon
sudo firewall-cmd --list-ports
docker port cadvisor
# บนเครื่อง app
curl -s -o /dev/null -w "%{http_code}\n" http://192.168.56.55:8080/metrics
# บนเครื่อง mon
curl -s -m 3 -o /dev/null -w "%{http_code}\n" localhost:8080/metrics

# ── Basic Auth ของ Prometheus ───────────────────────────────
# บนเครื่อง mon
sudo dnf install -y httpd-tools
python3 -c "import secrets;print(secrets.token_urlsafe(18),end='')" > secrets/prometheus_password
chmod 644 secrets/prometheus_password
printf 'basic_auth_users:\n  admin: %s\n' "$(htpasswd -nbBC 10 '' "$(cat secrets/prometheus_password)" | tr -d ':\n')" > prometheus/web.yml
cat prometheus/web.yml
docker compose exec prometheus promtool check web-config /etc/prometheus/web.yml

# ── Lab 5.1 ตรวจว่าล็อกแล้วจริง ─────────────────────────────
# บนเครื่อง mon
docker compose up -d
curl -s -o /dev/null -w "%{http_code}\n" localhost:9090/api/v1/query?query=up
curl -s -u "admin:$(cat secrets/prometheus_password)" -o /dev/null -w "%{http_code}\n" localhost:9090/api/v1/query?query=up
curl -s -u "admin:$(cat secrets/grafana_admin_password)" localhost:3000/api/datasources/uid/prometheus/health

# ── Pushgateway ต้องล็อกด้วย ────────────────────────────────
# บนเครื่อง app
echo "x 1" | curl -s -o /dev/null -w "%{http_code}\n" --data-binary @- http://192.168.56.55:9091/metrics/job/test
sudo /usr/local/bin/backup-with-metrics.sh
echo "0 2 * * * root /usr/local/bin/backup-with-metrics.sh" | sudo tee /etc/cron.d/db-backup

# ── Snapshot ของ Prometheus ─────────────────────────────────
# บนเครื่อง mon
curl -s -u "admin:$(cat secrets/prometheus_password)" -X POST localhost:9090/api/v1/admin/tsdb/snapshot
S=20261116T220241Z-1b3458e942432ffb
mkdir -p ~/backup
sudo tar czf ~/backup/prometheus-$S.tar.gz -C /var/lib/docker/volumes/monitoring_prometheus-data/_data/snapshots $S
ls -lh ~/backup

# ── ฐานข้อมูลของ Grafana ────────────────────────────────────
# บนเครื่อง mon
docker compose stop grafana
docker run --rm -v monitoring_grafana-data:/data:ro -v ~/backup:/backup:Z alpine cp /data/grafana.db /backup/grafana-$(date +%F).db
docker compose start grafana
ls -lh ~/backup

# ── 5.6 ไล่ปัญหาเมื่อกราฟว่าง ───────────────────────────────
# บนเครื่อง mon
docker compose exec prometheus promtool check config /etc/prometheus/prometheus.yml
curl -s -u "admin:$(cat secrets/prometheus_password)" localhost:9090/api/v1/query --data-urlencode 'query=node_cpu_seconds{mode="idle"}'
docker logs alertmanager 2>&1 | grep -i "notify" | tail -5
