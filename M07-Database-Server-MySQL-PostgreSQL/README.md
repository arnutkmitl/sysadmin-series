# ไฟล์ประกอบหนังสือ Database Server: MySQL & PostgreSQL

SysAdmin Pocket Series M07 โดย ดร.อาณัติ รัตนถิรกุล (อ.หมวกแดง) สำนักพิมพ์ SysAdmin Knowledge Press
ดาวน์โหลดได้ที่ https://github.com/arnutkmitl/sysadmin-series โฟลเดอร์ `M07-Database-Server-MySQL-PostgreSQL`

## โฟลเดอร์

| โฟลเดอร์ | เนื้อหา |
|---|---|
| `ch01/backup-mariadb.sh` | สำรองทุก database ของ MariaDB รายวัน (หัวข้อ 1.4) วางที่ /usr/local/bin |
| `ch02/roles.sql` | role, schema และสิทธิ์ของ PostgreSQL (หัวข้อ 2.3) |
| `ch03/db-maintenance.sh` | งานบำรุงรักษาประจำสัปดาห์ของทั้ง MariaDB และ PostgreSQL (หัวข้อ 3.3) |
| `configs/etc/my.cnf.d/` | ไฟล์ตั้งค่า MariaDB ของ db1 (90-server, 91-replication, 92-slowlog, 93-audit) และ 91-replica.cnf ของ db2 |
| `configs/var/lib/pgsql/data/pg_hba.conf` | pg_hba.conf ของ db1 จากหัวข้อ 2.2 |
| `capstone/` | โปรเจกต์จบเล่ม: webshop.sql, script backup ทั้งสองแบบ และ check-db.sh ตรวจรับ 31 ข้อ |
| `commands/chNN.sh` | คำสั่งที่พิมพ์ใน terminal ของแต่ละบท รวม 211 คำสั่ง ไม่ใช่สคริปต์ ให้คัดลอกทีละคำสั่ง |

## โปรเจกต์จบเล่ม

```
sudo mariadb < capstone/webshop.sql
sudo install -m 700 capstone/backup-mariadb.sh capstone/backup-mariadb-full.sh /usr/local/bin/
sudo ./capstone/check-db.sh primary                     # บน db1
sudo ./capstone/check-db.sh replica                     # บน db2
APP_PASSWORD=... ./capstone/check-db.sh app             # บนเครื่องแอป
```

แก้ IP และชื่อผู้ใช้ที่ต้นไฟล์ check-db.sh ให้ตรงกับเครื่องของคุณก่อนรัน

## ก่อนใช้งาน

- รหัสผ่านในไฟล์และคำสั่งทั้งหมดเป็นค่าของ Lab ให้เปลี่ยนทุกตัวก่อนใช้กับ server จริง
- ไฟล์ใน configs/ คัดลอกไปวางตาม path เดียวกันบนเครื่อง ไฟล์ใน /var/lib/pgsql/data ให้คัดลอกในชื่อผู้ใช้ postgres
- อ่านคำเตือน ⚠️ ในเล่มก่อนรันคำสั่งที่ลบข้อมูลหรือย้ายโฟลเดอร์ข้อมูล

ทดสอบบน Rocky Linux 10.2 กับ MariaDB 11.8.8 และ PostgreSQL 18.6 และตรวจขั้นตอนติดตั้งบน
Ubuntu Server 26.04 เมื่อ 12 พฤศจิกายน 2569
