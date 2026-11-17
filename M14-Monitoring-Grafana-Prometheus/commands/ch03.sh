#!/usr/bin/env bash
# บทที่ 3 Alertmanager: แจ้งเตือนผ่าน Telegram และ LINE
# SysAdmin Pocket Series M14 Monitoring with Grafana & Prometheus
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 3.2 เขียน Alert Rules ───────────────────────────────────
# บนเครื่อง mon
docker compose exec prometheus promtool check rules /etc/prometheus/alert_rules.yml

# ── Lab 3.1 โหลดกฎและดูสถานะ ────────────────────────────────
# บนเครื่อง mon
curl -s -X POST localhost:9090/-/reload
curl -s localhost:9090/api/v1/rules | python3 -c "import sys,json; [print(r['name'], r['health'], r['state']) for g in json.load(sys.stdin)['data']['groups'] for r in g['rules']]"

# ── 3.3 ตั้งค่า Alertmanager ────────────────────────────────
# บนเครื่อง mon
docker run --rm -v ./alertmanager:/etc/alertmanager:ro,Z --entrypoint amtool prom/alertmanager:v0.35.0 check-config /etc/alertmanager/alertmanager.yml

# ── สร้าง Bot และหา chat_id ─────────────────────────────────
# บนเครื่อง mon
printf '%s' 'TOKEN-ที่ได้จาก-BotFather' > secrets/telegram_bot_token
chmod 644 secrets/telegram_bot_token

# ── เพิ่ม Alertmanager เข้า Compose ─────────────────────────
# บนเครื่อง mon
docker compose up -d
sudo firewall-cmd --permanent --add-port=9093/tcp
sudo firewall-cmd --reload
curl -s localhost:9090/api/v1/alertmanagers

# ── Lab 3.2 จำลอง CPU สูงแล้วรับ Alert ──────────────────────
# บนเครื่อง app
sudo dnf install -y epel-release
sudo dnf install -y stress-ng
stress-ng --cpu 1 --cpu-load 95 --timeout 900 &

# ── Bridge แปลง Alert เป็นข้อความ LINE ──────────────────────
# บนเครื่อง mon
printf '%s' 'Channel-access-token-ของคุณ' > secrets/line_channel_token
chmod 644 secrets/line_channel_token
echo 'LINE_TO=Uxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' > .env
chmod 600 .env
docker compose up -d

# ── Lab 3.3 จำลองเครื่องดับ ส่งทั้ง Telegram และ LINE ───────
# ⚠️ คำสั่งนี้หยุดการเก็บ Metrics ของ app ทั้งหมด Dashboard ของ app จะว่างจนกว่าจะเปิดบริการคืน ห้ามทดสอบแบบนี้กับเครื่อง Production ที่ทีมอื่นเฝ้าดูอยู่ โดยไม่แจ้งล่วงหน้า
# บนเครื่อง app
sudo systemctl stop node_exporter
# บนเครื่อง mon
docker logs line-bridge

# ── Lab 3.4 Silence ระหว่างบำรุงรักษา ───────────────────────
# บนเครื่อง mon
docker compose exec alertmanager amtool --alertmanager.url=http://localhost:9093 silence add instance="192.168.56.56:9100" --duration=30m --author=admin --comment="ปิดเครื่อง app เพื่อ patch kernel"
docker compose exec alertmanager amtool --alertmanager.url=http://localhost:9093 silence query
docker compose exec alertmanager amtool --alertmanager.url=http://localhost:9093 alert query --silenced
docker compose exec alertmanager amtool --alertmanager.url=http://localhost:9093 silence expire cff75ef4-2da0-43a0-928f-5ce8d8c28e49
# บนเครื่อง app
sudo systemctl start node_exporter
