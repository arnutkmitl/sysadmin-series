#!/usr/bin/env bash
# HTTPS และความปลอดภัยพื้นฐาน
# SysAdmin Pocket Series M05 Web Server: Apache & Nginx
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── ติดตั้ง certbot บน Rocky Linux ──────────────────────────
sudo dnf install -y epel-release
sudo dnf install -y certbot python3-certbot-nginx
sudo python3 -m venv /opt/certbot
sudo /opt/certbot/bin/pip install --upgrade pip
sudo /opt/certbot/bin/pip install certbot certbot-nginx
sudo ln -s /opt/certbot/bin/certbot /usr/bin/certbot
sudo certbot --version

# ── เตรียม Lab ด้วย Pebble ──────────────────────────────────
sudo ./setup-pebble.sh
export REQUESTS_CA_BUNDLE=/opt/pebble/certs/pebble.minica.pem
sudo --preserve-env=REQUESTS_CA_BUNDLE certbot --nginx --server https://localhost:14000/dir -d site1.lab.test --agree-tos -m admin@lab.test --no-eff-email --non-interactive
curl -sI http://site1.lab.test/ | grep -E 'HTTP|Location'
curl -s https://site1.lab.test/
sudo certbot certificates

# ── ต่ออายุอัตโนมัติ ────────────────────────────────────────
sudo systemctl daemon-reload
sudo systemctl enable --now certbot-renew.timer
systemctl list-timers certbot-renew.timer --no-pager | head -2
sudo systemctl start certbot-renew.service
sudo tail -1 /var/log/letsencrypt/letsencrypt.log
sudo --preserve-env=REQUESTS_CA_BUNDLE certbot renew --force-renewal --no-random-sleep-on-renew
sudo certbot certificates | grep -E "Serial|Expiry"

# ── 3.2 Redirect จาก HTTP ไป HTTPS ──────────────────────────
sudo --preserve-env=REQUESTS_CA_BUNDLE certbot --nginx --server https://localhost:14000/dir -d site1.lab.test -d www.site1.lab.test --expand --non-interactive
for u in http://site1.lab.test/a http://www.site1.lab.test/a https://www.site1.lab.test/a; do printf '%-32s ' $u; curl -s -o /dev/null -w '%{http_code} %{redirect_url}\n' $u; done
curl -s -o /dev/null --resolve other.lab.test:443:192.168.56.20 https://other.lab.test/; echo "rc=$?"

# ── Apache ด้วยวิธี webroot ─────────────────────────────────
sudo dnf install -y mod_ssl
sudo --preserve-env=REQUESTS_CA_BUNDLE certbot certonly --webroot -w /var/www/site2 -d site2.lab.test --server https://localhost:14000/dir --agree-tos -m admin@lab.test --non-interactive
sudo apachectl configtest && sudo systemctl reload httpd
curl -sI http://site2.lab.test/a | grep -E 'HTTP|Location'
curl -sI https://site2.lab.test/ | grep -iE 'HTTP|server:|strict|x-frame|x-content'

# ── 3.3 Security Header ─────────────────────────────────────
curl -sI https://site1.lab.test/ | grep -iE 'strict|x-frame|x-content'
curl -sI https://site1.lab.test/style.css | grep -iE 'strict|x-frame|x-content|cache-control'
curl -sI https://site1.lab.test/style.css | grep -iE 'strict|x-frame|x-content|cache-control'

# ── 3.4 Security Checklist ──────────────────────────────────
curl -sI https://site1.lab.test/ | grep -i '^server:'
curl -s -o /dev/null -w 'DELETE -> %{http_code}\n' -X DELETE https://site1.lab.test/
for i in $(seq 1 30); do curl -s -o /dev/null -w '%{http_code}\n' https://site1.lab.test/; done | sort | uniq -c
sudo tail -1 /var/log/nginx/site1-error.log
curl -s -o /dev/null -w 'dir listing -> %{http_code}\n' https://site1.lab.test/files/
curl -s -o /dev/null -w 'TRACE -> %{http_code}\n' -X TRACE https://site2.lab.test/
nmap --script ssl-enum-ciphers -p 443 site2.lab.test | grep -E "TLSv|least strength"

# ── ตรวจคะแนน TLS ───────────────────────────────────────────
sudo dnf install -y testssl nmap
testssl --quiet --color 0 --add-ca /opt/pebble/certs/lab-root.pem https://site1.lab.test > /tmp/testssl.txt
grep -E "Overall Grade|TLS 1  |TLS 1.1|TLS 1.2|TLS 1.3|Strict Transport" /tmp/testssl.txt

# ── กล่อง Ubuntu ────────────────────────────────────────────
sudo apt install -y certbot python3-certbot-nginx python3-certbot-apache
systemctl cat certbot.timer | grep -E 'OnCalendar|Randomized'
