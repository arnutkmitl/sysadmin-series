# Script และคำสั่งประกอบหนังสือ Shell Script Automation

SysAdmin Pocket Series M03 โดย ดร.อาณัติ รัตนถิรกุล (อ.หมวกแดง) สำนักพิมพ์ SysAdmin Knowledge Press
ดาวน์โหลดได้ที่ https://github.com/arnutkmitl/sysadmin-series โฟลเดอร์ `M03-Shell-Script-Automation`

## โฟลเดอร์

| โฟลเดอร์ | เนื้อหา |
|---|---|
| `production/` | lib.sh, Script สำเร็จรูป 10 ตัวจากบทที่ 6, template.sh, acceptance.sh และไฟล์ตั้งค่าใน `etc/` |
| `labs/chNN/` | Script ตัวอย่างและเฉลย Lab ของแต่ละบท รวม 10 ไฟล์ |
| `commands/chNN.sh` | คำสั่งที่พิมพ์ใน terminal ของแต่ละบท รวม 122 คำสั่ง ไฟล์เหล่านี้ไม่ใช่สคริปต์ ให้คัดลอกทีละคำสั่ง |

## ติดตั้งชุด production

```
sudo install -D -m 644 production/lib.sh /usr/local/lib/sysadmin/lib.sh
sudo install -m 755 production/server-health.sh /usr/local/bin/
sudo /usr/local/bin/server-health.sh
```

ทุก Script มีส่วน "ตัวแปรที่ต้องแก้" อยู่บนสุด แก้ให้ตรงเครื่องก่อนรัน บน Rocky Linux ให้เรียกด้วย path เต็ม
เพราะ secure_path ของ sudo ไม่มี /usr/local/bin ไฟล์ `production/etc/` คัดลอกไปวางตาม path ใต้ /etc

## ก่อนใช้งาน

- ทดสอบบน VM ที่ถ่าย snapshot ไว้ก่อนใช้กับ server จริง
- อ่านคำเตือน ⚠️ ในเล่มก่อนรัน Script ที่ลบไฟล์ (backup-config.sh, backup-database.sh, log-rotate-custom.sh)
  และ Script ที่ reboot หรือย้อนโค้ด (system-update.sh, quick-deploy.sh)
- ตัวอย่าง clean-logs.sh และ no-safety.sh ในเล่มตั้งใจเขียนให้ผิด จึงไม่อยู่ในชุดนี้

ทดสอบบน Rocky Linux 10.2 (Bash 5.2, ShellCheck 0.10) และตรวจ ShellCheck 0.11 บน Ubuntu 26.04 เมื่อ 11 พฤศจิกายน 2569
