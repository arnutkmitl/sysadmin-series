# ไฟล์ประกอบหนังสือ Backup & Disaster Recovery

SysAdmin Pocket Series M17 โดย ดร.อาณัติ รัตนถิรกุล (อ.หมวกแดง) สำนักพิมพ์ SysAdmin Knowledge Press
ดาวน์โหลดได้ที่ https://github.com/arnutkmitl/sysadmin-series โฟลเดอร์ `M17-Backup-Disaster-Recovery`

## โฟลเดอร์

| โฟลเดอร์ | เนื้อหา |
|---|---|
| `ch00/` | seed-prod.sh (ข้อมูลตั้งต้นของ prod), setup-bkp.sh (ผู้ใช้และไดเรกทอรีบน bkp) |
| `ch02/` | snap-pull.sh (rsync แบบ bkp ดึง), Borg (borg-env, borg-backup.sh), restic + rest-server, prune-on-bkp.sh |
| `ch03/` | db-dump.sh, db-verify.sh, binlog.cnf ของ MariaDB, wal-archive.conf ของ PostgreSQL |
| `ch04/` | compose.yaml ของ WordPress, docker-backup.sh, docker-restore.sh, SeaweedFS S3, s3-undelete.sh, ransomware-drill.sh |
| `ch05/` | backup-and-notify.sh, systemd service/timer ทุกงาน, LINE mock, node_exporter, Prometheus + Grafana + alert rules |
| `ch06/` | local.conf ของ ReaR, dr-restore-data.sh, check-backup.sh |
| `commands/chNN.sh` | คำสั่งที่พิมพ์ใน terminal ของแต่ละบท รวม 330 คำสั่ง ไม่ใช่สคริปต์ ให้คัดลอกทีละคำสั่ง |

## ก่อนใช้งาน

- เปลี่ยน IP 192.168.56.85 (prod), .86 (bkp) และ .87 (dr) ให้ตรงกับเครื่องของคุณ ทั้งใน config และสคริปต์
- ชุดนี้ไม่มีรหัสผ่านหรือกุญแจใด ๆ สร้าง passphrase ของ Borg, รหัสผ่านของ restic, กุญแจ S3 และ token ของ LINE เองตามบทที่ 2, 4 และ 5 แล้วเก็บสำเนาไว้นอก prod
- ransomware-drill.sh เข้ารหัสและลบไฟล์จริงใน /srv/files ใช้กับเครื่องทดสอบเท่านั้น
- SeaweedFS ต้องปิดพอร์ต 8888, 9333 และ 8080 จากเครือข่าย เพราะ filer API ลบข้อมูลได้โดยไม่ผ่าน object lock (บทที่ 4)
- อ่านคำเตือน ⚠️ ในเล่มก่อนรันคำสั่งที่ลบข้อมูล ย้อน repository หรือปิดเครื่อง

ทดสอบบน Rocky Linux 10.2 กับ rsync 3.5.0, BorgBackup 1.4.5, restic 0.19.1, rest-server 0.14.0, SeaweedFS 4.54,
MariaDB 10.11, PostgreSQL 16, Docker CE, ReaR 2.9, node_exporter 1.12.1, Prometheus v3.16.0 และ Grafana 13.3.1
พร้อมกล่อง Ubuntu Server 26.04 เมื่อ 18 พฤศจิกายน 2569
