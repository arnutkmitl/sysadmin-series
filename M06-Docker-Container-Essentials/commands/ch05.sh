#!/usr/bin/env bash
# โปรเจกต์จบเล่ม: Full Application Stack
# SysAdmin Pocket Series M06 Docker & Container Essentials
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── ขั้นที่ 4 ขึ้นระบบ ──────────────────────────────────────
cd ~/capstone
cp .env.example .env && sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=$(head -c 12 /dev/urandom | base64)/" .env
docker compose config --quiet && echo config ok
docker compose up -d --build 2>&1 | grep -E "Built|Healthy|Started|rror"
docker compose ps --format "table {{.Service}}\t{{.Status}}"
docker compose ps --format "{{.Service}}: {{.Ports}}" | grep -E "0.0.0.0|127.0.0.1"
curl -s localhost/; echo
curl -s localhost/; echo
curl -s -X POST -H "Content-Type: application/json" -d "{\"body\":\"first note\"}" localhost/notes; echo
curl -s localhost/notes; echo
docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}"

# ── ขั้นที่ 5 ตรวจรับด้วย check-stack.sh ────────────────────
./check-stack.sh
docker compose down
docker compose up -d
curl -s localhost/notes; echo
curl -s localhost/; echo
./check-stack.sh | grep -E "INFO|note|passed"

# ── ขั้นที่ 6 ซ้อมรับมือเมื่อบางส่วนล่ม ─────────────────────
docker compose stop redis
time curl -s -w " %{http_code}\n" localhost/health
curl -s -o /dev/null -w "%{http_code}\n" localhost/
docker compose logs app 2>&1 | grep redis: | tail -1
docker compose ps --format "table {{.Service}}\t{{.Status}}" app
./check-stack.sh | grep -E "FAIL|passed"
docker compose start redis
curl -s localhost/health; echo
curl -s localhost/; echo
