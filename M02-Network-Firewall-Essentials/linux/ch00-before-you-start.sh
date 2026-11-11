#!/usr/bin/env bash
# ก่อนเริ่ม: วิธีใช้หนังสือและเตรียม Lab
# SysAdmin Pocket Series M02 Network & Firewall Essentials
#
# ไฟล์นี้รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# Lab บางข้อตั้งใจทำให้เครือข่ายพัง ห้ามรันทั้งไฟล์
# คำสั่งที่ไม่มีป้าย [client] หรือ [Ubuntu] รันบน server (Rocky Linux 10)
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── ติดตั้งเครื่องมือ ───────────────────────────────────────────
sudo dnf install -y tcpdump nmap nmap-ncat bind-utils traceroute mtr net-tools policycoreutils-python-utils

sudo dnf install -y nmap nmap-ncat bind-utils curl


# ── ตรวจความพร้อม ───────────────────────────────────────────────
cat /etc/rocky-release
systemctl is-active NetworkManager firewalld chronyd sshd
