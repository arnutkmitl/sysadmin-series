#!/usr/bin/env bash
# บทที่ 1 วางแผน Backup ก่อนลงมือ
# SysAdmin Pocket Series M17 Backup & Disaster Recovery
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 1.4 Lab 1.1 สำรวจข้อมูลบน prod ──────────────────────────
# บนเครื่อง prod
sudo du -sh /srv/files /srv/www /etc /var/lib/mysql /var/lib/pgsql/data /var/lib/docker/volumes /opt/wordpress
sudo docker system df --format "{{.Type}} {{.Size}}"
