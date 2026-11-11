#!/usr/bin/env bash
# Nginx: Server Block, PHP-FPM และ Reverse Proxy
# SysAdmin Pocket Series M05 Web Server: Apache & Nginx
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 2.1 ติดตั้ง Nginx ───────────────────────────────────────
sudo systemctl disable --now httpd
sudo dnf install -y nginx
nginx -v
sudo systemctl enable --now nginx
curl -sI http://localhost | head -2

# ── 2.2 โครงสร้างไฟล์ตั้งค่า ────────────────────────────────
grep -nE '^\s*(user|worker_processes|worker_connections|include|server_name|root|listen) ' /etc/nginx/nginx.conf
ls /etc/nginx/conf.d /etc/nginx/default.d
for u in /exact /exact/x /static/a.png /img/a.png /static/img/a.png /static/img/a.txt /about; do printf '%-20s ' "$u"; curl -s -H 'Host: match.lab.test' "http://127.0.0.1$u"; done
sudo rm /etc/nginx/conf.d/match.conf

# ── 2.3 Server Block หลายเว็บในเครื่องเดียว ─────────────────
sed 's/site1/site2/g' /etc/nginx/conf.d/site1.conf | sudo tee /etc/nginx/conf.d/site2.conf > /dev/null
sudo nginx -t
sudo systemctl reload nginx
curl -s http://site1.lab.test
curl -s http://site2.lab.test
curl -s -H 'Host: other.lab.test' http://192.168.56.20
sudo nginx -t && sudo systemctl reload nginx
curl -s -H 'Host: other.lab.test' http://192.168.56.20; echo "curl exit=$?"
curl -s http://site1.lab.test

# ── 2.4 PHP-FPM กับ Nginx ───────────────────────────────────
sudo nginx -t && sudo systemctl reload nginx
curl -s -o /dev/null -w 'permalink %{http_code}\n' http://wp.lab.test/hello-apache/
curl -s -o /dev/null -w '.htaccess %{http_code}\n' http://wp.lab.test/.htaccess
cd /var/www/wordpress && sudo -u apache /usr/local/bin/wp post create --post_title="Hello Nginx" --post_name=hello-nginx --post_status=publish --porcelain
curl -s http://wp.lab.test/hello-nginx/ | grep -o '<title>[^<]*'
curl -s -o /dev/null -w 'no SCRIPT_FILENAME: %{http_code} size=%{size_download}\n' http://wp.lab.test/
sudo tail -1 /var/log/nginx/wp-error.log

# ── 2.5 Reverse Proxy ───────────────────────────────────────
sudo dnf install -y nodejs
node --version
sudo mkdir -p /opt/app
sudo systemctl daemon-reload
sudo systemctl enable --now app
curl -s http://127.0.0.1:3000/hello
sudo nginx -t && sudo systemctl reload nginx
curl -s -o /dev/null -w 'before setsebool: %{http_code}\n' http://app.lab.test/hello
sudo tail -1 /var/log/nginx/app-error.log
sudo grep denied /var/log/audit/audit.log | grep 3000 | tail -1
sudo setsebool -P httpd_can_network_connect on
getsebool httpd_can_network_connect
curl -s http://app.lab.test/hello
# ⚠️ อย่าแก้ 502 ด้วย setenforce 0 คำสั่งนี้ปิด SELinux ทั้งเครื่อง ไม่ใช่แค่สิทธิ์ที่ต้องใช้ ให้อ่าน audit.log ว่าถูกห้ามเรื่องอะไรแล้วเปิดเฉพาะ boolean นั้น
sudo systemctl stop app
curl -s -o /dev/null -w 'app stopped: %{http_code}\n' http://app.lab.test/hello
sudo tail -1 /var/log/nginx/app-error.log
sudo systemctl start app

# ── 2.6 Performance และ Caching ─────────────────────────────
F=/wp-includes/css/dist/block-library/style.min.css
curl -s -o /dev/null -w 'plain %{size_download}\n' http://wp.lab.test$F
curl -s -H 'Accept-Encoding: gzip' -o /dev/null -w 'gzip  %{size_download}\n' http://wp.lab.test$F
curl -s -H 'Accept-Encoding: gzip' -o /dev/null -D - http://site1.lab.test/style.css | grep -iE 'HTTP|content-encoding|expires|cache-control'

# ── กล่อง Ubuntu ────────────────────────────────────────────
sudo ln -s /etc/nginx/sites-available/site1.conf /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
