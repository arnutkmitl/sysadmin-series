#!/usr/bin/env bash
# โปรเจกต์จบเล่ม: Database Server for Web Application
# SysAdmin Pocket Series M07 Database Server: MySQL & PostgreSQL
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── ขั้นที่ 1 ฐานข้อมูลและบัญชีของแอป ───────────────────────
sudo mariadb < capstone/webshop.sql

# ── ขั้นที่ 2 Firewall เฉพาะเครื่องที่ต้องใช้ ───────────────
sudo firewall-cmd --permanent --remove-rich-rule='rule family=ipv4 source address=192.168.56.0/24 port port=3306 protocol=tcp accept'
for ip in 192.168.56.20 192.168.56.41; do sudo firewall-cmd --permanent --add-rich-rule="rule family=ipv4 source address=$ip port port=3306 protocol=tcp accept"; done
sudo firewall-cmd --reload
sudo firewall-cmd --list-rich-rules

# ── ขั้นที่ 3 Backup รายวันและรายสัปดาห์ ────────────────────
sudo install -m 700 capstone/backup-mariadb.sh capstone/backup-mariadb-full.sh /usr/local/bin/
printf "30 2 * * * root /usr/local/bin/backup-mariadb.sh\n0 3 * * 0 root /usr/local/bin/backup-mariadb-full.sh\n" | sudo tee /etc/cron.d/backup-mariadb
sudo /usr/local/bin/backup-mariadb.sh; sudo /usr/local/bin/backup-mariadb-full.sh
sudo tail -5 /var/log/backup-mariadb.log

# ── ขั้นที่ 4 ตรวจรับด้วย check-db.sh ───────────────────────
sudo ./capstone/check-db.sh primary
# บนเครื่อง db2
sudo ./capstone/check-db.sh replica
# บนเครื่อง web
APP_PASSWORD=Web-App-2569 ./capstone/check-db.sh app

# ── ขั้นที่ 5 ซ้อมให้ script จับความผิดปกติ ─────────────────
# บนเครื่อง db2
sudo mariadb -e "STOP SLAVE"
# บนเครื่อง db2
sudo ./capstone/check-db.sh replica; echo "exit=$?"
# บนเครื่อง db2
sudo mariadb -e "START SLAVE"
# บนเครื่อง db2
sudo ./capstone/check-db.sh replica | tail -1
