#!/usr/bin/env bash
# บทที่ 1 ติดตั้ง Rocky Linux 10 จากเครื่องเปล่าถึง Login
# SysAdmin Pocket Series M01 Linux Server Quickstart ฉบับปรับปรุง (Rocky Linux 10.2)
#
# ไฟล์นี้รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# คำสั่งที่ไม่มีป้ายรันบน server ส่วนบรรทัดที่มีป้าย [Host PC] รันใน PowerShell บน Windows
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── ตรวจ Checksum ก่อนใช้งาน ────────────────────────────────────
# [Host PC] (Get-Item .\Rocky-10.2-x86_64-minimal.iso).Length

# [Host PC] Get-FileHash .\Rocky-10.2-x86_64-minimal.iso -Algorithm SHA256

# [Host PC] (Get-FileHash .\Rocky-10.2-x86_64-minimal.iso).Hash -eq 'aac6ac3ce781b91a91ce78463405f66c611a5dca4b3840c79e5e01d97302f6c8'

sha256sum -c CHECKSUM --ignore-missing


# ── เตรียม USB Boot สำหรับเครื่องจริง ───────────────────────────
# ⚠️ การเขียน USB Boot ลบข้อมูลทั้งหมดใน USB Flash Drive ตัวนั้น สำรองข้อมูลก่อน และตรวจขนาดไดรฟ์ให้แน่ใจว่าเลือกถูกตัว
lsblk -d -o NAME,SIZE,MODEL,TRAN

# ⚠️ `dd` เขียนทับอุปกรณ์ปลายทางทันทีโดยไม่ถามยืนยัน ถ้าพิมพ์ of=/dev/sda แทน sdb ข้อมูลในดิสก์หลักของเครื่องจะหายทั้งลูก ตรวจคอลัมน์ TRAN ต้องเป็น usb และขนาดต้องตรงกับ USB ก่อนกด Enter
sudo dd if=Rocky-10.2-x86_64-minimal.iso of=/dev/sdb bs=4M status=progress oflag=sync


# ── Login ครั้งแรก ──────────────────────────────────────────────



# ── ตรวจรุ่นของระบบ ─────────────────────────────────────────────
cat /etc/rocky-release

cat /etc/os-release


# ── ตรวจชื่อเครื่องและเวลา ──────────────────────────────────────
hostname
hostname -s

sudo hostnamectl set-hostname web01.example.co.th
hostname

timedatectl

sudo timedatectl set-timezone Asia/Bangkok
timedatectl | grep "Time zone"


# ── ตรวจ IP Address ─────────────────────────────────────────────
ip -br addr

ip addr show enp0s8


# ── ตรวจสิทธิ์ sudo ─────────────────────────────────────────────
id

sudo whoami

sudo -i


# ── ตรวจผลการแบ่งดิสก์ ──────────────────────────────────────────
lsblk

sudo vgs
sudo lvs

df -hT

df -hT /var
sudo lvextend -r -L +4G /dev/rlm_server/var
df -hT /var


# ── ทดสอบจากฝั่ง VM ─────────────────────────────────────────────
ip route

ip route get 8.8.8.8
ip route get 192.168.56.1

ping -c 3 10.0.2.2

ping -c 3 8.8.8.8

ping -c 3 rockylinux.org

ping -c 3 192.168.1.1
ping -c 3 8.8.8.8
ping -c 3 rockylinux.org


# ── ทดสอบจากฝั่ง Host PC ────────────────────────────────────────


# [Host PC] Test-NetConnection 192.168.56.10 -Port 22


# ── แก้การ์ด enp0s8 หลังติดตั้ง ─────────────────────────────────
nmcli con show

# ⚠️ คำสั่ง `nmcli con up` และการแก้ IP ของการ์ดที่คุณใช้ SSH อยู่จะตัด Session นั้นทันที ถ้าค่าใหม่ผิด คุณจะเข้าเครื่องไม่ได้ ให้ทำจาก Console ของ VirtualBox หรือเครื่องจริงเสมอ
sudo nmcli con mod enp0s8 ipv4.method manual ipv4.addresses 192.168.56.10/24 ipv4.gateway "" ipv4.dns "" connection.autoconnect yes
sudo nmcli con up enp0s8
ip -br addr show enp0s8

ip route | grep default
sudo nmcli con mod enp0s8 ipv4.gateway ""
sudo nmcli con up enp0s8
ip route | grep default


# ── ขั้นที่ 4 Login และตรวจระบบ ─────────────────────────────────
cat /etc/rocky-release
hostname
timedatectl | grep -E "Time zone|synchronized"
id
sudo whoami
lsblk
ip -br addr


# ── ขั้นที่ 5 ทดสอบการเชื่อมต่อทั้งสองทิศ ───────────────────────
ip route
ping -c 3 10.0.2.2
ping -c 3 8.8.8.8
ping -c 3 rockylinux.org


# ── ขั้นที่ 6 อัปเดตระบบและถ่าย Snapshot base-10.2 ──────────────
sudo dnf update -y

sudo dnf check-update

sudo systemctl reboot


# ── ISO และ Checksum ────────────────────────────────────────────
# [Ubuntu]
sha256sum -c SHA256SUMS --ignore-missing


# ── ตั้งเครือข่ายสองการ์ดใน Subiquity ───────────────────────────
# [Ubuntu]
sudo cat /etc/netplan/50-cloud-init.yaml

# [Ubuntu]
sudo netplan try


# ── LVM ของ Ubuntu ใช้พื้นที่ไม่เต็มดิสก์ ───────────────────────
# [Ubuntu]
sudo vgs
# [Ubuntu]
sudo lvextend -r -l +100%FREE /dev/ubuntu-vg/ubuntu-lv


# ── ผู้ใช้ admin บน Ubuntu ──────────────────────────────────────
# [Ubuntu]
sudo useradd -m -g admin -G sudo -s /bin/bash admin
# [Ubuntu]
sudo passwd admin
# [Ubuntu]
id admin


# ── SSH Server ──────────────────────────────────────────────────
# [Ubuntu]
sudo apt install -y openssh-server
# [Ubuntu]
systemctl status ssh.socket --no-pager


# ── ตรวจระบบหลังติดตั้ง Ubuntu ──────────────────────────────────
# [Ubuntu]
cat /etc/os-release | head -4
# [Ubuntu]
sudo apt update && sudo apt upgrade -y
