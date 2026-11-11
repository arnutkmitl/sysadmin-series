#!/usr/bin/env bash
# บทที่ 3 จัดการ Users และ Permissions
# SysAdmin Pocket Series M01 Linux Server Quickstart
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# "หน้า N" คือเลขหน้าที่พิมพ์ในหนังสือ
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── หน้า 89 ────────────────────────────────────────
# ตรวจสอบข้อมูล User ทั้งหมดในระบบ
cat /etc/passwd

# ── หน้า 90 ────────────────────────────────────────
# สร้าง User ใหม่ชื่อ "webmaster"
sudo useradd -m -s /bin/bash -c "Web Master" webmaster
Option
-m
(/home/webmaster)
-s /bin/bash /bin/sh -c "Web Master"

# ── หน้า 91 ────────────────────────────────────────
sudo passwd webmaster
# ตรวจสอบข้อมูล User แบบละเอียด
id webmaster
# ตรวจสอบข้อมูลจาก /etc/passwd
getent passwd webmaster

# ── หน้า 92 ────────────────────────────────────────
# เพิ่ม webmaster เข้า Group wheel (sudo)
sudo usermod -aG wheel webmaster
# ตรวจสอบว่า webmaster อยู่ใน Group wheel แล้ว
id webmaster

# ── หน้า 93 ────────────────────────────────────────
# เปลี่ยน Shell
sudo usermod -s /bin/zsh webmaster
# เปลี่ยนคำอธิบาย
sudo usermod -c "Senior Web Master" webmaster
# Lock User (ปิดการ Login ชั่วคราว)
sudo usermod -L webmaster
# Unlock User (เปิดการ Login กลับ)
sudo usermod -U webmaster
# ปิดการ Login ถาวร (ใช้สำหรับ Service Account)
sudo usermod -s /sbin/nologin webmaster
# ลบ User แต่เก็บ Home Directory ไว้
sudo userdel webmaster
# ลบ User พร้อม Home Directory (ระวัง ข้อมูลจะหายทั้งหมด)
sudo userdel -r webmaster

# ── หน้า 94 ────────────────────────────────────────
# สร้าง Group ชื่อ "webadmin"
sudo groupadd webadmin
# สร้าง Group ชื่อ "devteam"
sudo groupadd devteam

# ── หน้า 95 ────────────────────────────────────────
# เพิ่ม User เข้า Group (อย่าลืม -a)
sudo usermod -aG webadmin webmaster
sudo usermod -aG devteam webmaster
# ตรวจสอบสมาชิกใน Group
getent group webadmin
# ตรวจสอบว่า User อยู่ใน Group ไหนบ้าง
id webmaster

# ── หน้า 96 ────────────────────────────────────────
# ตรวจสอบ Group ทั้งหมดในระบบ
cat /etc/group
# ตรวจสอบเฉพาะ Group ที่ไม่ใช่ System Group (GID >= 1000)
awk -F: '$3 >= 1000' /etc/group
# ลบ webmaster ออกจาก Group devteam
sudo gpasswd -d webmaster devteam
# ลบ Group (ต้องไม่มี User ที่ใช้เป็น Primary Group)
sudo groupdel devteam
# สร้าง User ทั้ง 2 คน
sudo useradd -m -s /bin/bash -c "Alice Web Admin" alice
sudo useradd -m -s /bin/bash -c "Bob Web Admin" bob
sudo passwd alice
sudo passwd bob

# ── หน้า 97 ────────────────────────────────────────
# สร้าง Group webadmin
sudo groupadd webadmin
# เพิ่มทั้ง 2 คนเข้า Group
sudo usermod -aG webadmin alice
sudo usermod -aG webadmin bob
# สร้าง Directory สำหรับเว็บ
sudo mkdir -p /var/www/html
# กำหนดให้ Group webadmin เป็นเจ้าของ
sudo chown root:webadmin /var/www/html
# กำหนด Permission ให้ Group อ่าน/เขียน/เข้าได้
sudo chmod 775 /var/www/html
# ตั้ง Set-GID Bit เพื่อให้ไฟล์ใหม่ที่สร้างภายในสืบทอด Group
sudo chmod g+s /var/www/html

# ── หน้า 100 ────────────────────────────────────────
# กำหนด Permission เป็น 755
chmod 755 /var/www/html

# ── หน้า 101 ────────────────────────────────────────
# กำหนด Permission เป็น 644
chmod 644 /etc/myapp/config.conf
# กำหนด Permission เป็น 600 (เฉพาะเจ้าของ)
chmod 600 ~/.ssh/authorized_keys
# กำหนดให้ Directory และไฟล์ข้างในทั้งหมด (Recursive)
chmod -R 755 /var/www/html/
# เพิ่มสิทธิ์ Execute ให้ Owner
chmod u+x script.sh
# ลบสิทธิ์ Write ของ Group
chmod g-w config.conf
# เพิ่มสิทธิ์ Read ให้ทุกคน
chmod a+r readme.txt

# ── หน้า 102 ────────────────────────────────────────
# กำหนดให้ Owner อ่าน+เขียน, Group อ่าน, Others ไม่มีสิทธิ์
chmod u=rw,g=r,o= secret.txt
# ลบสิทธิ์ Write ของ Others (ป้องกันคนอื่นแก้ไข)
chmod o-w /var/www/html/index.html
# เปลี่ยนเจ้าของไฟล์เป็น webmaster
sudo chown webmaster myfile.txt
# เปลี่ยนเจ้าของและ Group
sudo chown webmaster:webadmin myfile.txt
# เปลี่ยนเฉพาะ Group
sudo chown :webadmin myfile.txt

# ── หน้า 103 ────────────────────────────────────────
# เปลี่ยนแบบ Recursive (ทั้ง Directory และไฟล์ข้างใน)
sudo chown -R webmaster:webadmin /var/www/html/
# ตรวจสอบแบบรายการ
ls -la /var/www/html/
# ตรวจสอบแบบละเอียด (รวม Permission แบบตัวเลข)
stat /var/www/html/

# ── หน้า 104 ────────────────────────────────────────
# ใช้ visudo เปิดไฟล์ sudoers (ต้องใช้วิธีนี้เสมอ)
sudo visudo

# ── หน้า 105 ────────────────────────────────────────
# สร้างไฟล์สิทธิ์สำหรับ webmaster
echo "webmaster ALL=(ALL) ALL" | sudo tee /etc/sudoers.d/webmaster
# กำหนด Permission ให้ถูกต้อง (ต้องเป็น 440)
sudo chmod 440 /etc/sudoers.d/webmaster

# ── หน้า 106 ────────────────────────────────────────
# ให้ webmaster รันได้เฉพาะคำสั่ง systemctl กับ nginx
echo "webmaster ALL=(ALL) /usr/bin/systemctl restart nginx, /usr/bin/systemctl reload nginx, /usr/bin/systemctl status nginx" | sudo tee /etc/sudoers.d/webmaster
sudo chmod 440 /etc/sudoers.d/webmaster
# สำหรับ Deploy User ที่ใช้ใน Automation Script
echo "deploy ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart myapp" | sudo tee /etc/sudoers.d/deploy
sudo chmod 440 /etc/sudoers.d/deploy

# ── หน้า 107 ────────────────────────────────────────
# ให้ทุก User ใน Group webadmin ใช้ sudo ได้สำหรับคำสั่ง nginx
echo "%webadmin ALL=(ALL) /usr/bin/systemctl restart nginx, /usr/bin/systemctl reload nginx" | sudo tee /etc/sudoers.d/webadmin-group
sudo chmod 440 /etc/sudoers.d/webadmin-group
# ตรวจสอบว่าใครใช้ sudo ทำอะไรบ้าง
sudo journalctl -u sudo
# หรือตรวจสอบจาก /var/log/secure
sudo grep "sudo" /var/log/secure | tail -20

# ── หน้า 109 ────────────────────────────────────────
# สร้าง User ทั้ง 3 คน
sudo useradd -m -s /bin/bash -c "Alice Lead Developer" alice
sudo useradd -m -s /bin/bash -c "Bob Developer" bob
sudo useradd -m -s /bin/bash -c "Charlie Designer" charlie
# ตั้ง Password (ใน Lab ใช้ Password ง่าย ๆ ได้ แต่ Production ต้อง
sudo passwd alice
sudo passwd bob
sudo passwd Charlie
# สร้าง Group
sudo groupadd webdev
sudo groupadd webdesign
# ทั้ง 3 คนอยู่ใน webdev
sudo usermod -aG webdev alice
sudo usermod -aG webdev bob
sudo usermod -aG webdev charlie

# ── หน้า 110 ────────────────────────────────────────
# charlie อยู่ใน webdesign ด้วย
sudo usermod -aG webdesign charlie
# alice มีสิทธิ์ sudo สำหรับ Nginx
echo "alice ALL=(ALL) /usr/bin/systemctl restart nginx, /usr/bin/systemctl reload nginx, /usr/bin/systemctl status nginx" | sudo tee /etc/sudoers.d/alice-nginx
sudo chmod 440 /etc/sudoers.d/alice-nginx
# สร้าง Directory Structure
sudo mkdir -p /projects/webapp/assets
# กำหนด /projects/webapp ให้ Group webdev
sudo chown root:webdev /projects/webapp
sudo chmod 2775 /projects/webapp
# กำหนด /projects/webapp/assets ให้ Group webdesign
sudo chown root:webdesign /projects/webapp/assets
sudo chmod 2775 /projects/webapp/assets

# ── หน้า 111 ────────────────────────────────────────
# ทดสอบเป็น alice (สมาชิก webdev)
su - alice
cd /projects/webapp
touch test-alice.txt
ls -la
# ควรสร้างไฟล์ได้สำเร็จ Group ของไฟล์ควรเป็น webdev
exit
# ทดสอบเป็น charlie (สมาชิก webdev + webdesign)
su - charlie
cd /projects/webapp/assets
touch test-charlie.css
ls -la
# ควรสร้างไฟล์ได้สำเร็จ Group ของไฟล์ควรเป็น webdesign
exit
# ทดสอบว่า User ทั่วไปเข้าถึงไม่ได้
# สร้าง User ภายนอกทีมเพื่อทดสอบ
sudo useradd -m -s /bin/bash outsider
su - outsider
cd /projects/webapp
touch test-outsider.txt

# ── หน้า 112 ────────────────────────────────────────
# ควร Permission denied
exit
# ลบ User ทดสอบ
sudo userdel -r outsider
id alice
id bob
id charlie
ls -la /projects/

# ── หน้า 113 ────────────────────────────────────────
ls -la /projects/webapp/
ls -la /projects/webapp/test-alice.txt
su - alice ใส่
Password ไม่ได้
Password
Permission ไม่
Shared
chmod ใหม่
Directory ไม่ได้
Group ของไฟล์
Bit /projects/webapp
webdev
User ไม่เห็น
Logout แล้ว Login ใหม่ Group ใหม่
Logout/Login
visudo แจ้ง
visudo จะถามให้แก้ไข กด e Syntax Error
sudoers

# ── หน้า 114 ────────────────────────────────────────
Rocky Linux 10
Ubuntu Server 25.10 Group สำหรับ
wheel
sudo
sudo
usermod -aG wheel
usermod -aG sudo
sudo
username
username
useradd (ต้องใส่
adduser (ถามข้อมูลทีละ Interactive
Option เอง)
Default Shell /bin/bash
# สร้าง User แบบ Interactive (Ubuntu)
sudo adduser webmaster

# ── หน้า 115 ────────────────────────────────────────
# เพิ่มเข้า Group sudo (ไม่ใช่ wheel)
sudo usermod -aG sudo webmaster
