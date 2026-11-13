#!/usr/bin/env bash
# ภาคผนวก ค แหล่งเรียนรู้เพิ่มเติม
# SysAdmin Pocket Series M10 SSL & Security Hardening
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── ไฟล์ประกอบหนังสือ ───────────────────────────────────────
git clone --filter=blob:none --sparse https://github.com/arnutkmitl/sysadmin-series.git
cd sysadmin-series
git sparse-checkout set M10-SSL-Security-Hardening
