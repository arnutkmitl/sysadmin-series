# ไฟล์ประกอบหนังสือ Docker & Container Essentials

SysAdmin Pocket Series M06 โดย ดร.อาณัติ รัตนถิรกุล (อ.หมวกแดง) สำนักพิมพ์ SysAdmin Knowledge Press
ดาวน์โหลดได้ที่ https://github.com/arnutkmitl/sysadmin-series โฟลเดอร์ `M06-Docker-Container-Essentials`

## โฟลเดอร์

| โฟลเดอร์ | เนื้อหา |
|---|---|
| `stacks/` | Stack พร้อม deploy 6 ชุดจากบทที่ 2: wordpress, lemp, monitoring, gitlab, nextcloud, portainer |
| `ch01/lab14/` | Nginx กับ PHP-FPM บน network เดียวกัน (Lab 1.4) |
| `ch02/web-php/` | Lab 1.4 ในรูป compose.yaml |
| `ch03/` | pinger (CMD กับ ENTRYPOINT), node-app (multi-stage), nginx-custom (Lab 3.1), registry |
| `ch04/update-demo/` | ตัวอย่างอัปเดตและย้อนรุ่นด้วย .env |
| `capstone/` | โปรเจกต์จบเล่ม พร้อม check-stack.sh ตรวจรับ 18 ข้อ |
| `snippets/` | compose-snippets.yaml รวม snippet ของภาคผนวก ข ที่ทดสอบแล้ว |
| `configs/etc/docker/daemon.json` | ค่าตั้งของ Docker daemon จากบทที่ 3 และ 4 |
| `commands/chNN.sh` | คำสั่งที่พิมพ์ใน terminal ของแต่ละบท รวม 265 คำสั่ง ไม่ใช่สคริปต์ ให้คัดลอกทีละคำสั่ง |

## เริ่ม stack

```
cp -r stacks/wordpress ~/stacks/
cd ~/stacks/wordpress
cp .env.example .env
head -c 18 /dev/urandom | base64 > secrets/db_password.txt
head -c 18 /dev/urandom | base64 > secrets/db_root_password.txt
chmod 700 secrets && chmod 644 secrets/*.txt
docker compose up -d
```

ทุก stack มี `.env.example` ให้คัดลอกเป็น `.env` แล้วแก้รหัสผ่านก่อน up ไฟล์ `.env` และไฟล์ใน `secrets/`
ไม่อยู่ในชุดดาวน์โหลดและถูกตัดออกจาก Git ด้วย `.gitignore` ของแต่ละโฟลเดอร์

## โปรเจกต์จบเล่ม

```
cp -r capstone ~/capstone && cd ~/capstone
cp .env.example .env    # แก้ DB_PASSWORD
docker compose up -d --build
./check-stack.sh
```

## ก่อนใช้งาน

- image ทุกตัวระบุรุ่นไว้แล้ว ตรวจรุ่นใหม่บน Docker Hub ก่อนนำไปใช้จริง และสแกนด้วย Trivy ตามบทที่ 4
- รหัสผ่านในคำสั่งเป็นค่าของ Lab ให้เปลี่ยนทุกตัวก่อนใช้กับ server จริง
- อ่านคำเตือน ⚠️ ในเล่มก่อนรันคำสั่งที่ลบ volume, prune หรือแก้ /etc/docker/daemon.json

ทดสอบบน Rocky Linux 10.2 กับ Docker 29.9.3 และ Compose v5.7.1 และตรวจขั้นตอนติดตั้ง
บน Ubuntu Server 26.04 เมื่อ 11 พฤศจิกายน 2569
