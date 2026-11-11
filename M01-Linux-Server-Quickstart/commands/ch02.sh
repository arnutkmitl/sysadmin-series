#!/usr/bin/env bash
# บทที่ 2 รู้จักระบบ คำสั่งพื้นฐานที่ต้องใช้ทุกวัน
# SysAdmin Pocket Series M01 Linux Server Quickstart
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# "หน้า N" คือเลขหน้าที่พิมพ์ในหนังสือ
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── หน้า 55 ────────────────────────────────────────
pwd
# ไปที่ /etc
cd /etc
# ไปที่ Home Directory ของตัวเอง (3 วิธี)
cd ~
cd $HOME
cd
# ย้อนกลับ 1 ระดับ
cd ..

# ── หน้า 56 ────────────────────────────────────────
# กลับไป Directory ก่อนหน้า
cd -
# แสดงรายการแบบพื้นฐาน
ls
# แสดงแบบละเอียด (Permission, Owner, ขนาด, วันที่)
ls -l
# แสดงรวมไฟล์ที่ซ่อน (ไฟล์ที่ขึ้นต้นด้วย .)
ls -la
# แสดงขนาดแบบอ่านง่าย (KB, MB, GB)
ls -lh
# แสดงเรียงตามเวลาแก้ไขล่าสุด (ใหม่สุดอยู่บน)
ls -lt

# ── หน้า 57 ────────────────────────────────────────
# ติดตั้ง tree ก่อน (ปกติ Minimal ไม่มี)
sudo dnf install -y tree
# แสดงโครงสร้าง 2 ระดับ
tree -L 2 /etc/ssh/

# ── หน้า 58 ────────────────────────────────────────
# สร้าง Directory
mkdir /home/sysadmin/projects
# สร้าง Directory หลายระดับพร้อมกัน
mkdir -p /home/sysadmin/projects/web/logs
# สร้างไฟล์เปล่า
touch /home/sysadmin/projects/note.txt

# ── หน้า 59 ────────────────────────────────────────
# คัดลอกไฟล์
cp /etc/hostname /home/sysadmin/hostname-backup.txt
# คัดลอก Directory (ต้องใช้ -r)
cp -r /etc/ssh/ /home/sysadmin/ssh-backup/
# คัดลอกพร้อมรักษา Permission และ Timestamp
cp -a /etc/ssh/ /home/sysadmin/ssh-backup/
# ย้ายไฟล์ไป Directory อื่น
mv /home/sysadmin/note.txt /home/sysadmin/projects/
# เปลี่ยนชื่อไฟล์ (ใช้ mv เหมือนกัน)
mv /home/sysadmin/projects/note.txt /home/sysadmin/projects/readme.txt
# ลบไฟล์
rm /home/sysadmin/hostname-backup.txt
# ลบไฟล์โดยไม่ถามยืนยัน
rm -f filename

# ── หน้า 60 ────────────────────────────────────────
# ลบ Directory ที่มีไฟล์ข้างใน
rm -r /home/sysadmin/ssh-backup/
# ลบ Directory โดยไม่ถามยืนยัน
rm -rf /home/sysadmin/ssh-backup/
# แสดงเนื้อหาทั้งหมด (เหมาะกับไฟล์สั้น)
cat /etc/hostname
# แสดงแบบเลื่อนตรวจสอบได้ (เหมาะกับไฟล์ยาว)
less /etc/ssh/sshd_config
# กด q เพื่อออก / กด / แล้วพิมพ์คำเพื่อค้นหา
# แสดง 20 บรรทัดแรก
head -20 /var/log/messages
# แสดง 20 บรรทัดสุดท้าย
tail -20 /var/log/messages

# ── หน้า 61 ────────────────────────────────────────
# ติดตามไฟล์แบบ Real-time (Log จะแสดงทันทีที่มีบรรทัดใหม่)
tail -f /var/log/messages
# เปิดไฟล์เพื่อแก้ไข
nano /home/sysadmin/projects/readme.txt

# ── หน้า 62 ────────────────────────────────────────
uptime

# ── หน้า 63 ────────────────────────────────────────
free -h

# ── หน้า 64 ────────────────────────────────────────
df -h
# ใช้ top (มีมาในระบบ)
top

# ── หน้า 65 ────────────────────────────────────────
q
M
P
k
Kill Process (พิมพ์ PID แล้วกด Enter)
1
# ติดตั้ง htop (จะได้ฝึกใช้ dnf ไปด้วย)
sudo dnf install -y htop
# เปิดใช้งาน
htop
sudo ss -tlnp

# ── หน้า 66 ────────────────────────────────────────
systemctl status sshd

# ── หน้า 67 ────────────────────────────────────────
# เปิด Service
sudo systemctl start sshd

# ── หน้า 68 ────────────────────────────────────────
# ปิด Service
sudo systemctl stop sshd
# Restart Service (ปิดแล้วเปิดใหม่)
sudo systemctl restart sshd
# Reload Config โดยไม่ต้อง Restart (ถ้า Service รองรับ)
sudo systemctl reload sshd
# ตั้งให้เปิดอัตโนมัติเมื่อ Boot
sudo systemctl enable sshd
# ตั้งให้เปิดอัตโนมัติ + เปิดทันที (2 อย่างในคำสั่งเดียว)
sudo systemctl enable --now sshd

# ── หน้า 69 ────────────────────────────────────────
# ยกเลิกการเปิดอัตโนมัติ
sudo systemctl disable sshd
# ตรวจสอบว่าเปิดอัตโนมัติหรือไม่
systemctl is-enabled sshd
# แสดง Service ที่ Active ทั้งหมด
systemctl list-units --type=service
# แสดง Service ที่ Failed
systemctl --failed
# แสดง Service ทั้งหมด (รวม Inactive)
systemctl list-units --type=service --all

# ── หน้า 70 ────────────────────────────────────────
# ติดตาม Log ของ sshd แบบ Real-time (เหมือน tail -f)
sudo journalctl -u sshd -f

# ── หน้า 71 ────────────────────────────────────────
# Log ทั้งหมดตั้งแต่ Boot ปัจจุบัน
sudo journalctl -b
# Log จาก Boot ก่อนหน้า
sudo journalctl -b -1
0
emerg
1
alert
2
crit
3
err
4
warning
5
notice
6
info
7
debug
# แสดงเฉพาะ Error ขึ้นไป (ระดับ 0-3)
sudo journalctl -p err

# ── หน้า 72 ────────────────────────────────────────
# แสดงเฉพาะ Error ของวันนี้
sudo journalctl -p err --since today
# แสดง Log ในช่วงเวลาที่กำหนด
sudo journalctl --since "2025-01-15 08:00" --until "2025-01-15 09:00"
# แสดง Log 50 บรรทัดล่าสุด
sudo journalctl -n 50
# ตรวจสอบรายการ Log Files
ls -la /var/log/

# ── หน้า 73 ────────────────────────────────────────
# Log Files ที่สำคัญ
cat /var/log/messages         # Log ทั่วไปของระบบ
cat /var/log/secure           # Log การ Login, sudo, SSH
cat /var/log/dnf.log          # Log การติดตั้ง/อัปเดต Package
cat /var/log/cron             # Log ของ Cron Job

# ── หน้า 74 ────────────────────────────────────────
# ค้นหา Package ที่มีคำว่า "vim" ในชื่อหรือคำอธิบาย
dnf search vim
# ตรวจสอบรายละเอียดของ Package
dnf info vim-enhanced
# ติดตั้ง Package เดียว
sudo dnf install -y vim-enhanced
# ติดตั้งหลาย Package พร้อมกัน
sudo dnf install -y vim-enhanced wget curl git
# ตรวจสอบว่า Package ติดตั้งแล้วหรือยัง
rpm -qa | grep vim
# ลบ Package
sudo dnf remove -y vim-enhanced

# ── หน้า 75 ────────────────────────────────────────
sudo dnf autoremove -y
# แสดง Package ที่ติดตั้งทั้งหมด
dnf list installed
# แสดง Package ที่มี Update
dnf list updates
# ติดตั้ง EPEL Repository
sudo dnf install -y epel-release
# อัปเดต Package List หลังเพิ่ม Repo ใหม่
sudo dnf update -y
# ตรวจสอบว่า EPEL ถูกเพิ่มแล้ว
dnf repolist

# ── หน้า 77 ────────────────────────────────────────
# ตรวจสอบชื่อ Server
hostname
# ตรวจสอบ OS Version
cat /etc/os-release
# ตรวจสอบ Kernel Version
uname -r
# ตรวจสอบเวลาเปิดเครื่องและ Load Average
uptime
# ตรวจสอบจำนวน CPU Core
nproc

# ── หน้า 78 ────────────────────────────────────────
# ตรวจสอบ RAM ทั้งหมดและที่ใช้ไป
free -h
# ตรวจสอบพื้นที่ Disk
df -h
# ตรวจสอบ IP Address
ip addr
# ตรวจสอบ Service ที่ Active ทั้งหมด
systemctl list-units --type=service --state=active
# ตรวจสอบสถานะ SSH
systemctl status sshd
# ตรวจสอบ Port ที่เปิดอยู่
sudo ss -tlnp
# ตรวจสอบ Service ที่ Failed
systemctl –failed

# ── หน้า 79 ────────────────────────────────────────
# ตรวจสอบ Error ของวันนี้
sudo journalctl -p err --since today
# ตรวจสอบ Log การ Login ล่าสุด 10 บรรทัด
sudo journalctl -u sshd -n 10
# ตรวจสอบ Log ของ secure (การ Login, sudo)
sudo tail -20 /var/log/secure
# เพิ่ม EPEL Repository
sudo dnf install -y epel-release
# ติดตั้ง htop
sudo dnf install -y htop
# ทดสอบ htop
htop

# ── หน้า 80 ────────────────────────────────────────
dnf install ไม่ได้ ไม่มี Internet
dnf: No
package found

# ── หน้า 81 ────────────────────────────────────────
Permission
denied เมื่อรัน
systemctl
journalctl ไม่
User ไม่มีสิทธิ์
htop แสดงผล
Terminal ไม่
Emulator หรือตั้ง export LANG=en_US.UTF-8

# ── หน้า 82 ────────────────────────────────────────
Rocky Linux (dnf)
Ubuntu (apt)

# ── หน้า 83 ────────────────────────────────────────
Rocky Linux (dnf) Ubuntu (apt)
# อัปเดตระบบ (ทำ 2 ขั้นตอน)
sudo apt update && sudo apt upgrade -y
# ติดตั้ง htop
sudo apt install -y htop
# ค้นหา Package
apt search nginx

# ── หน้า 84 ────────────────────────────────────────
Rocky Linux
Ubuntu
Log ทั่วไป /var/log/messages /var/log/syslog
Log การ Login /var/log/secure /var/log/auth.log Log Package /var/log/dnf.log /var/log/apt/history.log Manager
