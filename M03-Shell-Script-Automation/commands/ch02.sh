#!/usr/bin/env bash
# ตัวแปร เงื่อนไข และลูป: Syntax ที่ต้องใช้
# SysAdmin Pocket Series M03 Shell Script Automation
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 2.1 ตัวแปร ──────────────────────────────────────────────
HOST="web01"
echo "Server: $HOST"
HOST = "web01"
# ⚠️ ใช้ตัวแปรโดยไม่ครอบ "" คือ bug ที่พบบ่อยที่สุดใน Shell Script ค่าที่มีช่องว่างจะถูกแยกเป็นหลายคำ และค่าที่มี * จะถูกขยายเป็นชื่อไฟล์ เมื่อตัวแปรนั้นอยู่ในคำสั่ง rm หรือ mv ผลคือลบหรือย้ายผิดไฟล์
FILE="sales report.txt"
touch "$FILE"
ls -l $FILE
ls -l "$FILE"
readonly BACKUP_DIR="/backup"
BACKUP_DIR="/tmp"
TODAY=$(date +%Y%m%d)
echo "etc-$TODAY.tar.gz"
FILE="nginx.conf.bak"
echo "${FILE%.bak} ยาว ${#FILE} ตัวอักษร"
echo "${BACKUP_DEST:?ไม่ได้ระบุปลายทาง}"

# ── 2.2 เงื่อนไข ────────────────────────────────────────────
NAME=""
[ $NAME == "web01" ] && echo match
[[ $NAME == "web01" ]] || echo "ไม่ตรง"

# ── 2.3 ลูป ─────────────────────────────────────────────────
# ⚠️ อย่าอ่านไฟล์ด้วย for i in $(cat ไฟล์) เพราะ for แยกตามช่องว่าง ไม่ใช่ตามบรรทัด บรรทัด "192.168.56.10 web01" จะกลายเป็นสองรอบ รอบที่สองนำคำว่า web01 ไปใช้เป็น IP ใช้ while read -r แทนทุกครั้ง
for svc in sshd crond chronyd; do systemctl is-active --quiet "$svc" && echo "$svc OK" || echo "$svc DOWN"; done
for f in /var/log/*.log; do echo "$f $(sudo du -h "$f" | cut -f1)"; done
printf '192.168.56.10\n192.168.56.20\n10.255.255.1\n' > ip-list.txt
while read -r ip; do ping -c 1 -W 1 "$ip" &>/dev/null && echo "UP   $ip" || echo "DOWN $ip"; done < ip-list.txt
while true; do echo "$(date +%T) $(uptime | awk -F'average:' '{print $2}')"; sleep 5; done

# ── 2.4 ฟังก์ชัน ────────────────────────────────────────────
./func-demo.sh

# ── 2.5 รับ argument จากผู้ใช้ ──────────────────────────────
./port-check.sh
./port-check.sh 192.168.56.10 2222
./port-check.sh 192.168.56.10 3306
./getopts-demo.sh -v sshd
./getopts-demo.sh -vf crond

# ── Lab 2.1 Script ตรวจ Service หลายตัว ─────────────────────
./check-services.sh sshd nginx
echo $?
