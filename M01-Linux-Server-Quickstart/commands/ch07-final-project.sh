#!/usr/bin/env bash
# โปรเจกต์จบเล่ม: สร้าง Server พร้อมใช้งานใน 60 นาที
# SysAdmin Pocket Series M01 Linux Server Quickstart
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# "หน้า N" คือเลขหน้าที่พิมพ์ในหนังสือ
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── หน้า 197 ────────────────────────────────────────
cat /etc/os-release
ip addr
sudo whoami
df -h
# อัปเดตระบบ
sudo dnf update -y
# ติดตั้ง EPEL + Package ที่จำเป็น
sudo dnf install -y epel-release
sudo dnf install -y vim-enhanced htop tree wget curl
policycoreutils-python-utils
# ตั้ง Auto-update
sudo dnf install -y dnf-automatic
sudo sed -i 's/apply_updates = no/apply_updates = yes/' /etc/dnf/automatic.conf
sudo systemctl enable --now dnf-automatic-install.timer

# ── หน้า 198 ────────────────────────────────────────
# สร้าง User สำหรับทีม Web
sudo useradd -m -s /bin/bash -c "Web Developer" webdev01
sudo passwd webdev01
# สร้าง Group
sudo groupadd webteam
sudo usermod -aG webteam admin01
sudo usermod -aG webteam webdev01
# สร้าง Directory สำหรับเว็บ
sudo mkdir -p /var/www/html
sudo chown root:webteam /var/www/html
sudo chmod 2775 /var/www/html
ssh-keygen -t ed25519 -C "admin01@workstation"
ssh-copy-id admin01@[IP ของ Server]
ssh admin01@[IP ของ Server]

# ── หน้า 199 ────────────────────────────────────────
# สำรอง Config
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%Y%m%d)
# แก้ไข Config
sudo nano /etc/ssh/sshd_config
# อนุญาต SELinux
sudo semanage port -a -t ssh_port_t -p tcp 2222
# ตรวจ Syntax
sudo sshd -t
# Restart SSH
sudo systemctl restart sshd
ssh -p 2222 admin01@[IP ของ Server]

# ── หน้า 200 ────────────────────────────────────────
# ลบ Service ที่ไม่จำเป็น
sudo firewall-cmd --permanent --remove-service=cockpit
sudo firewall-cmd --permanent --remove-service=dhcpv6-client
sudo firewall-cmd --permanent --remove-service=ssh
# เปิด Port ที่ต้องการ
sudo firewall-cmd --permanent --add-port=2222/tcp
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
# Reload
sudo firewall-cmd --reload
# ตรวจสอบ
sudo firewall-cmd --list-all
getenforce

# ── หน้า 201 ────────────────────────────────────────
# สร้าง Backup Script
sudo tee /usr/local/bin/backup-configs.sh > /dev/null << 'EOF'

# ── หน้า 202 ────────────────────────────────────────
sudo chmod 700 /usr/local/bin/backup-configs.sh
# รัน Backup ครั้งแรก
sudo /usr/local/bin/backup-configs.sh
# ตั้ง Cron Job
echo "0 2 * * * /usr/local/bin/backup-configs.sh >> /var/log/backup.log 2>&1" | sudo tee -a /var/spool/cron/root

# ── หน้า 203 ────────────────────────────────────────
echo "=== Server Handover Checklist ==="
echo ""
# 1. OS
echo -n "[1] OS: "
cat /etc/os-release | grep "PRETTY_NAME" | cut -d'"' -f2
# 2. sudo user
echo -n "[2] sudo user: "
id admin01 | grep -q wheel && echo "admin01 OK (wheel)" ||
echo "FAIL"
# 3. SSH Port
echo -n "[3] SSH Port: "
grep "^Port" /etc/ssh/sshd_config
# 4. Password Auth
echo -n "[4] Password Auth: "
grep "^PasswordAuthentication" /etc/ssh/sshd_config

# ── หน้า 204 ────────────────────────────────────────
# 5. Root Login
echo -n "[5] Root Login: "
grep "^PermitRootLogin" /etc/ssh/sshd_config
# 6. Firewall
echo -n "[6] Firewall Ports: "
sudo firewall-cmd --list-ports
echo -n "    Firewall Services: "
sudo firewall-cmd --list-services
# 7. SELinux
echo -n "[7] SELinux: "
getenforce
# 8. Auto-update
echo -n "[8] Auto-update: "
systemctl is-active dnf-automatic-install.timer
# 9. Backup
echo -n "[9] Backup: "
ls /backup/*.tar.gz 2>/dev/null | tail -1 || echo "NO BACKUP FOUND"

# ── หน้า 205 ────────────────────────────────────────
# 10. IP Address
echo -n "[10] IP Address: "
hostname -I | awk '{print $1}'
echo ""
echo "=== Checklist Complete ==="
=== Server Handover Checklist ===
[1] OS: Rocky Linux 9.x (Blue Onyx)
[2] sudo user: admin01 OK (wheel)
[3] SSH Port: Port 2222
[4] Password Auth: PasswordAuthentication no
[5] Root Login: PermitRootLogin no
[6] Firewall Ports: 2222/tcp
Firewall Services: http https
[7] SELinux: Enforcing
[8] Auto-update: active
[9] Backup: /backup/server-config-20250115-1430.tar.gz
[10] IP Address: 192.168.1.100
=== Checklist Complete ===

# ── หน้า 206 ────────────────────────────────────────
☐ 1
OS ติดตั้งสำเร็จ Rocky Linux 9 Minimal
☐ 2
sudo user พร้อมใช้งาน (ไม่ใช้ root โดยตรง)
☐ 3
SSH Login ด้วย Key เท่านั้น (Password ปิด)
☐ 4
SSH อยู่บน Port ที่ไม่ใช่ 22
☐ 5
PermitRootLogin no
☐ 6
AllowUsers จำกัดเฉพาะ User ที่ต้องการ
☐ 7
Firewall เปิดเฉพาะ Port ที่จำเป็น
☐ 8
SELinux อยู่ใน Enforcing Mode
☐ 9
☐ 10
