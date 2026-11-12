#!/usr/bin/env bash
# ก่อนเริ่ม: วิธีใช้หนังสือและเตรียมเครื่อง
# SysAdmin Pocket Series M08 DNS & Essential Network Services
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── สิ่งที่ต้องเตรียม ───────────────────────────────────────
sudo nmcli con mod "Wired connection 1" con-name enp0s9 ipv4.method manual ipv4.addresses 10.8.0.1/24 ipv6.method disabled
sudo nmcli con up enp0s9
ip -br -4 a
