#!/usr/bin/env bash
# จัดการข้อความ: grep, awk, sed และ pipe
# SysAdmin Pocket Series M03 Shell Script Automation
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 3.1 Pipe ต่อคำสั่งเป็นสายพาน ────────────────────────────
grep -v nologin /etc/passwd | cut -d: -f1,7 | sort
sudo ss -tlnp | grep -c LISTEN

# ── 3.2 grep ค้นหาบรรทัด ────────────────────────────────────
sudo grep -ic "error" /var/log/messages
grep -Ev '^#|^$' /etc/chrony.conf

# ── 3.3 awk ดึงคอลัมน์และกรอง ───────────────────────────────
awk -F: '$3 >= 1000 && $3 < 65534 {print $1, $3, $6}' /etc/passwd
ps -eo pid,%mem,comm --sort=-%mem | awk 'NR <= 4'

# ── 3.4 sed แก้ข้อความ ──────────────────────────────────────
# ⚠️ sed -i ที่ไม่มีนามสกุลต่อท้ายแก้ไฟล์ทันทีโดยไม่มีสำเนา ถ้ารูปแบบผิด config ทั้งไฟล์อาจเสีย ใช้ sed -i.bak ทุกครั้ง และลองรูปแบบโดยไม่ใส่ -i ก่อนเสมอ
echo "listen 80; server_name old.example.lan;" | sed 's/80/8080/; s/old/new/g'
sed -n '3,4p' /etc/hosts

# ── 3.6 jq อ่าน JSON ────────────────────────────────────────
ip -j addr show enp0s8 | jq -r '.[0].addr_info[0].local'
curl -s https://api.github.com/repos/koalaman/shellcheck/releases/latest | jq -r '.tag_name, .published_at'

# ── Lab 3.1 หา Top 10 IP ที่ล็อกอินผิด ──────────────────────
./top-failed.sh 5

# ── Lab 3.2 แก้ config หลายไฟล์พร้อมกัน ─────────────────────
mkdir -p ~/scripts/labs/conf && cd ~/scripts/labs/conf
for app in web api worker; do printf 'name=%s\nport=8080\n' "$app" > "$app.conf"; done
for f in *.conf; do sed -i.bak 's/^port=.*/port=9090/' "$f"; done
grep -H '^port=' *.conf
ls *.bak

# ── กล่อง Ubuntu ────────────────────────────────────────────
./top-failed.sh 10 /var/log/auth.log
journalctl -u ssh --since today | grep "Failed password" | grep -oE 'from [0-9.]+' | sort | uniq -c
