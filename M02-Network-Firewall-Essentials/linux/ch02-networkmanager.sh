#!/usr/bin/env bash
# บทที่ 2 ตั้งค่า Network ด้วย NetworkManager
# SysAdmin Pocket Series M02 Network & Firewall Essentials
#
# ไฟล์นี้รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# Lab บางข้อตั้งใจทำให้เครือข่ายพัง ห้ามรันทั้งไฟล์
# คำสั่งที่ไม่มีป้าย [client] หรือ [Ubuntu] รันบน server (Rocky Linux 10)
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 2.1 nmcli เครื่องมือหลักของ NetworkManager ──────────────────
nmcli device status
nmcli connection show

nmcli con show enp0s8 | grep -E '^ipv4\.(method|addresses|gateway|dns)'
nmcli -f GENERAL.STATE,IP4.ADDRESS dev show enp0s8

nmcli general status


# ── 2.2 ตั้ง Static IP ──────────────────────────────────────────
sudo nmcli con mod "ens33" ipv4.addresses 192.168.1.100/24
sudo nmcli con mod "ens33" ipv4.gateway 192.168.1.1
sudo nmcli con mod "ens33" ipv4.dns "1.1.1.1 9.9.9.9"
sudo nmcli con mod "ens33" ipv4.method manual
sudo nmcli con up "ens33"

sudo nmcli con mod enp0s8 ipv4.method manual ipv4.addresses 192.168.56.10/24 ipv6.method disabled
sudo nmcli con up enp0s8

# ⚠️ ถ้าคุณ SSH เข้ามาทางการ์ดที่กำลังเปลี่ยน IP การเชื่อมต่อจะหลุดทันทีหลัง `nmcli con up` และถ้าตั้งค่าผิดจะเข้าเครื่องไม่ได้อีก ให้ทำขั้นนี้จาก Console ของ VirtualBox หรือ Console ของผู้ให้บริการ cloud เสมอ
ip -br addr show enp0s8
sudo grep -A3 '^\[ipv4\]' /etc/NetworkManager/system-connections/enp0s8.nmconnection


# ── 2.3 เพิ่ม Network Interface (Dual NIC) ──────────────────────
sudo nmcli con add type ethernet ifname enp0s9 con-name service-net \
    ipv4.method manual ipv4.addresses 192.168.57.10/24 \
    ipv4.never-default yes ipv6.method disabled
sudo nmcli con up service-net

sudo nmcli con add type ethernet ifname ens35 con-name backup-net \
    ipv4.method manual ipv4.addresses 10.10.50.21/24 ipv4.never-default yes

sudo nmcli con delete "Wired connection 1"


# ── 2.4 Bonding ─────────────────────────────────────────────────
sudo nmcli con add type bond ifname bond0 con-name bond0 \
    bond.options "mode=active-backup,miimon=100" \
    ipv4.method manual ipv4.addresses 192.168.10.20/24 ipv4.gateway 192.168.10.1
sudo nmcli con add type ethernet ifname ens33 con-name bond0-port1 controller bond0 port-type bond
sudo nmcli con add type ethernet ifname ens34 con-name bond0-port2 controller bond0 port-type bond
cat /proc/net/bonding/bond0


# ── 2.5 เปลี่ยน DNS ─────────────────────────────────────────────
# ⚠️ อย่าแก้ `/etc/resolv.conf` ด้วยมือ NetworkManager จะเขียนทับเมื่อ connection ขึ้นใหม่หรือรีบูต ค่าที่แก้จะหายไปโดยไม่มีข้อความเตือน
sudo nmcli con mod enp0s3 ipv4.ignore-auto-dns yes ipv6.ignore-auto-dns yes ipv4.dns "1.1.1.1 9.9.9.9"
sudo nmcli con up enp0s3
cat /etc/resolv.conf

sudo nmcli con mod "ens33" ipv4.dns "192.168.1.53 1.1.1.1"
sudo nmcli con up "ens33"

dig google.com | grep -E 'status|SERVER|Query time'
dig @9.9.9.9 rockylinux.org +short
nslookup rockylinux.org 8.8.8.8


# ── 2.6 nmtui สำหรับงานด่วนบน Console ───────────────────────────
sudo nmtui


# ── Lab 2.1 ตั้ง Static IP สำหรับ Web Server ────────────────────
sudo nmcli con mod enp0s8 connection.id mgmt
sudo nmcli con mod mgmt ipv4.method manual ipv4.addresses 192.168.56.10/24 ipv6.method disabled
sudo nmcli con up mgmt
sudo nmcli con mod enp0s3 ipv4.ignore-auto-dns yes ipv6.ignore-auto-dns yes ipv4.dns "1.1.1.1 9.9.9.9"
sudo nmcli con up enp0s3


# ── Lab 2.2 ตั้ง Dual NIC แยก Management กับ Service ────────────
sudo mkdir -p /srv/www
echo "web01 OK" | sudo tee /srv/www/index.html
sudo systemd-run --unit=labweb python3 -m http.server 80 --directory /srv/www
sudo firewall-cmd --add-service=http

curl http://192.168.57.10
ssh -p 2222 admin@192.168.56.10


# ── กล่อง Ubuntu ────────────────────────────────────────────────
# ไฟล์ตั้งค่าของหัวข้อนี้อยู่ที่ configs/ubuntu/etc/netplan/60-lab.yaml ในชุดดาวน์โหลด
# ตัวอย่างค่าหรือรูปแบบในเล่ม (ไม่ใช่คำสั่ง):
#   network:
#     version: 2
#     ethernets:
#       ens33:
#         addresses: [192.168.1.100/24]
#         routes:
#           - to: default
#             via: 192.168.1.1
#         nameservers:
#           addresses: [192.168.1.53, 1.1.1.1]
# [Ubuntu]
sudo chmod 600 /etc/netplan/60-lab.yaml
sudo netplan try
sudo netplan apply
