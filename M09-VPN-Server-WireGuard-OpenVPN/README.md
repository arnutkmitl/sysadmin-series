# ไฟล์ประกอบหนังสือ VPN Server: WireGuard & OpenVPN

SysAdmin Pocket Series M09 โดย ดร.อาณัติ รัตนถิรกุล (อ.หมวกแดง) สำนักพิมพ์ SysAdmin Knowledge Press
ดาวน์โหลดได้ที่ https://github.com/arnutkmitl/sysadmin-series โฟลเดอร์ `M09-VPN-Server-WireGuard-OpenVPN`

## โฟลเดอร์

| โฟลเดอร์ | เนื้อหา |
|---|---|
| `configs/vpn1/etc/wireguard/` | wg0.conf (remote access) และ wg1.conf (site-to-site) ของสำนักงานใหญ่ |
| `configs/vpn2/etc/wireguard/wg1.conf` | site-to-site ฝั่งสาขา |
| `configs/laptop/etc/wireguard/wg0.conf` | client แบบ split tunnel พร้อม PresharedKey |
| `configs/vpn1/etc/openvpn/server/` | server.conf (UDP 1194) และ tcp443.conf (TCP 443) |
| `configs/vpn1/etc/systemd/system/` | openvpn-crl.service และ .timer ต่ออายุ CRL ทุกเดือน |
| `configs/*/etc/sysctl.d/90-vpn.conf` | เปิด ip_forward บน vpn1 และ vpn2 |
| `configs/app1/etc/systemd/system/intranet.service` | หน้าเว็บทดสอบบน app1 |
| `ch02/make-ovpn` | สร้างไฟล์ .ovpn ไฟล์เดียวจาก inline file ของ Easy-RSA (หัวข้อ 2.3) |
| `capstone/add-users.sh`, `users.txt` | สร้างบัญชี WireGuard และ OpenVPN ให้ผู้ใช้ 20 คน |
| `capstone/check-vpn.sh` | script ตรวจรับโปรเจกต์จบเล่ม 30 ข้อจากสามเครื่อง |
| `commands/chNN.sh` | คำสั่งที่พิมพ์ใน terminal ของแต่ละบท รวม 281 คำสั่ง ไม่ใช่สคริปต์ ให้คัดลอกทีละคำสั่ง |

## โปรเจกต์จบเล่ม

```
sudo ./capstone/add-users.sh capstone/users.txt   # บน vpn1
sudo ./capstone/check-vpn.sh server               # บน vpn1
sudo ./capstone/check-vpn.sh branch               # บน vpn2
sudo ./capstone/check-vpn.sh client               # บน laptop ขณะเชื่อม WireGuard
```

แก้ IP ที่ต้นไฟล์ check-vpn.sh และ add-users.sh ให้ตรงกับเครือข่ายของคุณก่อนรัน

## ก่อนใช้งาน

- ชุดนี้ไม่มีกุญแจ certificate หรือ tc.key ใด ๆ ค่าในวงเล็บมุม เช่น <private key ของ vpn1>
  ให้แทนด้วยกุญแจที่สร้างบนเครื่องของคุณตามบทที่ 1 และ 2
- ติดตั้ง crl.pem ด้วย `install -m 644` ทุกครั้ง ถ้า OpenVPN อ่าน CRL ไม่ได้ ผู้ใช้ทุกคนจะเชื่อมไม่ได้
- บน Ubuntu เปลี่ยน user และ group ใน server.conf เป็น nobody และ nogroup
- อ่านคำเตือน ⚠️ ในเล่มก่อนรันคำสั่งที่เปลี่ยน firewall หรือถอนสิทธิ์ certificate

ทดสอบบน Rocky Linux 10.2 กับ wireguard-tools 1.0.20250521, OpenVPN 2.7.8 และ Easy-RSA 3.2.5
และตรวจแพ็กเกจกับไฟล์บน Ubuntu Server 26.04 เมื่อ 12 พฤศจิกายน 2569
