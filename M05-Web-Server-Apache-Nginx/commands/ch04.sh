#!/usr/bin/env bash
# Production Deployment และการแก้ปัญหา
# SysAdmin Pocket Series M05 Web Server: Apache & Nginx
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 4.1 จัดการ Log ──────────────────────────────────────────
sudo nginx -t
systemctl is-active nginx
sudo mv /etc/nginx/conf.d/logformat.conf /etc/nginx/conf.d/00-logformat.conf
sudo nginx -t && sudo systemctl reload nginx
sudo tail -1 /var/log/nginx/app-access.log

# ── Log Rotation ────────────────────────────────────────────
cat /etc/logrotate.d/nginx
sudo logrotate -d /etc/logrotate.d/nginx 2>&1 | grep -E 'rotating pattern'

# ── GoAccess สรุป log ───────────────────────────────────────
sudo dnf install -y goaccess
rpm -q goaccess
sudo goaccess /var/log/nginx/site1-access.log --log-format=COMBINED -o /tmp/report.html
ls -l /tmp/report.html
sudo goaccess /var/log/nginx/site1-access.log --log-format=COMBINED -o /tmp/r.json
python3 -c "import json; d=json.load(open('/tmp/r.json')); g=d['general']; print('total', g['total_requests'], 'visitors', g['unique_visitors'])"

# ── Apache MPM ──────────────────────────────────────────────
httpd -V 2>/dev/null | grep -i mpm
grep -v '^#' /etc/httpd/conf.modules.d/00-mpm.conf | grep -v '^$'

# ── PHP-FPM ตามขนาด RAM ─────────────────────────────────────
grep -E '^(pm|pm\.[a-z_]+) =' /etc/php-fpm.d/www.conf
ps -o rss= -C php-fpm | sort -n | tail -3 | awk '{printf "%.0f MB\n", $1/1024}'
free -m | head -2

# ── 4.3 Monitoring ──────────────────────────────────────────
curl -s http://127.0.0.1:8080/nginx_status
curl -s -o /dev/null -w 'from LAN -> %{http_code}\n' http://192.168.56.20:8080/nginx_status
curl -s 'http://localhost/server-status?auto' | head -4

# ── 403 จาก SELinux ─────────────────────────────────────────
echo '<h1>about</h1>' > ~/about.html
sudo mv ~/about.html /var/www/site1/
ls -Z /var/www/site1/about.html
curl -s -o /dev/null -w 'about.html -> %{http_code}\n' https://site1.lab.test/about.html
sudo grep "denied.*about.html" /var/log/audit/audit.log | tail -1 | grep -o "avc:.*tclass=file"
sudo restorecon -v /var/www/site1/about.html
curl -s -o /dev/null -w 'after restorecon -> %{http_code}\n' https://site1.lab.test/about.html

# ── 403 จากสิทธิ์ไฟล์ ───────────────────────────────────────
sudo chmod 600 /var/www/site1/about.html
curl -s -o /dev/null -w 'chmod 600 -> %{http_code}\n' https://site1.lab.test/about.html
sudo tail -1 /var/log/nginx/site1-error.log
sudo chmod 644 /var/www/site1/about.html

# ── 502 Bad Gateway ─────────────────────────────────────────
sudo systemctl stop php-fpm
curl -s -o /dev/null -w 'php-fpm stopped -> %{http_code}\n' http://wp.lab.test/
sudo tail -1 /var/log/nginx/wp-error.log
sudo systemctl start php-fpm

# ── Port ถูกใช้อยู่ ─────────────────────────────────────────
sudo systemctl start httpd
sudo journalctl -u httpd -n 6 --no-pager | grep -iE 'address already|no listening'
sudo ss -tlnp 'sport = :80' | tail -n +2

# ── ใบรับรองใกล้หมดอายุ ─────────────────────────────────────
sudo openssl x509 -in /etc/letsencrypt/live/site1.lab.test/cert.pem -noout -enddate
echo | openssl s_client -connect site1.lab.test:443 -servername site1.lab.test 2>/dev/null | openssl x509 -noout -checkend 2592000
