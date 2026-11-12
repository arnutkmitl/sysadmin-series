# SysAdmin Pocket Series: ชุดคำสั่งและไฟล์ประกอบหนังสือ

ไฟล์ประกอบหนังสือชุด SysAdmin Pocket Series โดย ดร.อาณัติ รัตนถิรกุล (อ.หมวกแดง) สำนักพิมพ์ SysAdmin Knowledge Press
แต่ละเล่มมีโฟลเดอร์ของตัวเอง ภายในมีคำสั่งทุกบรรทัดในเล่ม ไฟล์ตั้งค่า และสคริปต์ เรียงตามบทเดียวกับหนังสือ
ตอนนี้ดาวน์โหลดได้ 9 จาก 17 เล่ม

## รายชื่อเล่ม

| เล่ม | ชื่อเรื่อง | โฟลเดอร์ | สถานะ |
|---|---|---|---|
| M01 | Linux Server Quickstart: ติดตั้ง Server จริงใน 1 วัน | [`M01-Linux-Server-Quickstart/`](M01-Linux-Server-Quickstart/) | ดาวน์โหลดได้ |
| M02 | Network & Firewall Essentials: ตั้งค่าเครือข่ายและปิดช่องโหว่ใน 1 วัน | [`M02-Network-Firewall-Essentials/`](M02-Network-Firewall-Essentials/) | ดาวน์โหลดได้ |
| M03 | Shell Script Automation: เปลี่ยนงานซ้ำ ๆ เป็น Script อัตโนมัติใน 1 วัน | [`M03-Shell-Script-Automation/`](M03-Shell-Script-Automation/) | ดาวน์โหลดได้ |
| M04 | Python for SysAdmin: เปลี่ยนงาน Admin ให้เป็น Python อัตโนมัติใน 1 วัน | [`M04-Python-for-SysAdmin/`](M04-Python-for-SysAdmin/) | ดาวน์โหลดได้ |
| M05 | Web Server: Apache & Nginx ตั้งเว็บจริงใน 1 วัน | [`M05-Web-Server-Apache-Nginx/`](M05-Web-Server-Apache-Nginx/) | ดาวน์โหลดได้ |
| M06 | Docker & Container Essentials: จาก Install ถึง Production ใน 1 วัน | [`M06-Docker-Container-Essentials/`](M06-Docker-Container-Essentials/) | ดาวน์โหลดได้ |
| M07 | Database Server: MySQL & PostgreSQL ตั้ง DB จริงใน 1 วัน | [`M07-Database-Server-MySQL-PostgreSQL/`](M07-Database-Server-MySQL-PostgreSQL/) | ดาวน์โหลดได้ |
| M08 | DNS & Essential Network Services: ตั้ง DNS Server ใน 1 วัน | [`M08-DNS-Essential-Network-Services/`](M08-DNS-Essential-Network-Services/) | ดาวน์โหลดได้ |
| M09 | VPN Server: เชื่อมเครือข่ายปลอดภัยใน 1 วัน | [`M09-VPN-Server-WireGuard-OpenVPN/`](M09-VPN-Server-WireGuard-OpenVPN/) | ดาวน์โหลดได้ |
| M10 | SSL & Security Hardening: ล็อก Server ให้แน่นใน 1 วัน | `M10-SSL-Security-Hardening/` | กำลังจัดทำ |
| M11 | Proxmox VE: สร้าง Virtual Lab ใน 1 วัน | `M11-Proxmox-VE-Virtualization/` | กำลังจัดทำ |
| M12 | CI/CD & Git Essentials: Deploy อัตโนมัติใน 1 วัน | `M12-CICD-Git-Essentials/` | กำลังจัดทำ |
| M13 | Mail Server: ตั้งระบบอีเมลองค์กรใน 1 วัน | `M13-Mail-Server-Postfix-Dovecot/` | กำลังจัดทำ |
| M14 | Monitoring with Grafana & Prometheus: สร้างระบบ Monitoring จาก 0 ใน 1 วัน | `M14-Monitoring-Grafana-Prometheus/` | กำลังจัดทำ |
| M15 | Ansible Automation: จัดการ Server 10 เครื่องเหมือน 1 เครื่อง | `M15-Ansible-Automation/` | กำลังจัดทำ |
| M16 | Reverse Proxy & Load Balancer: Nginx, HAProxy, Traefik ครบใน 1 วัน | `M16-Reverse-Proxy-Load-Balancer/` | กำลังจัดทำ |
| M17 | Backup & Disaster Recovery: อย่าให้ข้อมูลหายเป็นอันขาด | `M17-Backup-Disaster-Recovery/` | กำลังจัดทำ |

## วิธีดาวน์โหลด

**ทั้งชุด** กดปุ่ม Code แล้วเลือก Download ZIP หรือใช้ git

```
git clone https://github.com/arnutkmitl/sysadmin-series.git
```

**เฉพาะเล่มเดียว** ใช้ sparse checkout ของ git ตัวอย่างนี้ดึงเฉพาะเล่ม M02

```
git clone --filter=blob:none --sparse https://github.com/arnutkmitl/sysadmin-series.git
cd sysadmin-series
git sparse-checkout set M02-Network-Firewall-Essentials
```

เมื่อเล่มใหม่ออก ให้เพิ่มชื่อโฟลเดอร์ต่อท้ายคำสั่งเดิม เช่น `git sparse-checkout add M05-Web-Server-Apache-Nginx` แล้วสั่ง `git pull` เพื่อรับไฟล์ที่แก้ไขล่าสุด

**ไฟล์เดียว** เปิดไฟล์บนเว็บ GitHub แล้วกดปุ่ม Download raw file หรือ Copy raw file

## ก่อนใช้งาน

- ไฟล์ในโฟลเดอร์ `linux/` และ `windows/` ของแต่ละเล่มเป็นไฟล์รวมคำสั่ง ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในหนังสือ
- คำสั่งที่มี ⚠️ กำกับอาจลบข้อมูล ตัดการเชื่อมต่อ หรือทำให้เข้าเครื่องไม่ได้ อ่านคำเตือนก่อนรันทุกครั้ง
- ทดลองใน VM ที่ถ่าย snapshot ไว้ก่อนใช้กับเครื่องจริง
- README ในโฟลเดอร์ของแต่ละเล่มบอกค่าที่ต้องเปลี่ยนให้ตรงเครื่องของคุณ

## แจ้งปัญหา

พบคำสั่งที่ใช้ไม่ได้หรือผลไม่ตรงกับในเล่ม แจ้งได้ที่ [Issues](https://github.com/arnutkmitl/sysadmin-series/issues) ระบุเล่ม บท และรุ่นของระบบปฏิบัติการที่ใช้
