# ไฟล์ตั้งค่าและคำสั่งประกอบหนังสือ Web Server: Apache & Nginx

SysAdmin Pocket Series M05 โดย ดร.อาณัติ รัตนถิรกุล (อ.หมวกแดง) สำนักพิมพ์ SysAdmin Knowledge Press
ดาวน์โหลดได้ที่ https://github.com/arnutkmitl/sysadmin-series โฟลเดอร์ `M05-Web-Server-Apache-Nginx`

## โฟลเดอร์

| โฟลเดอร์ | เนื้อหา |
|---|---|
| `configs/chNN/` | ไฟล์ตั้งค่าทุกไฟล์ในเล่ม 27 ไฟล์ วางตาม path จริงบน Rocky Linux แยกตามบท เพราะบางไฟล์ถูกแก้ต่อในบทถัดไป |
| `snippets/` | Nginx snippets จากภาคผนวก ข 5 ชุด |
| `scripts/check-sites.sh` | Script ตรวจรับโปรเจกต์จบเล่ม 23 ข้อ |
| `scripts/setup-pebble.sh` | เตรียม Pebble (ACME server สำหรับทดสอบ) ใช้กับ Lab HTTPS บทที่ 3 |
| `commands/chNN.sh` | คำสั่งที่พิมพ์ใน terminal ของแต่ละบท รวม 242 คำสั่ง ไฟล์เหล่านี้ไม่ใช่สคริปต์ ให้คัดลอกทีละคำสั่ง |

## วิธีใช้ไฟล์ตั้งค่า

```
sudo cp configs/ch05/etc/nginx/conf.d/static.conf /etc/nginx/conf.d/
sudo nginx -t && sudo systemctl reload nginx
```

แก้ชื่อเว็บ (server_name, ServerName) และ path ของใบรับรองให้ตรงกับเครื่องก่อน reload ทุกครั้ง
บน Ubuntu ให้วางไฟล์ของ Nginx ใน /etc/nginx/sites-available แล้ว ln -s ไปที่ sites-enabled
และไฟล์ของ Apache ใน /etc/apache2/sites-available แล้วใช้ a2ensite ตามกล่อง Ubuntu ในเล่ม

## Lab HTTPS ด้วย Pebble

```
sudo ./scripts/setup-pebble.sh
export REQUESTS_CA_BUNDLE=/opt/pebble/certs/pebble.minica.pem
sudo --preserve-env=REQUESTS_CA_BUNDLE certbot --nginx --server https://localhost:14000/dir -d site1.lab.test
```

Pebble ใช้กับเครื่องทดลองเท่านั้น server จริงที่มีโดเมนใช้ certbot กับ Let's Encrypt ตรงโดยตัด --server
และ REQUESTS_CA_BUNDLE ออก รีบูตเครื่องทดลองแล้วให้รัน setup-pebble.sh ใหม่และต่ออายุใบเดิมด้วย
certbot renew --force-renewal --no-random-sleep-on-renew

## ก่อนใช้งาน

- รหัสผ่านในไฟล์และคำสั่งเป็นค่าของ Lab ให้เปลี่ยนทุกตัวก่อนใช้กับ server จริง
- อ่านคำเตือน ⚠️ ในเล่มก่อนรันคำสั่งที่หยุด service เปลี่ยนสิทธิ์ไฟล์ หรือปิด SELinux บางส่วน

ทดสอบบน Rocky Linux 10.2 (Apache 2.4.63, Nginx 1.26.3, PHP 8.3, certbot 5.10) และตรวจคำสั่ง
บน Ubuntu Server 26.04 (Apache 2.4.66, Nginx 1.28.3, PHP 8.5) เมื่อ 11 พฤศจิกายน 2569
