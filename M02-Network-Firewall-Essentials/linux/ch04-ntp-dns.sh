#!/usr/bin/env bash
# บทที่ 4 ตั้งเวลาและชื่อ: NTP และ DNS Client
# SysAdmin Pocket Series M02 Network & Firewall Essentials
#
# ไฟล์นี้รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# Lab บางข้อตั้งใจทำให้เครือข่ายพัง ห้ามรันทั้งไฟล์
# คำสั่งที่ไม่มีป้าย [client] หรือ [Ubuntu] รันบน server (Rocky Linux 10)
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 4.1 ตั้ง Timezone ───────────────────────────────────────────
timedatectl
sudo timedatectl set-timezone Asia/Bangkok
timedatectl | grep 'Time zone'

timedatectl list-timezones | grep -E 'Bangkok|Singapore'


# ── 4.2 NTP ด้วย chrony ─────────────────────────────────────────
grep -E '^(pool|server)' /etc/chrony.conf

sudo sed -i 's/^pool .*/pool th.pool.ntp.org iburst/' /etc/chrony.conf
sudo systemctl restart chronyd

# ไฟล์ตั้งค่าของหัวข้อนี้อยู่ที่ configs/rocky/etc/chrony.conf.snippet ในชุดดาวน์โหลด
chronyc sources -v
chronyc tracking | grep -E 'Reference|Stratum|System time|Leap'


# ── 4.3 ตั้ง Hostname ให้เป็นระบบ ───────────────────────────────
# ⚠️ อย่าตั้งโดเมนภายในเป็น .local โดเมนนี้สงวนไว้ให้ mDNS ของ Apple และ Avahi เครื่อง macOS และ Linux desktop จะไม่ถาม DNS สำหรับชื่อที่ลงท้ายด้วย .local ทำให้หาเครื่องไม่เจอ ใช้ .lan, .internal หรือโดเมนย่อยของโดเมนจริงขององค์กรแทน
sudo hostnamectl set-hostname web01.example.lan
hostnamectl

sudo hostnamectl set-hostname --pretty "Web Server ฝ่ายบัญชี"
hostnamectl --static

echo "192.168.56.10  web01.example.lan  web01" | sudo tee -a /etc/hosts
hostname -f
getent hosts web01


# ── 4.4 ตั้ง DNS Client ให้ถูกต้อง ──────────────────────────────
nmcli -g ipv4.dns,ipv4.ignore-auto-dns,ipv6.ignore-auto-dns con show enp0s3

dig +short rockylinux.org
dig rockylinux.org MX +short
host -t A th.pool.ntp.org
nslookup time1.nimt.or.th

for dns in 1.1.1.1 8.8.8.8 9.9.9.9; do echo -n "$dns: "; dig @$dns +short www.example.com; done


# ── Local DNS Cache ด้วย systemd-resolved ───────────────────────
# ⚠️ การเปลี่ยน `/etc/resolv.conf` เป็น symlink กระทบการหาชื่อของทั้งเครื่อง ถ้าทำผิด server จะหาชื่อไม่ได้เลย ให้ทดสอบด้วย `dig rockylinux.org` ทันที วิธีย้อนกลับคือ `sudo rm /etc/resolv.conf` ตามด้วย `sudo systemctl disable --now systemd-resolved` และ `sudo systemctl restart NetworkManager` ซึ่งจะสร้างไฟล์เดิมคืนให้
sudo dnf install -y systemd-resolved
sudo systemctl enable --now systemd-resolved
sudo ln -sf ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
sudo systemctl restart NetworkManager
resolvectl status enp0s3 | grep 'DNS Servers'
sudo resolvectl statistics | grep -E 'Hits|Misses'


# ── Lab 4.1 ตั้ง NTP, Hostname และ DNS ──────────────────────────
sudo timedatectl set-timezone Asia/Bangkok
sudo sed -i 's/^pool .*/pool th.pool.ntp.org iburst/' /etc/chrony.conf
sudo systemctl restart chronyd
sudo hostnamectl set-hostname web01.example.lan
echo "192.168.56.10  web01.example.lan  web01" | sudo tee -a /etc/hosts
timedatectl; hostnamectl --static; chronyc tracking | head -3


# ── กล่อง Ubuntu ────────────────────────────────────────────────
# [Ubuntu]
cat /etc/chrony/sources.d/ubuntu-ntp-pools.sources | grep ^pool
chronyc -N sources

# [Ubuntu]
echo "pool th.pool.ntp.org iburst" | sudo tee /etc/chrony/sources.d/th-pool.sources
sudo chronyc reload sources
