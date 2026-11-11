#!/usr/bin/env bash
# บทที่ 1 เข้าใจ Network บน Linux
# SysAdmin Pocket Series M02 Network & Firewall Essentials
#
# ไฟล์นี้รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# Lab บางข้อตั้งใจทำให้เครือข่ายพัง ห้ามรันทั้งไฟล์
# คำสั่งที่ไม่มีป้าย [client] หรือ [Ubuntu] รันบน server (Rocky Linux 10)
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── ดูค่าของเครื่องจริง ─────────────────────────────────────────
ip -br addr
ip addr show enp0s8

ip route show
ip route get 8.8.8.8


# ── 1.3 Port ประตูเข้าออกของบริการ ──────────────────────────────
sudo ss -tlnp
sudo ss -ulnp | grep chronyd


# ── 1.4 DNS แปลชื่อเป็น IP ──────────────────────────────────────
grep ^hosts /etc/nsswitch.conf
cat /etc/resolv.conf

getent hosts intranet.example.lan
echo "192.168.56.10  intranet.example.lan" | sudo tee -a /etc/hosts
getent hosts intranet.example.lan
sudo sed -i '/intranet.example.lan/d' /etc/hosts


# ── 1.5 โครงสร้าง Network Stack บน Linux ────────────────────────
sudo ls /etc/NetworkManager/system-connections/
sudo grep -A3 '^\[ipv4\]' /etc/NetworkManager/system-connections/enp0s8.nmconnection
