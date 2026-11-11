#!/usr/bin/env bash
# บทที่ 1 ติดตั้ง Rocky Linux จากเครื่องเปล่าถึง Login
# SysAdmin Pocket Series M01 Linux Server Quickstart
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# "หน้า N" คือเลขหน้าที่พิมพ์ในหนังสือ
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── หน้า 14 ────────────────────────────────────────
# ตรวจสอบ Checksum บน Linux/macOS
# Rocky-10.1-x86_64-minimal.iso: 1528954880 bytes
SHA256 (Rocky-10.1-x86_64-minimal.iso) =
5aafc2c86e606428cd7c5802b0d28c220f34c181a57eefff2cc6f65 214714499

# ── หน้า 29 ────────────────────────────────────────
Mount
File System
Point

# ── หน้า 31 ────────────────────────────────────────
Address
192.168.1.10
IP ของ Server
Netmask
255.255.255.0 หรือเขียนเป็น /24
Gateway
192.168.1.1
IP ของ Router
DNS
8.8.8.8, 1.1.1.1 ใช้ Google DNS และ Cloudflare Servers
DNS

# ── หน้า 40 ────────────────────────────────────────
cat /etc/os-release

# ── หน้า 42 ────────────────────────────────────────
ip addr
sudo whoami
df -h

# ── หน้า 44 ────────────────────────────────────────
RAM 8 GB ขึ้น
VirtualBox
virtualbox.org
Rocky Linux 9
Minimal ISO
ISO
rockylinux.org
25 GB ขึ้นไป

# ── หน้า 46 ────────────────────────────────────────
# ตรวจสอบ OS
cat /etc/os-release
# ตรวจสอบ IP
ip addr
# ตรวจสอบสิทธิ์ sudo
sudo whoami

# ── หน้า 48 ────────────────────────────────────────
Rocky Linux 10
Ubuntu Server 25.10

# ── หน้า 49 ────────────────────────────────────────
# อัปเดต Package List และ Upgrade ทุก Package
sudo apt update && sudo apt upgrade -y
# ตรวจสอบ OS Version
cat /etc/os-release
# ตรวจสอบ IP Address
ip addr
