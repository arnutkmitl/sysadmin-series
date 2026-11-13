#!/usr/bin/env bash
# SELinux และ AppArmor: กักบริการไว้ในกรอบ
# SysAdmin Pocket Series M10 SSL & Security Hardening
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 3.1 SELinux ทำงานอย่างไร ────────────────────────────────
getenforce
sudo sestatus | grep -E 'status|Current mode|Mode from|Loaded policy'
grep -E '^SELINUX(TYPE)?=' /etc/selinux/config

# ── ป้ายของไฟล์และโปรเซส ────────────────────────────────────
ls -Z /etc/shadow /etc/nginx/nginx.conf /usr/share/nginx/site/index.php /var/log/nginx/access.log
ps -eZ | grep -E ' (nginx|php-fpm|named|pebble|fail2ban-server)$' | awk '{print $1, $NF}' | sort -u
id -Z

# ── ย้ายเว็บไป /srv แล้วเว็บพัง ─────────────────────────────
sudo mkdir -p /srv/site
sudo cp /usr/share/nginx/site/index.php /srv/site/
echo '<h1>About site.lab.test</h1>' | sudo tee /srv/site/about.html > /dev/null
sudo sed -i 's|root /usr/share/nginx/site;|root /srv/site;|' /etc/nginx/conf.d/site.conf
sudo nginx -t && sudo systemctl reload nginx
curl -s -o /dev/null -w '%{http_code}\n' https://site.lab.test/about.html
curl -s -o /dev/null -w '%{http_code}\n' https://site.lab.test/
ls -l /srv/site/
sudo tail -2 /var/log/nginx/error.log

# ── อ่าน AVC ด้วย ausearch ──────────────────────────────────
sudo ausearch -m avc -ts recent

# ── audit2why บอกประเภทของปัญหา ─────────────────────────────
sudo ausearch -m avc -ts recent | audit2why | head -6

# ── ป้ายที่ถูกต้องมาจากไหน ──────────────────────────────────
matchpathcon /srv/site/index.php /usr/share/nginx/html/index.html /var/www/html/index.html
sudo semanage fcontext -a -t httpd_sys_content_t '/srv/site(/.*)?'
sudo restorecon -Rv /srv/site
curl -s -o /dev/null -w '%{http_code}\n' https://site.lab.test/about.html
curl -s https://site.lab.test/
sudo semanage fcontext -l -C

# ── mv กับ cp ให้ผลต่างกัน ──────────────────────────────────
echo '<h1>Contact</h1>' > ~/contact.html
echo '<h1>FAQ</h1>' > ~/faq.html
sudo mv ~/contact.html /srv/site/
sudo cp ~/faq.html /srv/site/
ls -Z /srv/site/contact.html /srv/site/faq.html
for f in contact faq; do curl -s -o /dev/null -w "%{http_code} $f.html\n" https://site.lab.test/$f.html; done
sudo restorecon -v /srv/site/contact.html
curl -s -o /dev/null -w '%{http_code}\n' https://site.lab.test/contact.html

# ── chcon แก้ได้แค่ชั่วคราว ─────────────────────────────────
sudo chcon -t var_t /srv/site/faq.html
ls -Z /srv/site/faq.html
sudo restorecon -v /srv/site/faq.html

# ── PHP เขียนไฟล์ลง uploads ─────────────────────────────────
sudo cp ~/ch03/note.php /srv/site/
sudo install -d -o apache -g apache /srv/site/uploads
ls -Zd /srv/site/uploads
curl -s https://site.lab.test/note.php
matchpathcon /srv/site/uploads
sudo restorecon -Rv /srv/site
curl -s https://site.lab.test/note.php
sudo ausearch -m avc -ts recent -c php-fpm | grep AVC
sudo semanage fcontext -a -t httpd_sys_rw_content_t '/srv/site/uploads(/.*)?'
sudo restorecon -Rv /srv/site/uploads
curl -s https://site.lab.test/note.php

# ── Reverse proxy ไปที่ backend ─────────────────────────────
sudo mkdir -p /opt/api
echo '{"status":"ok"}' | sudo tee /opt/api/health > /dev/null
sudo cp ~/ch03/api-tcp.service /etc/systemd/system/api.service
sudo systemctl daemon-reload && sudo systemctl enable --now api
curl -s http://127.0.0.1:3000/health
ps -eZ | grep python3
sudo nginx -t && sudo systemctl reload nginx
curl -s -o /dev/null -w '%{http_code}\n' https://site.lab.test/api/health
sudo tail -1 /var/log/nginx/error.log
sudo ausearch -m avc -ts recent -c nginx | grep name_connect
sudo ausearch -m avc -ts recent -c nginx | audit2why
getsebool httpd_can_network_connect
sudo setsebool -P httpd_can_network_connect on
curl -s https://site.lab.test/api/health
sudo semanage boolean -l -C

# ── บริการฟัง port ที่ไม่ใช่ค่ามาตรฐาน ──────────────────────
sudo nginx -t 2>&1 | tail -1 && sudo systemctl reload nginx; echo rc=$?
curl -s -m 3 http://127.0.0.1:8090/; echo rc=$?
sudo tail -1 /var/log/nginx/error.log
sudo semanage port -l | grep -w http_port_t
sudo semanage port -a -t http_port_t -p tcp 8090
sudo systemctl reload nginx
curl -s http://127.0.0.1:8090/
sudo semanage port -l -C
sudo rm /etc/nginx/conf.d/status.conf && sudo systemctl reload nginx
sudo semanage port -d -t http_port_t -p tcp 8090

# ── อย่าป้อน log ทั้งวันให้ audit2allow ─────────────────────
sudo ausearch -m avc -ts today | audit2allow

# ── backend ผ่าน unix socket ────────────────────────────────
sudo cp ~/ch03/unix_server.py /opt/api/
sudo cp ~/ch03/api-unix.service /etc/systemd/system/api.service
sudo systemctl daemon-reload && sudo systemctl restart api
ls -lZ /run/api/
sudo sed -i 's|proxy_pass http://127.0.0.1:3000/;|proxy_pass http://unix:/run/api/api.sock:/;|' /etc/nginx/conf.d/site.conf
sudo setsebool -P httpd_can_network_connect off
sudo nginx -t && sudo systemctl reload nginx
curl -s -o /dev/null -w '%{http_code}\n' https://site.lab.test/api/health
sudo ausearch -m avc -ts recent -c nginx | grep api.sock

# ── Permissive เฉพาะ httpd_t เพื่อเก็บ AVC ให้ครบ ───────────
sudo semanage permissive -a httpd_t
curl -s -o /dev/null -w '%{http_code}\n' https://site.lab.test/api/health
sudo semanage permissive -d httpd_t
sudo ausearch -m avc -ts recent -c nginx | grep api.sock

# ── สร้าง module จาก AVC ที่คัดแล้ว ─────────────────────────
mkdir -p ~/selinux && cd ~/selinux
sudo ausearch -m avc -ts recent -c nginx | grep api.sock | audit2allow -M nginx_api
cat nginx_api.te
sudo semodule -i nginx_api.pp
sudo semodule -l | grep nginx_api
curl -s https://site.lab.test/api/health
getsebool httpd_can_network_connect

# ── 3.5 AppArmor บน Ubuntu ──────────────────────────────────
sudo aa-enabled
sudo aa-status | head -4

# ── บริการใดถูกคุมอยู่จริง ──────────────────────────────────
sudo apt install -y nginx tcpdump apparmor-utils
ps -eZ | grep -E 'nginx|chronyd|sshd|rsyslog|systemd-resolve' | awk '{print $1, $2, $NF}' | sort -u -k3
sudo aa-status | sed -n '/processes have profiles defined/,/complain mode/p'

# ── เมื่อ AppArmor ปฏิเสธ ───────────────────────────────────
sudo timeout 5 tcpdump -i lo -c 1 -w /etc/capture.txt
sudo journalctl -k --since '-1min' | grep -o 'apparmor="DENIED".*' | tail -1
grep -E 'HOME}/\*\* |\[aA\]\[pP\] ' /etc/apparmor.d/usr.bin.tcpdump
sudo timeout 5 tcpdump -i lo -c 1 -w /etc/capture.pcap
ls -l /etc/capture.pcap

# ── complain และ enforce ────────────────────────────────────
sudo aa-complain /usr/bin/tcpdump
sudo timeout 5 tcpdump -i lo -c 1 -w /etc/capture.txt
sudo journalctl -k --since '-1min' | grep -o 'apparmor="ALLOWED".*capture.txt.*' | tail -1
sudo aa-enforce /usr/bin/tcpdump
sudo rm -f /etc/capture.txt /etc/capture.pcap

# ── วัดคะแนนหลังจบบท ────────────────────────────────────────
sudo ./security-audit.sh -v | sed -n '/\] 09/,/\] 17/{/\] 17/!p};$p'
