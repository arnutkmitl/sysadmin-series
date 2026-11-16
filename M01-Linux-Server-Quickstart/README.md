# ชุดคำสั่ง Linux Server Quickstart ฉบับปรับปรุง

SysAdmin Pocket Series M01 โดย ดร.อาณัติ รัตนถิรกุล (อ.หมวกแดง) สำนักพิมพ์ SysAdmin Knowledge Press

ชุดนี้รวมคำสั่งทุกบรรทัดในเล่มฉบับปรับปรุง (Rocky Linux 10.2) ไว้ให้คัดลอกได้โดยไม่ต้องพิมพ์ตาม เรียงตามบทและหัวข้อเดียวกับในเล่ม
ดาวน์โหลดได้ที่ https://github.com/arnutkmitl/sysadmin-series โฟลเดอร์ `M01-Linux-Server-Quickstart` รวม 1461 คำสั่ง

## วิธีใช้

1. เปิดไฟล์ของบทที่กำลังอ่านใน editor แล้วคัดลอกทีละคำสั่งไปวางใน terminal
2. อ่านคำอธิบายในเล่มก่อนรันทุกครั้ง โดยเฉพาะคำสั่งที่มี ⚠️ กำกับ
3. ไฟล์ใน `commands/` ไม่ใช่สคริปต์ ถ้าเผลอสั่งรันทั้งไฟล์ ไฟล์จะหยุดตั้งแต่บรรทัดแรก ๆ โดยไม่รันคำสั่งใด
4. บรรทัดที่ขึ้นต้นด้วย `# [Host PC]` รันใน PowerShell บน Windows ส่วน `# [Ubuntu]` คือคำสั่งในกล่อง Ubuntu
5. ไฟล์ใน `scripts/` เป็นสคริปต์ที่รันได้ทั้งไฟล์ วางตาม path ที่ระบุในบรรทัดที่สองของไฟล์

## ค่าของ Lab

| ค่าในเล่ม | ความหมาย |
|---|---|
| 192.168.56.10 | server (Rocky Linux 10.2) วง Host-only |
| 192.168.56.1 | Host PC |
| 2222 | พอร์ต SSH หลัง Hardening ในบทที่ 4 |
| admin | ผู้ใช้ที่มีสิทธิ์ sudo |

## รายการไฟล์

| ไฟล์ | เนื้อหา | จำนวน |
|---|---|---|
| `commands/ch00.sh` | ก่อนเริ่ม: วิธีใช้หนังสือและสิ่งที่ต้องเตรียม | 75 คำสั่ง |
| `commands/ch01.sh` | บทที่ 1 ติดตั้ง Rocky Linux 10 จากเครื่องเปล่าถึง Login | 73 คำสั่ง |
| `commands/ch02.sh` | บทที่ 2 รู้จักระบบ คำสั่งพื้นฐานที่ต้องใช้ทุกวัน | 303 คำสั่ง |
| `commands/ch03.sh` | บทที่ 3 จัดการ Users และ Permissions | 281 คำสั่ง |
| `commands/ch04.sh` | บทที่ 4 เชื่อมต่อ SSH Remote จากที่ไหนก็ได้ | 178 คำสั่ง |
| `commands/ch05.sh` | บทที่ 5 ตั้งค่า Firewall และ SELinux | 193 คำสั่ง |
| `commands/ch06.sh` | บทที่ 6 อัปเดตและ Backup ก่อนเปิดให้โลกเข้าถึง | 189 คำสั่ง |
| `commands/ch07-final-project.sh` | บทที่ 7 โปรเจกต์จบเล่ม: สร้าง Server พร้อมใช้งานใน 60 นาที | 154 คำสั่ง |
| `commands/appendix-c-troubleshooting.sh` | ภาคผนวก ค รวมการแก้ไขปัญหา | 15 คำสั่ง |
| `scripts/backup-configs.sh` | สคริปต์ Backup ของบทที่ 6 วางที่ /usr/local/bin/ แล้ว chmod 700 | - |
| `scripts/handover-check.sh` | สคริปต์ตรวจส่งมอบ 24 ข้อของบทที่ 7 รันได้ทั้งไฟล์ (อ่านค่าอย่างเดียว) | - |
| `cheatsheet.md` | Cheat Sheet ของภาคผนวก ก | - |

## รุ่นซอฟต์แวร์ที่ทดสอบ

Rocky Linux 10.2 (kernel 6.12.0-211.74.1), OpenSSH 9.9p1, firewalld 2.4.3, dnf 4.20, Ubuntu Server 26.04.1 LTS, VirtualBox 7.2.6 บน Windows 11
ทุกคำสั่งทดสอบบน VM เมื่อ 16 พฤศจิกายน 2569
