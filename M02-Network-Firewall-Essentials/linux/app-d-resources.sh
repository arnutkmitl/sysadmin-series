#!/usr/bin/env bash
# ภาคผนวก ง แหล่งเรียนรู้เพิ่มเติม
# SysAdmin Pocket Series M02 Network & Firewall Essentials
#
# ไฟล์นี้รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# Lab บางข้อตั้งใจทำให้เครือข่ายพัง ห้ามรันทั้งไฟล์
# คำสั่งที่ไม่มีป้าย [client] หรือ [Ubuntu] รันบน server (Rocky Linux 10)
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── ไฟล์ประกอบหนังสือ ───────────────────────────────────────────
git clone https://github.com/arnutkmitl/sysadmin-series.git
git clone --filter=blob:none --sparse https://github.com/arnutkmitl/sysadmin-series.git
cd sysadmin-series
git sparse-checkout set M02-Network-Firewall-Essentials


# ── คู่มือในเครื่อง ─────────────────────────────────────────────
man firewalld.richlanguage
man nmcli-examples
man chrony.conf
man jail.conf
