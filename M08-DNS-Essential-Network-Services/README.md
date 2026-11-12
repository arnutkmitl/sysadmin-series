# ไฟล์ประกอบหนังสือ DNS & Essential Network Services

SysAdmin Pocket Series M08 โดย ดร.อาณัติ รัตนถิรกุล (อ.หมวกแดง) สำนักพิมพ์ SysAdmin Knowledge Press
ดาวน์โหลดได้ที่ https://github.com/arnutkmitl/sysadmin-series โฟลเดอร์ `M08-DNS-Essential-Network-Services`

## โฟลเดอร์

| โฟลเดอร์ | เนื้อหา |
|---|---|
| `configs/ns1/etc/named.conf` | BIND ของ ns1 แบบ split DNS พร้อม zone ที่เปิด update (สถานะหลังบทที่ 3) |
| `configs/ns1/var/named/` | zone file ของ view internal, external, reverse และ zone ตั้งต้นใน dynamic/ |
| `configs/ns1/etc/unbound/conf.d/lan.conf` | Unbound resolver ของวง LAN (บทที่ 2 และ 3) |
| `configs/ns1/etc/kea/` | Kea DHCPv4 พร้อม reservation และ DDNS กับ kea-dhcp-ddns (บทที่ 3) |
| `configs/ns1/etc/chrony.conf.append` | บรรทัดที่ต่อท้าย /etc/chrony.conf ให้ ns1 เป็น NTP server |
| `configs/ns2/etc/named.conf` | BIND secondary ของ ns2 ทั้งสอง view |
| `configs/docker/pihole/compose.yaml` | Pi-hole บน Docker (หัวข้อ 2.3) |
| `capstone/check-dns.sh` | script ตรวจรับโปรเจกต์จบเล่ม 42 ข้อจากสามเครื่อง |
| `commands/chNN.sh` | คำสั่งที่พิมพ์ใน terminal ของแต่ละบท รวม 292 คำสั่ง ไม่ใช่สคริปต์ ให้คัดลอกทีละคำสั่ง |

## โปรเจกต์จบเล่ม

```
sudo ./capstone/check-dns.sh primary      # บน ns1
sudo ./capstone/check-dns.sh secondary    # บน ns2
./capstone/check-dns.sh client            # บนเครื่องลูกข่ายใน LAN
```

แก้ IP และชื่อโดเมนที่ต้นไฟล์ check-dns.sh ให้ตรงกับเครือข่ายของคุณก่อนรัน

## ก่อนใช้งาน

- ชุดนี้ไม่มีไฟล์กุญแจ TSIG สร้างเองด้วย tsig-keygen ตามหัวข้อ 2.2 และ 3.2 แล้วใส่ secret ของ
  ddns-key ใน kea-dhcp-ddns.conf ตรงข้อความ "ใส่ secret จาก /etc/named.ddns.key"
- ไฟล์ใน configs/ คือสถานะสุดท้ายของ Lab หลังทำครบทุกบท รวม record ที่เพิ่มระหว่างทดลอง เช่น nas,
  backup และ files ใช้เป็นตัวเทียบ ไม่ใช่จุดเริ่ม ถ้าเริ่มจากเครื่องเปล่าให้ทำตามบทที่ 1 ทีละขั้น
- รหัสผ่าน Pi-hole ใน compose.yaml เป็นค่าของ Lab ให้เปลี่ยนก่อนใช้งาน
- อ่านคำเตือน ⚠️ ในเล่มก่อนรันคำสั่งที่หยุดบริการหรือเปลี่ยน firewall

ทดสอบบน Rocky Linux 10.2 กับ BIND 9.18.33, Unbound 1.24.2, Kea 3.0.3 และ chrony 4.8
และตรวจไฟล์ตั้งค่าบน Ubuntu Server 26.04 เมื่อ 12 พฤศจิกายน 2569
