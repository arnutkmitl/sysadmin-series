#!/usr/bin/env bash
# โปรเจกต์จบเล่ม: Multi-Site Web Server
# SysAdmin Pocket Series M05 Web Server: Apache & Nginx
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── ส่วนกลางที่ใช้ร่วมกัน ───────────────────────────────────
sudo mkdir -p /etc/nginx/snippets
for d in static.lab.test wp.lab.test app.lab.test; do sudo --preserve-env=REQUESTS_CA_BUNDLE certbot certonly --nginx -d $d --server https://localhost:14000/dir --agree-tos -m admin@lab.test --non-interactive | grep Successfully; done
sudo chmod 755 /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh

# ── Server Block ทั้งสามเว็บ ────────────────────────────────
sudo nginx -t && sudo systemctl reload nginx
cd /var/www/wordpress
sudo -u apache /usr/local/bin/wp option update home https://wp.lab.test
sudo -u apache /usr/local/bin/wp option update siteurl https://wp.lab.test
curl -s https://static.lab.test/ | grep -o '<h1>[^<]*'
curl -s https://app.lab.test/api

# ── ตรวจรับงาน ──────────────────────────────────────────────
sudo WP_PASS='Lab-Admin-2569!' ./check-sites.sh | tail -8
# ⚠️ systemctl stop app ทำให้ app.lab.test ตอบ 502 ทันที ทดลองบนเครื่องทดสอบ หรือนอกเวลาที่มีผู้ใช้ และสั่ง start คืนทันทีหลังตรวจ
sudo systemctl stop app
sudo WP_PASS='Lab-Admin-2569!' ./check-sites.sh | grep -E "FAIL|จาก"
sudo systemctl start app
sudo --preserve-env=REQUESTS_CA_BUNDLE certbot renew --cert-name wp.lab.test --force-renewal --no-random-sleep-on-renew | grep success
sudo journalctl -u nginx --since "-1min" --no-pager | grep -i reload | tail -1
testssl --quiet --color 0 --add-ca /opt/pebble/certs/lab-root.pem https://wp.lab.test | grep "Overall Grade"
