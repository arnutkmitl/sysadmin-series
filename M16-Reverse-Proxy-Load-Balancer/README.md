# ไฟล์ประกอบหนังสือ Reverse Proxy & Load Balancer

SysAdmin Pocket Series M16 โดย ดร.อาณัติ รัตนถิรกุล (อ.หมวกแดง) สำนักพิมพ์ SysAdmin Knowledge Press
ดาวน์โหลดได้ที่ https://github.com/arnutkmitl/sysadmin-series โฟลเดอร์ `M16-Reverse-Proxy-Load-Balancer`

## โฟลเดอร์

| โฟลเดอร์ | เนื้อหา |
|---|---|
| `ch00/` | be-app.py + be-app.service (แอปหลังบ้าน), setup-pebble.sh (Pebble + DNS ทดสอบ) |
| `ch01/` | web.conf ของ nginx สามขั้น และ 00-cache.conf |
| `ch02/` | haproxy.cfg สองขั้น, deploy hook ของ certbot, check_sni.py |
| `ch03/` | traefik.yml, docker-compose.yml, dynamic/web.yml |
| `ch04/` | keepalived.conf ของ lb1 และ lb2, chk_haproxy.sh, vip_probe.py |
| `ch05/` | load.sh, PROXY protocol (ch05.cfg, ch05.conf), loop.conf, prometheus.yml |
| `ch06/` | haproxy.cfg ฉบับจบเล่ม, be-app2.service, certsync (haproxy-cert-recv, certsync-wrap), deploy hook, check-proxy.sh, serial.py |
| `commands/chNN.sh` | คำสั่งที่พิมพ์ใน terminal ของแต่ละบท รวม 254 คำสั่ง ไม่ใช่สคริปต์ ให้คัดลอกทีละคำสั่ง |

## ก่อนใช้งาน

- เปลี่ยน IP 192.168.56.71 ถึง .75 ให้ตรงกับเครื่องของคุณ ทั้งใน config และสคริปต์
- รหัสผ่าน LabStats-2569 (หน้า Stats) และ LabTraefik-2569 (dashboard) เป็นค่าตัวอย่างในเล่ม เปลี่ยนก่อนใช้งานจริง
- users.htpasswd ของ Traefik ไม่อยู่ในชุดนี้ สร้างใหม่ตามบทที่ 3
- บน Rocky Linux ต้องติดป้าย SELinux ให้พอร์ต 8404, 8888 และ 8081 ตามบทที่ 2 และ 6 และวาง chk_haproxy.sh ใน /usr/libexec/keepalived
- ค่าที่ใช้ Pebble (REQUESTS_CA_BUNDLE, caServer, LEGO_CA_CERTIFICATES) ใช้ใน Lab เท่านั้น เมื่อมีโดเมนจริงให้ตัดออกตามภาคผนวก ค
- อ่านคำเตือน ⚠️ ในเล่มก่อนรันคำสั่งที่หยุดบริการหรือปิดเครื่อง

ทดสอบบน Rocky Linux 10.2 กับ nginx 1.26.3, HAProxy 3.0.5, keepalived 2.2.8, certbot 4.2.0, Traefik v3.7.19,
Docker CE 29.10.0, Pebble v2.10.3 และ Prometheus v3.16.0 พร้อมกล่อง Ubuntu Server 26.04 เมื่อ 17 พฤศจิกายน 2569
