# ไฟล์ประกอบหนังสือ Mail Server

SysAdmin Pocket Series M13 โดย ดร.อาณัติ รัตนถิรกุล (อ.หมวกแดง) สำนักพิมพ์ SysAdmin Knowledge Press
ดาวน์โหลดได้ที่ https://github.com/arnutkmitl/sysadmin-series โฟลเดอร์ `M13-Mail-Server-Postfix-Dovecot`

## โฟลเดอร์

| โฟลเดอร์ | เนื้อหา |
|---|---|
| `ch02/` | setup-pebble.sh (ACME server สำหรับ Lab), add-mailuser.sh, local.conf ของ Dovecot 2.3 (Rocky) และ 2.4 (Ubuntu) |
| `ch03/` | server block ของ Nginx, config.inc.php ของ Roundcube (Rocky และ tarball บน Ubuntu), 99-roundcube.ini, config-v1.1.xml ของ autoconfig |
| `ch04/` | local.cf ของ SpamAssassin, junk.sieve และบล็อก Sieve ของ Dovecot |
| `ch05/` | add-mailuser.sh รุ่น userdb passwd-file, quota ของ Dovecot 2.3 และ 2.4, backup-mail.sh, timer สามชุด, compose.yaml และ mailserver.env ของ docker-mailserver |
| `ch06/` | check-mail.sh ตรวจ 33 ข้อ และ local.conf ของ mail2 |
| `final/` | ค่าตั้งจริงเมื่อจบเล่มของ mail1, mail2 และ zone ของ ns1 (ไม่มีกุญแจลับ) |
| `commands/chNN.sh` | คำสั่งที่พิมพ์ใน terminal และ PowerShell ของแต่ละบท รวม 466 คำสั่ง ไม่ใช่สคริปต์ ให้คัดลอกทีละคำสั่ง |

## เริ่มใช้

```
sudo ./ch06/check-mail.sh -v                   # ตรวจ mail server ของเครื่องนี้ 33 ข้อ
sudo DOMAIN=example.org ./ch06/check-mail.sh   # ระบุโดเมนเอง
sudo ./ch05/add-mailuser.sh somchai@example.com
```

## ก่อนใช้งาน

- เปลี่ยน example.com, mail.example.com และ IP 192.168.56.x ให้ตรงกับของคุณทุกไฟล์
- setup-pebble.sh และบรรทัด REQUESTS_CA_BUNDLE ใน certbot-renew.service ใช้ใน Lab เท่านั้น บน server จริงใช้ Let's Encrypt ตรง
- config.inc.php มีค่า DES_KEY_PLACEHOLDER ให้สุ่มใหม่ด้วย `openssl rand -base64 18` ตามหัวข้อ 3.5
- add-mailuser.sh ของ ch02 ใช้กับ userdb แบบ static ส่วนของ ch05 ใช้กับ userdb passwd-file ที่ตั้ง quota รายคน
- ชุดนี้ไม่มีกุญแจลับของ DKIM, certificate และ hash ของรหัสผ่าน ให้สร้างใหม่บนเครื่องของคุณ
- อ่านคำเตือน ⚠️ ในเล่มก่อนรันคำสั่งที่ลบอีเมลหรือ queue (doveadm expunge, postsuper -d)

ทดสอบบน Rocky Linux 10.2 กับ Postfix 3.8.5, Dovecot 2.3.21, OpenDKIM 2.11.0, OpenDMARC 1.4.2, SpamAssassin 4.0.1 และ Roundcube 1.6.20
และทดสอบส่วนของ Ubuntu Server 26.04 (Postfix 3.10.6, Dovecot 2.4.2) บนเครื่องจริงเมื่อ 15 พฤศจิกายน 2569
