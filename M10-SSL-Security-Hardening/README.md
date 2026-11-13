# ไฟล์ประกอบหนังสือ SSL & Security Hardening

SysAdmin Pocket Series M10 โดย ดร.อาณัติ รัตนถิรกุล (อ.หมวกแดง) สำนักพิมพ์ SysAdmin Knowledge Press
ดาวน์โหลดได้ที่ https://github.com/arnutkmitl/sysadmin-series โฟลเดอร์ `M10-SSL-Security-Hardening`

## โฟลเดอร์

| โฟลเดอร์ | เนื้อหา |
|---|---|
| `audit/security-audit.sh` | script ตรวจ 30 ข้อที่ใช้ทั้งเล่ม (บทที่ 0 ถึง 5, ภาคผนวก ก) |
| `ch00/setup-pebble.sh` | ACME server สำหรับทดสอบ (Pebble) เป็น systemd service ฟัง 127.0.0.1 |
| `ch02/` | 20-m10-hardening.conf ของ sshd, jail.local ของ fail2ban, ห้าบรรทัดแรกของ /etc/pam.d/sshd |
| `ch03/` | note.php, api-tcp.service, api-unix.service, unix_server.py สำหรับทดลอง SELinux |
| `ch04/` | pwquality, sysctl, rsyslog ฝั่งส่งและฝั่งรับ, กฎ sudo webops, aide-check.service/.timer, aide_efi.te |
| `ch05/` | security-audit.service และ .timer ตรวจทุกเช้าวันจันทร์ |
| `commands/chNN.sh` | คำสั่งที่พิมพ์ใน terminal ของแต่ละบท รวม 467 คำสั่ง ไม่ใช่สคริปต์ ให้คัดลอกทีละคำสั่ง |

## เริ่มใช้

```
sudo ./audit/security-audit.sh -v                      # ตรวจ 30 ข้อพร้อมเหตุผล
sudo SITE=www.example.com ./audit/security-audit.sh    # ตรวจเว็บของคุณเอง
```

ค่าที่ปรับได้อยู่ต้นไฟล์ security-audit.sh ได้แก่ SITE, SSH_GROUP, ALLOWED_TCP และ CERT_DAYS

## ก่อนใช้งาน

- ติดตั้งแพ็กเกจ google-authenticator และยืนยันว่ามีไฟล์ pam_google_authenticator.so ก่อนแก้ /etc/pam.d/sshd
  ถ้า PAM เรียกโมดูลที่ไม่มีอยู่ จะไม่มีใครเข้าเครื่องได้ (หัวข้อ 5.2)
- เปิด session SSH ค้างไว้หนึ่งหน้าต่างทุกครั้งที่ reload sshd
- ignoreip ใน jail.local และ IP ใน 90-remote.conf ต้องแก้ให้ตรงกับเครือข่ายของคุณ
- aide_efi.te ใช้กับเครื่องที่บูตแบบ UEFI และมี /boot/efi เป็น vfat คอมไพล์ด้วย checkmodule ตามหัวข้อ 5.2
- ชุดนี้ไม่มีกุญแจ TSIG, secret ของ TOTP หรือใบรับรองของเครื่องทดสอบ ให้สร้างใหม่บนเครื่องของคุณ
- อ่านคำเตือน ⚠️ ในเล่มก่อนรันคำสั่งที่เปลี่ยน PAM, sshd, firewall หรือลบผู้ใช้

ทดสอบบน Rocky Linux 10.2 กับ OpenSSL 3.5.8, OpenSSH 9.9p1, Nginx 1.26.3, fail2ban 1.1.0 และ AIDE 0.19.2
และทดสอบส่วนของ Ubuntu Server 26.04 บนเครื่องจริงเมื่อ 13 พฤศจิกายน 2569
