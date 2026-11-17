#!/usr/bin/env bash
# บทที่ 6 โปรเจกต์จบเล่ม: ส่งมอบระบบ Monitoring
# SysAdmin Pocket Series M14 Monitoring with Grafana & Prometheus
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── Pushgateway ต้องจำข้อมูลข้าม Restart ────────────────────
# บนเครื่อง mon
docker compose exec pushgateway ls -la /data
docker compose exec pushgateway id
docker run --rm -v monitoring_pushgateway-data:/data alpine chown 65534:65534 /data
docker compose restart pushgateway
# บนเครื่อง app
sudo /usr/local/bin/backup-with-metrics.sh
# บนเครื่อง mon
docker compose exec pushgateway ls -l /data

# ── 6.3 สคริปต์ตรวจส่งมอบ ───────────────────────────────────
# บนเครื่อง mon
chmod 755 ~/monitoring/check-monitoring.sh
~/monitoring/check-monitoring.sh; echo "exit=$?"

# ── 6.4 ซ้อมระบบล่ม ─────────────────────────────────────────
# ⚠️ การซ้อมนี้หยุดแอป shop จริง ผู้ใช้จะสั่งซื้อไม่ได้ระหว่างซ้อม บนระบบ Production ให้ซ้อมในช่วงเวลาที่ตกลงไว้ หรือใช้ target ทดสอบแยกต่างหาก
# บนเครื่อง app
sudo systemctl stop shop; date
# บนเครื่อง mon
docker logs lab-mock-api 2>&1 | grep WebsiteDown
~/monitoring/check-monitoring.sh | grep -vE "\[OK\]"
# บนเครื่อง app
sudo systemctl start shop

# ── 6.5 Restart แล้วข้อมูลต้องอยู่ ──────────────────────────
# บนเครื่อง mon
q(){ curl -s -u "admin:$(cat secrets/prometheus_password)" localhost:9090/api/v1/query --data-urlencode "query=$1" | python3 -c "import sys,json;[print(r['metric'].get('instance',''),r['value'][1]) for r in json.load(sys.stdin)['data']['result']]"; }
q 'count_over_time(up{job="node"}[3h])'
docker compose down
docker volume ls --format "{{.Name}}" | grep monitoring
docker compose up -d
q 'count_over_time(up{job="node"}[3h])'

# ── 6.6 เอกสารส่งมอบ ────────────────────────────────────────
# บนเครื่อง mon
sudo dnf install -y git
cd ~/monitoring
printf 'secrets/\n.env\n' > .gitignore
git init
git add .
git status --short | grep -E "secrets|\.env" || echo "ไม่มีไฟล์ลับใน Git"
