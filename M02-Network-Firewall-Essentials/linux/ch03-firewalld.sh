#!/usr/bin/env bash
# บทที่ 3 Firewall ขั้นกลาง: firewalld Zone และ Rich Rules
# SysAdmin Pocket Series M02 Network & Firewall Essentials
#
# ไฟล์นี้รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# Lab บางข้อตั้งใจทำให้เครือข่ายพัง ห้ามรันทั้งไฟล์
# คำสั่งที่ไม่มีป้าย [client] หรือ [Ubuntu] รันบน server (Rocky Linux 10)
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── Runtime กับ Permanent ───────────────────────────────────────
sudo firewall-cmd --add-service=http
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload


# ── ดูสถานะ ─────────────────────────────────────────────────────
sudo firewall-cmd --state
sudo firewall-cmd --get-default-zone
sudo firewall-cmd --get-active-zones

sudo firewall-cmd --list-all
sudo firewall-cmd --list-all-zones | less


# ── 3.2 Zone กุญแจของ firewalld ─────────────────────────────────
# ⚠️ ถ้า SSH เข้ามาทางการ์ดที่กำลังเปลี่ยน zone และ zone ใหม่ไม่ได้เปิดพอร์ต 2222 การเชื่อมต่อจะหลุดทันที เปิดพอร์ตใน zone ปลายทางก่อนย้ายการ์ดเสมอ
sudo firewall-cmd --zone=internal --change-interface=enp0s8
sudo nmcli con mod mgmt connection.zone internal
sudo nmcli con up mgmt
sudo firewall-cmd --get-active-zones

sudo firewall-cmd --permanent --zone=trusted --add-source=10.10.50.0/24


# ── 3.3 Rich Rules ──────────────────────────────────────────────
# ตัวอย่างค่าหรือรูปแบบในเล่ม (ไม่ใช่คำสั่ง):
#   rule family="ipv4" source address="IP/วง" port port="พอร์ต" protocol="tcp" accept|drop|reject

# ── ตัวอย่างที่ใช้บ่อย ──────────────────────────────────────────
sudo firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.57.1" port port="2222" protocol="tcp" accept'

sudo firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" source address="203.0.113.50" drop'
sudo firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" source address="198.51.100.0/24" reject'

sudo firewall-cmd --permanent --zone=internal --add-rich-rule='rule family="ipv4" source address="192.168.56.0/24" accept'

sudo firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" port port="2222" protocol="tcp" accept limit value="3/m"'

sudo firewall-cmd --zone=public --list-rich-rules
sudo firewall-cmd --permanent --zone=public --remove-rich-rule='rule family="ipv4" source address="203.0.113.50" drop'


# ── ลำดับของ rich rule ──────────────────────────────────────────
sudo firewall-cmd --permanent --zone=public --add-rich-rule='rule priority="-10" family="ipv4" source address="192.168.57.1" accept'
sudo firewall-cmd --permanent --zone=public --add-rich-rule='rule priority="0" family="ipv4" source address="192.168.57.0/24" drop'


# ── 3.4 Port Forwarding ─────────────────────────────────────────
sudo firewall-cmd --permanent --zone=public --add-forward-port=port=8080:proto=tcp:toport=80
sudo firewall-cmd --reload

sudo firewall-cmd --permanent --zone=public --add-forward-port=port=8081:proto=tcp:toport=80:toaddr=192.168.56.20
sudo firewall-cmd --permanent --zone=public --add-masquerade
sudo firewall-cmd --reload
sudo firewall-cmd --zone=public --list-forward-ports


# ── 3.5 Logging ─────────────────────────────────────────────────
sudo firewall-cmd --set-log-denied=unicast
sudo firewall-cmd --get-log-denied
sudo journalctl -k --since "10 min ago" | grep REJECT

sudo firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.57.0/24" port port="2222" protocol="tcp" log prefix="SSH-DENY: " level="warning" limit value="1/m" drop'
sudo journalctl -k -g "SSH-DENY"


# ── 3.6 Backup และ Restore ──────────────────────────────────────
sudo cp -a /etc/firewalld /root/firewalld-$(date +%Y%m%d)
sudo tar czf /root/firewalld-$(date +%F).tar.gz -C /etc firewalld
ls /etc/firewalld/zones/

# ⚠️ การ restore จะทับค่า firewall ปัจจุบันทั้งหมด ถ้าไฟล์สำรองเก่ากว่ากฎที่ใช้อยู่ กฎใหม่จะหายไป ทำจาก Console หรือแน่ใจว่าไฟล์สำรองเปิด SSH ไว้
sudo tar xzf /root/firewalld-2026-11-10.tar.gz -C /etc
sudo firewall-cmd --check-config
sudo firewall-cmd --reload


# ── Lab 3.1 ตั้ง Firewall สำหรับ Multi-Zone Server ──────────────
sudo cp -a /etc/firewalld /root/firewalld-before-lab3
sudo firewall-cmd --permanent --zone=internal --add-rich-rule='rule family="ipv4" source address="192.168.56.0/24" accept'
sudo firewall-cmd --reload
sudo nmcli con mod mgmt connection.zone internal
sudo nmcli con up mgmt
sudo nmcli con mod service-net connection.zone public
sudo nmcli con up service-net

sudo systemd-run --on-active=5m --unit=fw-rollback /usr/bin/firewall-cmd --reload
sudo firewall-cmd --zone=public --add-service=http --add-service=https
sudo firewall-cmd --zone=public --remove-service=ssh --remove-service=cockpit
sudo firewall-cmd --zone=public --remove-port=2222/tcp
sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.57.1" port port="2222" protocol="tcp" accept'

# [client]
nc -zv -w 3 192.168.57.10 2222
nc -zv -w 3 192.168.57.10 80
nc -zv -w 3 192.168.56.10 2222

sudo firewall-cmd --permanent --zone=public --add-service=http --add-service=https
sudo firewall-cmd --permanent --zone=public --remove-service=ssh --remove-service=cockpit
sudo firewall-cmd --permanent --zone=public --remove-port=2222/tcp
sudo firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.57.1" port port="2222" protocol="tcp" accept'
sudo firewall-cmd --reload
sudo systemctl stop fw-rollback.timer
sudo firewall-cmd --permanent --zone=public --list-all


# ── Lab 3.2 ตั้ง Port Forwarding และ Logging ────────────────────
sudo firewall-cmd --permanent --zone=public --add-forward-port=port=8080:proto=tcp:toport=80
sudo firewall-cmd --reload
sudo firewall-cmd --set-log-denied=unicast
sudo journalctl -k --since "5 min ago" | grep 'DPT=3306'
sudo firewall-cmd --set-log-denied=off


# ── กล่อง Ubuntu ────────────────────────────────────────────────
# ⚠️ ถ้าสั่ง `ufw enable` ผ่าน SSH ก่อนอนุญาตพอร์ต SSH การเชื่อมต่อจะหลุดและเข้าเครื่องไม่ได้อีก ต้องแก้จาก Console
# [Ubuntu]
sudo ufw allow from 192.168.56.0/24 to any port 2222 proto tcp
sudo ufw allow 'Nginx Full'
sudo ufw deny from 203.0.113.50
sudo ufw enable
sudo ufw status numbered

# [Ubuntu]
sudo ufw limit 2222/tcp
sudo ufw app info OpenSSH
