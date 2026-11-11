#!/usr/bin/env bash
# บทที่ 6 อัปเดตและ Backup ก่อนเปิดให้โลกเข้าถึง
# SysAdmin Pocket Series M01 Linux Server Quickstart
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# "หน้า N" คือเลขหน้าที่พิมพ์ในหนังสือ
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── หน้า 176 ────────────────────────────────────────
# อัปเดต Package ทั้งหมดเป็นเวอร์ชันล่าสุด
sudo dnf update -y

# ── หน้า 177 ────────────────────────────────────────
# ตรวจสอบว่ามี Update อะไรบ้างก่อนติดตั้ง (ไม่ติดตั้ง แค่ตรวจสอบ)
dnf check-update
# ตรวจสอบเฉพาะ Security Update
dnf updateinfo list security
# ติดตั้ง needs-restarting tool
sudo dnf install -y dnf-utils
# ตรวจสอบว่าต้อง Reboot หรือไม่
sudo needs-restarting -r
sudo reboot
# ติดตั้ง dnf-automatic
sudo dnf install -y dnf-automatic

# ── หน้า 178 ────────────────────────────────────────
sudo nano /etc/dnf/automatic.conf
[commands]
# ให้ดาวน์โหลด Update อัตโนมัติ
download_updates = yes
# ให้ติดตั้ง Update อัตโนมัติ
apply_updates = yes
# ประเภท Update ที่ต้องการ (default = ทุกประเภท, security = upgrade_type = default
[emitters]
# ส่งรายงานผ่าน stdio (บันทึกลง Log)
emit_via = stdio

# ── หน้า 179 ────────────────────────────────────────
# เปิด Timer สำหรับ Auto-install
sudo systemctl enable --now dnf-automatic-install.timer
# ตรวจสอบว่า Timer ทำงาน
sudo systemctl status dnf-automatic-install.timer

# ── หน้า 180 ────────────────────────────────────────
# ตรวจสอบว่า Timer ถัดไปจะรันเมื่อไหร่
systemctl list-timers dnf-automatic*

# ── หน้า 181 ────────────────────────────────────────
# ตรวจสอบ Log ว่า Auto-update ติดตั้งอะไรไปบ้าง
sudo journalctl -u dnf-automatic-install.service
# ตรวจสอบ Log ของ dnf ทั้งหมด
sudo cat /var/log/dnf.log | tail -50
# รูปแบบมาตรฐาน
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%Y%m%d)

# ── หน้า 182 ────────────────────────────────────────
# ตัวอย่างการใช้งานจริง
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%Y%m%d)
sudo nano /etc/ssh/sshd_config
# แก้ไข Config ...
# ถ้าทุกอย่างเรียบร้อย ก็ทำงานต่อ
# ถ้ามีปัญหา กู้คืนด้วย
sudo cp /etc/ssh/sshd_config.bak.20250115 /etc/ssh/sshd_config
sudo systemctl restart sshd
echo 'bak() { sudo cp "$1" "$1.bak.$(date +%Y%m%d%H%M)"; }' >> ~/.bashrc
source ~/.bashrc
bak /etc/ssh/sshd_config
# สร้าง /etc/ssh/sshd_config.bak.202501151430

# ── หน้า 183 ────────────────────────────────────────
# สร้าง Directory สำหรับเก็บ Backup
sudo mkdir -p /backup
# สำรอง /etc ทั้งหมดเป็นไฟล์ tar.gz
sudo tar czf /backup/etc-backup-$(date +%Y%m%d).tar.gz /etc
# ตรวจสอบขนาดไฟล์
ls -lh /backup/
# ตรวจสอบรายการไฟล์ภายใน Backup (ไม่ต้อง Extract)
sudo tar tzf /backup/etc-backup-20250115.tar.gz | head -20
# กู้คืนไฟล์เฉพาะตัว
sudo tar xzf /backup/etc-backup-20250115.tar.gz -C /
etc/ssh/sshd_config
# กู้คืน /etc ทั้ง Directory (ระวัง จะ Overwrite Config ปัจจุบันทั้งหมด)
sudo tar xzf /backup/etc-backup-20250115.tar.gz -C /

# ── หน้า 184 ────────────────────────────────────────
sudo nano /usr/local/bin/backup-configs.sh
#!/bin/bash
# backup-configs.sh
# สำรอง Configuration ที่สำคัญของ Server
BACKUP_DIR="/backup"
DATE=$(date +%Y%m%d-%H%M)
BACKUP_FILE="${BACKUP_DIR}/server-config-${DATE}.tar.gz"
# สร้าง Directory ถ้ายังไม่มี
mkdir -p ${BACKUP_DIR}
# สำรองไฟล์ที่สำคัญ
tar czf ${BACKUP_FILE} \
/etc/ssh/sshd_config \
/etc/firewalld/ \
/etc/selinux/config \
/etc/sudoers.d/ \
/etc/dnf/automatic.conf \
/etc/hostname \

# ── หน้า 185 ────────────────────────────────────────
/etc/hosts \
/etc/passwd \
/etc/group \
/etc/shadow \
2>/dev/null
# แสดงผลลัพธ์
echo "Backup สำเร็จ: ${BACKUP_FILE}"
echo "ขนาด: $(ls -lh ${BACKUP_FILE} | awk '{print $5}')"
# ลบ Backup ที่เก่ากว่า 30 วัน
find ${BACKUP_DIR} -name "server-config-*.tar.gz" -mtime +30 -delete
echo "ลบ Backup ที่เก่ากว่า 30 วันแล้ว"
sudo chmod 700 /usr/local/bin/backup-configs.sh
# ทดสอบ
sudo /usr/local/bin/backup-configs.sh

# ── หน้า 186 ────────────────────────────────────────
# เปิด Crontab สำหรับ root
sudo crontab -e
# Backup Config ทุกวันตอนตี 2
0 2 * * * /usr/local/bin/backup-configs.sh >> /var/log/backup.log 2>&1
sudo crontab -l

# ── หน้า 188 ────────────────────────────────────────
VBoxManage snapshot "Rocky9-Lab" take "Before-Hardening" --description "ก่อนทำ SSH Hardening"
# ตรวจสอบรายการ Snapshot
VBoxManage snapshot "Rocky9-Lab" list
# Revert ไป Snapshot (กรณีมีปัญหา)
VBoxManage snapshot "Rocky9-Lab" restore "Before-Hardening"

# ── หน้า 189 ────────────────────────────────────────
# ลบ Snapshot (บนเครื่อง Host)
VBoxManage snapshot "Rocky9-Lab" delete "Before-Hardening"

# ── หน้า 190 ────────────────────────────────────────
# ติดตั้ง (ถ้ายังไม่มี)
sudo apt install -y unattended-upgrades
# ตั้งค่า
sudo dpkg-reconfigure unattended-upgrades
sudo nano /etc/apt/apt.conf.d/50unattended-upgrades
// อัปเดต Security Patch อัตโนมัติ (เปิดเป็นค่าเริ่มต้น)
Unattended-Upgrade::Allowed-Origins {
"${distro_id}:${distro_codename}-security";
};
// Reboot อัตโนมัติถ้าจำเป็น (ปกติปิดอยู่)
// Unattended-Upgrade::Automatic-Reboot "true";
// Unattended-Upgrade::Automatic-Reboot-Time "02:00";

# ── หน้า 191 ────────────────────────────────────────
sudo systemctl status unattended-upgrades
# อัปเดต Package List + ติดตั้ง Update
sudo apt update && sudo apt upgrade -y
# ตรวจสอบว่าต้อง Reboot หรือไม่
[ -f /var/run/reboot-required ] && echo "Reboot required" || echo "No reboot needed"
Rocky Linux
Ubuntu

# ── หน้า 193 ────────────────────────────────────────
systemctl is-active dnf-automatic-install.timer
# ต้องได้ active
