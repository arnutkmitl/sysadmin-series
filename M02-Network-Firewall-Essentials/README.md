# ชุดคำสั่งและไฟล์ตั้งค่า Network & Firewall Essentials

SysAdmin Pocket Series M02 โดย ดร.อาณัติ รัตนถิรกุล (อ.หมวกแดง) สำนักพิมพ์ SysAdmin Knowledge Press

ชุดนี้รวมคำสั่งทุกบรรทัดในเล่มไว้ให้คัดลอกได้โดยไม่ต้องพิมพ์ตาม เรียงตามบทและหัวข้อเดียวกับในเล่ม
ดาวน์โหลดได้ที่ https://github.com/arnutkmitl/sysadmin-series โฟลเดอร์ `M02-Network-Firewall-Essentials`
รวมคำสั่ง Linux 235 คำสั่ง คำสั่งฝั่ง Windows 13 คำสั่ง และไฟล์ตั้งค่า 4 ไฟล์

## วิธีใช้

1. เปิดไฟล์ของบทที่กำลังอ่านใน editor แล้วคัดลอกทีละคำสั่งไปวางใน terminal
2. อ่านคำอธิบายในเล่มก่อนรันทุกครั้ง โดยเฉพาะคำสั่งที่มี ⚠️ กำกับ
3. ไฟล์ใน `linux/` และ `windows/` ไม่ใช่สคริปต์ ถ้าเผลอสั่งรันทั้งไฟล์ ไฟล์จะหยุดตั้งแต่บรรทัดแรก ๆ โดยไม่รันคำสั่งใด
4. ไฟล์ใน `configs/` คัดลอกไปวางตาม path ในชื่อโฟลเดอร์ เช่น `configs/rocky/etc/fail2ban/jail.local` คือ `/etc/fail2ban/jail.local` บนเครื่อง Rocky Linux
5. ไฟล์ที่ลงท้ายด้วย `.snippet` เป็นเพียงบรรทัดที่ต้องแก้ในไฟล์เดิมของระบบ ห้ามคัดลอกทับทั้งไฟล์

## ป้ายในไฟล์คำสั่ง

- ไม่มีป้าย คือรันบน server (Rocky Linux 10)
- `# [client]` คือรันบนเครื่อง client
- `# [Ubuntu]` คือคำสั่งในกล่อง Ubuntu สำหรับ Ubuntu Server 26.04
- คำสั่งฝั่ง Host PC (VirtualBox, PowerShell) แยกไว้ใน `windows/`

## ค่าที่ต้องเปลี่ยนให้ตรงเครื่องของคุณ

ตัวอย่างในเล่มใช้ค่าของ Lab ตามตารางที่ 0-1 ถ้าเครื่องของคุณต่างจากนี้ ให้แก้ก่อนรัน

| ค่าในเล่ม | ความหมาย |
|---|---|
| 192.168.56.10 / 192.168.56.20 | server และ client วง management |
| 192.168.57.10 / 192.168.57.20 | server และ client วง service |
| 192.168.57.1 | Host PC (เครื่องผู้ดูแลระบบ) |
| enp0s3, enp0s8, enp0s9 | ชื่อการ์ดบน VirtualBox (VMware มักเป็น ens33 หรือ ens160) |
| 2222 | พอร์ต SSH ที่ย้ายมาตั้งแต่ M01 |
| admin | ผู้ใช้ที่มีสิทธิ์ sudo |

## รายการไฟล์

| ไฟล์ | เนื้อหา | จำนวน |
|---|---|---|
| `linux/ch00-before-you-start.sh` | ก่อนเริ่ม: วิธีใช้หนังสือและเตรียม Lab | 4 คำสั่ง |
| `windows/ch00-before-you-start-host-pc.ps1` | ก่อนเริ่ม: วิธีใช้หนังสือและเตรียม Lab | 9 คำสั่ง |
| `linux/ch01-network-basics.sh` | บทที่ 1 เข้าใจ Network บน Linux | 14 คำสั่ง |
| `linux/ch02-networkmanager.sh` | บทที่ 2 ตั้งค่า Network ด้วย NetworkManager | 45 คำสั่ง |
| `windows/ch02-networkmanager-host-pc.ps1` | บทที่ 2 ตั้งค่า Network ด้วย NetworkManager | 2 คำสั่ง |
| `configs/ubuntu/etc/netplan/60-lab.yaml` | ไฟล์ตั้งค่าจากบทที่ 2 ตั้งค่า Network ด้วย NetworkManager | - |
| `linux/ch03-firewalld.sh` | บทที่ 3 Firewall ขั้นกลาง: firewalld Zone และ Rich Rules | 73 คำสั่ง |
| `windows/ch03-firewalld-host-pc.ps1` | บทที่ 3 Firewall ขั้นกลาง: firewalld Zone และ Rich Rules | 1 คำสั่ง |
| `linux/ch04-ntp-dns.sh` | บทที่ 4 ตั้งเวลาและชื่อ: NTP และ DNS Client | 38 คำสั่ง |
| `configs/rocky/etc/chrony.conf.snippet` | ไฟล์ตั้งค่าจากบทที่ 4 ตั้งเวลาและชื่อ: NTP และ DNS Client | - |
| `linux/ch05-fail2ban.sh` | บทที่ 5 Fail2ban ป้องกัน Brute Force อัตโนมัติ | 23 คำสั่ง |
| `configs/rocky/etc/fail2ban/jail.local` | ไฟล์ตั้งค่าจากบทที่ 5 Fail2ban ป้องกัน Brute Force อัตโนมัติ | - |
| `configs/ubuntu/etc/fail2ban/jail.local` | ไฟล์ตั้งค่าจากบทที่ 5 Fail2ban ป้องกัน Brute Force อัตโนมัติ | - |
| `linux/ch06-troubleshooting.sh` | บทที่ 6 Troubleshooting Network เมื่อ Network ล่ม | 25 คำสั่ง |
| `linux/ch07-final-project.sh` | โปรเจกต์จบเล่ม: Secure Network สำหรับ Web Server | 4 คำสั่ง |
| `windows/ch07-final-project-host-pc.ps1` | โปรเจกต์จบเล่ม: Secure Network สำหรับ Web Server | 1 คำสั่ง |
| `linux/app-c-subnet.sh` | ภาคผนวก ค Private IP และ Subnet Reference | 1 คำสั่ง |
| `linux/app-d-resources.sh` | ภาคผนวก ง แหล่งเรียนรู้เพิ่มเติม | 8 คำสั่ง |
| `scripts/web01-handover.sh` | ชุดตรวจส่งมอบ server (บทที่ 7) รันได้ทั้งไฟล์ | - |

## รุ่นซอฟต์แวร์ที่ทดสอบ

Rocky Linux 10.2, NetworkManager 1.56.0, firewalld 2.4.3, chrony 4.8, Fail2ban 1.1.0 (EPEL), Ubuntu Server 26.04.1 LTS
ทุก Lab ทดสอบบน VirtualBox เมื่อ 11 พฤศจิกายน 2569
