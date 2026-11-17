#!/usr/bin/env bash
# ภาคผนวก ค ไฟล์ Compose และโครงสร้างโฟลเดอร์ฉบับเต็ม
# SysAdmin Pocket Series M14 Monitoring with Grafana & Prometheus
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── ไฟล์เสริมสำหรับ Lab ─────────────────────────────────────
# บนเครื่อง mon
docker compose -f docker-compose.yml -f lab-mock-api/docker-compose.lab.yml up -d
docker logs lab-mock-api
