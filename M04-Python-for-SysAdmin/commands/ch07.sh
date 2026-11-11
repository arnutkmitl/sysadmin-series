#!/usr/bin/env bash
# โปรเจกต์จบเล่ม: Python Admin Toolkit
# SysAdmin Pocket Series M04 Python for SysAdmin
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── ตรวจรับงาน ──────────────────────────────────────────────
sudo ~/python-admin/.venv/bin/python acceptance.py | tail -1
