#!/usr/bin/env bash
# บทที่ 5 ตั้งค่า Firewall และ SELinux
# SysAdmin Pocket Series M01 Linux Server Quickstart
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# "หน้า N" คือเลขหน้าที่พิมพ์ในหนังสือ
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── หน้า 150 ────────────────────────────────────────
# ตรวจสอบว่า firewalld กำลังทำงานอยู่หรือไม่
sudo systemctl status firewalld
# ตรวจสอบกฎทั้งหมดของ Zone ปัจจุบัน
sudo firewall-cmd --list-all

# ── หน้า 151 ────────────────────────────────────────
# เปิด HTTP (Port 80)
sudo firewall-cmd --permanent --add-service=http
# เปิด HTTPS (Port 443)
sudo firewall-cmd --permanent --add-service=https

# ── หน้า 152 ────────────────────────────────────────
# Reload เพื่อให้มีผล
sudo firewall-cmd –reload
# เปิด Port 8080/tcp
sudo firewall-cmd --permanent --add-port=8080/tcp
# เปิด Port 3306/tcp (MySQL)
sudo firewall-cmd --permanent --add-port=3306/tcp
# Reload เพื่อให้มีผล
sudo firewall-cmd –reload
# ปิด Service
sudo firewall-cmd --permanent --remove-service=cockpit
sudo firewall-cmd --reload

# ── หน้า 153 ────────────────────────────────────────
# ปิด Port
sudo firewall-cmd --permanent --remove-port=8080/tcp
sudo firewall-cmd –reload
# ตรวจสอบ Service ทั้งหมดที่ firewalld รองรับ
firewall-cmd --get-services
# ตรวจสอบว่า Service นั้นใช้ Port อะไร
firewall-cmd --info-service=http
# ตรวจสอบกฎทั้งหมดอีกครั้ง
sudo firewall-cmd --list-all

# ── หน้า 154 ────────────────────────────────────────
# ตรวจสอบเฉพาะ Port ที่เปิด
sudo firewall-cmd --list-ports

# ── หน้า 155 ────────────────────────────────────────
Mode
# ตรวจสอบ Mode ปัจจุบัน
getenforce
# ตรวจสอบรายละเอียดเพิ่มเติม
sestatus

# ── หน้า 156 ────────────────────────────────────────
# เปลี่ยนเป็น Permissive (สำหรับ Debug เท่านั้น)
sudo setenforce 0
# เปลี่ยนกลับเป็น Enforcing
sudo setenforce 1

# ── หน้า 157 ────────────────────────────────────────
sudo nano /etc/selinux/config
# ติดตั้ง Package ที่จำเป็น (ถ้ายังไม่มี)
sudo dnf install -y setroubleshoot-server
# อ่าน Error ทั้งหมด
sudo sealert -a /var/log/audit/audit.log

# ── หน้า 158 ────────────────────────────────────────
# ตรวจสอบ SELinux Context ของไฟล์
ls -Z /var/www/html/
# แก้ Context ให้ถูกต้องสำหรับ Web Content
sudo semanage fcontext -a -t httpd_sys_content_t
"/data/web(/.*)?"

# ── หน้า 159 ────────────────────────────────────────
sudo restorecon -Rv /data/web/
# ตรวจสอบ Port ที่ SELinux อนุญาตสำหรับ SSH
sudo semanage port -l | grep ssh
# เพิ่ม Port ใหม่สำหรับ SSH
sudo semanage port -a -t ssh_port_t -p tcp 2222
# ตรวจสอบ Port ที่ SELinux อนุญาตสำหรับ HTTP
sudo semanage port -l | grep http
# เพิ่ม Port ใหม่สำหรับ HTTP
sudo semanage port -a -t http_port_t -p tcp 8080
# ตรวจสอบ Boolean ทั้งหมดที่เกี่ยวกับ httpd
sudo getsebool -a | grep httpd
# อนุญาตให้ httpd เชื่อมต่อ Network ออกไปข้างนอก
sudo setsebool -P httpd_can_network_connect on
# อนุญาตให้ httpd ส่ง Email
sudo setsebool -P httpd_can_sendmail on

# ── หน้า 160 ────────────────────────────────────────
Service
Port
Protocol
firewall-cmd

# ── หน้า 161 ────────────────────────────────────────
# ตรวจสอบสถานะปัจจุบัน
sudo firewall-cmd --list-all
# ลบ Service ที่ไม่จำเป็น
sudo firewall-cmd --permanent --remove-service=cockpit
sudo firewall-cmd --permanent --remove-service=dhcpv6-client
# เปิด Service สำหรับ Web
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-port=8080/tcp
# เปิด SSH Port ที่เปลี่ยนไว้ (ถ้ายังไม่ได้เปิดจากบทที่ 4)
sudo firewall-cmd --permanent --add-port=2222/tcp
# ลบ SSH Port เก่า (ถ้ายังเปิดอยู่)
sudo firewall-cmd --permanent --remove-service=ssh

# ── หน้า 162 ────────────────────────────────────────
# Reload
sudo firewall-cmd --reload
# ตรวจสอบผลลัพธ์
sudo firewall-cmd --list-all

# ── หน้า 164 ────────────────────────────────────────
# ตรวจสอบสถานะ Firewall
sudo firewall-cmd --list-all
# ตรวจสอบสถานะ SELinux
getenforce
sestatus

# ── หน้า 165 ────────────────────────────────────────
sudo firewall-cmd --permanent --remove-service=cockpit
sudo firewall-cmd --permanent --remove-service=dhcpv6-client
# ลบ SSH Port เก่า (ถ้ายังเปิดอยู่)
sudo firewall-cmd --permanent --remove-service=ssh
# SSH Custom Port
sudo firewall-cmd --permanent --add-port=2222/tcp
# Web Server
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
# Application Port
sudo firewall-cmd --permanent --add-port=8080/tcp
# Reload
sudo firewall-cmd --reload
# ตรวจ Mode
getenforce

# ── หน้า 166 ────────────────────────────────────────
# ถ้าเป็น Permissive ให้เปลี่ยนกลับ
sudo setenforce 1
# ตรวจไฟล์ Config ว่าเป็น enforcing ถาวร
grep "^SELINUX=" /etc/selinux/config
# ตรวจสอบว่า Package ที่จำเป็นมีอยู่แล้ว
sudo dnf install -y policycoreutils-python-utils
# อนุญาต SSH บน Port 2222 (ถ้ายังไม่ได้ทำจากบทที่ 4)
sudo semanage port -l | grep ssh_port_t
sudo semanage port -a -t ssh_port_t -p tcp 2222
# อนุญาต HTTP บน Port 8080
sudo semanage port -a -t http_port_t -p tcp 8080
# ทดสอบ SSH
ssh -p 2222 sysadmin@[IP ของ Server]

# ── หน้า 167 ────────────────────────────────────────
# ติดตั้ง nc สำหรับทดสอบ (บน Server)
sudo dnf install -y nmap-ncat
# เปิด Port ชั่วคราวเพื่อทดสอบ (บน Server Terminal ที่ 1)
nc -l 80 &
# ทดสอบจากเครื่อง Client
nc -zv [IP ของ Server] 80
# ควรได้ Connection succeeded
nc -zv [IP ของ Server] 443
nc -zv [IP ของ Server] 3306
# Kill nc process ที่เปิดไว้
kill %1

# ── หน้า 168 ────────────────────────────────────────
sudo firewall-cmd --list-all
getenforce

# ── หน้า 169 ────────────────────────────────────────
# เปิดใช้งาน ufw (ครั้งแรก)
sudo ufw enable
# ตรวจสอบสถานะ
sudo ufw status verbose

# ── หน้า 170 ────────────────────────────────────────
Rocky Linux (firewall-cmd)
Ubuntu (ufw)
firewall-cmd --list-all
ufw status verbose
firewall-cmd --permanent --ufw allow 8080/tcp add-port=8080/tcp
ufw allow http add-service=http
firewall-cmd --permanent --ufw delete allow remove-port=8080/tcp
8080/tcp
Reload
firewall-cmd --reload
(มีผลทันที ไม่ต้อง Reload)
firewall-cmd --permanent --ufw allow from IP เฉพาะ
add-rich-rule='...'
192.168.1.0/24 to any port 22
(ค่าเริ่มต้นของ public zone)
ufw default deny incoming
systemctl start/stop
ufw enable/disable Firewall
firewalld

# ── หน้า 171 ────────────────────────────────────────
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 2222/tcp    # SSH Custom Port
sudo ufw allow http         # Port 80
sudo ufw allow https        # Port 443
sudo ufw allow 8080/tcp     # Application
sudo ufw enable
sudo ufw status
# ตรวจสอบสถานะ AppArmor
sudo apparmor_status
# ตรวจสอบว่า Profile ไหนอยู่ใน Enforce Mode
sudo aa-status
