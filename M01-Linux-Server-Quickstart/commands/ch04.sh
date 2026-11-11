#!/usr/bin/env bash
# บทที่ 4 เชื่อมต่อ SSH Remote จากที่ไหนก็ได้
# SysAdmin Pocket Series M01 Linux Server Quickstart
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# "หน้า N" คือเลขหน้าที่พิมพ์ในหนังสือ
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── หน้า 121 ────────────────────────────────────────
ssh sysadmin@192.168.1.10
The authenticity of host '192.168.1.10 (192.168.1.10)' can't be established.
ED25519 key fingerprint is
SHA256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.

# ── หน้า 122 ────────────────────────────────────────
Are you sure you want to continue connecting
(yes/no/[fingerprint])? yes

# ── หน้า 123 ────────────────────────────────────────
ssh sysadmin@192.168.1.10
ssh -p 2222 sysadmin@192.168.1.10
[sysadmin@server01 ~]$
hostname

# ── หน้า 124 ────────────────────────────────────────
whoami
# sysadmin
ip addr | grep "inet "

# ── หน้า 125 ────────────────────────────────────────
RSA (เก่า)
ed25519 (แนะนำ)
# สร้าง Key Pair แบบ ed25519
ssh-keygen -t ed25519 -C "sysadmin@workstation"
Generating public/private ed25519 key pair.
Enter file in which to save the key
(/home/sysadmin/.ssh/id_ed25519): [กด Enter ใช้ค่าเริ่มต้น] Enter passphrase (empty for no passphrase): [พิมพ์ Passphrase Enter same passphrase again: [พิมพ์อีกครั้ง]

# ── หน้า 127 ────────────────────────────────────────
ssh-copy-id sysadmin@192.168.1.10
# แสดง Public Key
cat ~/.ssh/id_ed25519.pub
type $env:USERPROFILE\.ssh\id_ed25519.pub

# ── หน้า 128 ────────────────────────────────────────
# บน Server สร้าง Directory .ssh (ถ้ายังไม่มี)
mkdir -p ~/.ssh
# กำหนด Permission ให้ถูกต้อง
chmod 700 ~/.ssh
# วาง Public Key ลงไฟล์ authorized_keys
echo "ssh-ed25519 AAAA...ข้อความที่ Copy มา... sysadmin@workstation" >> ~/.ssh/authorized_keys
# กำหนด Permission
chmod 600 ~/.ssh/authorized_keys
Permission

# ── หน้า 129 ────────────────────────────────────────
ssh sysadmin@192.168.1.10
# สำรองไฟล์ sshd_config ก่อนแก้ไขเสมอ
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%Y%m%d)

# ── หน้า 130 ────────────────────────────────────────
sudo nano /etc/ssh/sshd_config
# เปิด Port ใหม่บน Firewall
sudo firewall-cmd --permanent --add-port=2222/tcp
sudo firewall-cmd --reload
# ถ้าใช้ SELinux ต้องอนุญาต Port ใหม่ด้วย
sudo semanage port -a -t ssh_port_t -p tcp 2222
sudo dnf install -y policycoreutils-python-utils

# ── หน้า 131 ────────────────────────────────────────
PasswordAuthentication no
PermitRootLogin no
AllowUsers sysadmin webmaster

# ── หน้า 132 ────────────────────────────────────────
MaxAuthTries 3
Port 2222
PermitRootLogin no
PasswordAuthentication no
AllowUsers sysadmin webmaster
MaxAuthTries 3
# ตรวจ Syntax ของ sshd_config
sudo sshd -t

# ── หน้า 133 ────────────────────────────────────────
sudo systemctl restart sshd
ssh -p 2222 sysadmin@192.168.1.10
# ทดสอบ Login ด้วย Password (ควรถูกปฏิเสธ)
ssh -p 2222 -o PubkeyAuthentication=no
sysadmin@192.168.1.10
# ผลลัพธ์ที่คาดหวัง: Permission denied (publickey)

# ── หน้า 134 ────────────────────────────────────────
# ทดสอบ Login ด้วย root (ควรถูกปฏิเสธ)
ssh -p 2222 root@192.168.1.10
# ผลลัพธ์ที่คาดหวัง: Permission denied (publickey)
# ทดสอบ Login ด้วย Port เก่า (ควรเชื่อมต่อไม่ได้)
ssh -p 22 sysadmin@192.168.1.10
# ผลลัพธ์ที่คาดหวัง: Connection refused
ssh -p 2222 -i ~/.ssh/id_ed25519 sysadmin@192.168.1.10
nano ~/.ssh/config

# ── หน้า 135 ────────────────────────────────────────
# Server ตัวแรก Lab Server
Host myserver
HostName 192.168.1.10
Port 2222
User sysadmin
IdentityFile ~/.ssh/id_ed25519
# Server ตัวที่สอง Web Server
Host webserver
HostName 10.0.1.50
Port 2200
User webmaster
IdentityFile ~/.ssh/id_ed25519
# Server ตัวที่สาม Database Server
Host dbserver
HostName 10.0.1.51
Port 2222
User dbadmin
IdentityFile ~/.ssh/id_ed25519
chmod 600 ~/.ssh/config

# ── หน้า 136 ────────────────────────────────────────
# เชื่อมต่อ Lab Server
ssh myserver
# เชื่อมต่อ Web Server
ssh webserver
# เชื่อมต่อ Database Server
ssh dbserver
Host myserver
HostName 192.168.1.10
Port 2222
User sysadmin
IdentityFile ~/.ssh/id_ed25519
ServerAliveInterval 60
ServerAliveCountMax 3

# ── หน้า 137 ────────────────────────────────────────
# คัดลอกไฟล์จากเครื่อง Client ไป Server
scp myfile.txt myserver:/home/sysadmin/
# คัดลอกไฟล์จาก Server มาเครื่อง Client
scp myserver:/var/log/messages ./messages.log
# คัดลอก Directory ทั้งหมด
scp -r myfolder/ myserver:/home/sysadmin/

# ── หน้า 138 ────────────────────────────────────────
# บนเครื่อง Client
ssh-keygen -t ed25519 -C "lab-key"
# บนเครื่อง Client
ssh-copy-id sysadmin@[IP ของ Server]
# บนเครื่อง Client
ssh sysadmin@[IP ของ Server]

# ── หน้า 139 ────────────────────────────────────────
# สำรอง Config
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%Y%m%d)
# แก้ไข Config
sudo nano /etc/ssh/sshd_config
Port 2222
PermitRootLogin no
PasswordAuthentication no
AllowUsers sysadmin
MaxAuthTries 3
# เพิ่ม Port ใหม่
sudo firewall-cmd --permanent --add-port=2222/tcp
sudo firewall-cmd --reload

# ── หน้า 140 ────────────────────────────────────────
# อนุญาต SELinux (ถ้าจำเป็น)
sudo dnf install -y policycoreutils-python-utils
sudo semanage port -a -t ssh_port_t -p tcp 2222
# ตรวจ Syntax
sudo sshd -t
# Restart SSH
sudo systemctl restart sshd
# ทดสอบ Login ด้วย Port ใหม่ + Key
ssh -p 2222 sysadmin@[IP ของ Server]
# ทดสอบว่า Password ถูกปิด
ssh -p 2222 -o PubkeyAuthentication=no sysadmin@[IP ของ Server]

# ── หน้า 141 ────────────────────────────────────────
ssh -p 2222 root@[IP ของ Server]
# บนเครื่อง Client
nano ~/.ssh/config
chmod 600 ~/.ssh/config
ssh lab-server
# ควร Login ได้ทันที
# บน Server ลบ SSH Service จาก Firewall (ซึ่งเปิด Port 22)
sudo firewall-cmd --permanent --remove-service=ssh
sudo firewall-cmd --reload

# ── หน้า 142 ────────────────────────────────────────
# ตรวจสอบ
sudo firewall-cmd --list-all
# ไม่ควรเห็น service: ssh แล้ว แต่ควรเห็น port: 2222/tcp
Connection
Port ใหม่ไม่ได้
refused หลัง
permanent --add-port=2222/tcp Restart
Firewall
&& firewall-cmd --reload
Permission
Key ไม่ตรง
denied
authorized_keys เป็น 600 และ (publickey)
Permission
.ssh เป็น 700

# ── หน้า 143 ────────────────────────────────────────
SELinux
blocking SSH
semanage
ssh_port_t -p tcp 2222
on new port
sshd_config
syntax error
Config
Console) แล้วใช้ไฟล์ Backup sshd_config.bak กู้คืน

# ── หน้า 144 ────────────────────────────────────────
# ติดตั้ง OpenSSH Server
sudo apt install -y openssh-server
# เปิด Service
sudo systemctl enable --now ssh
# ตรวจสอบสถานะ
sudo systemctl status ssh

# ── หน้า 145 ────────────────────────────────────────
Rocky Linux (firewall-Ubuntu (ufw) cmd)
firewall-cmd --permanent --sudo ufw allow SSH ใหม่
add-port=2222/tcp
2222/tcp
Reload
firewall-cmd --reload
(ไม่จำเป็น ufw มีผล Firewall
firewall-cmd --list-all
sudo ufw status
sudo ufw delete remove-service=ssh
allow 22/tcp
# ตัวอย่างการตั้งค่า Firewall สำหรับ SSH บน Ubuntu
sudo ufw allow 2222/tcp
sudo ufw delete allow 22/tcp
sudo ufw status
