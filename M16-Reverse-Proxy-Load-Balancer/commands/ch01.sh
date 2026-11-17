#!/usr/bin/env bash
# บทที่ 1 Reverse Proxy และ nginx
# SysAdmin Pocket Series M16 Reverse Proxy & Load Balancer
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── Lab 1.1 nginx ส่งต่อไปหลังบ้านเครื่องเดียว ──────────────
# บนเครื่อง lb1
sudo dnf install -y nginx
nginx -v
sudo firewall-cmd --permanent --add-service=http --add-service=https
sudo firewall-cmd --reload
sudo nginx -t
sudo systemctl enable --now nginx
curl -s -H "Host: web.lab.test" http://127.0.0.1/
sudo tail -1 /var/log/nginx/error.log
getsebool httpd_can_network_connect
sudo setsebool -P httpd_can_network_connect 1
curl -s -H "Host: web.lab.test" http://127.0.0.1/
sudo nginx -t && sudo systemctl reload nginx
# บนเครื่อง Host
curl -s --resolve web.lab.test:80:192.168.56.71 http://web.lab.test/
curl -s --resolve web.lab.test:80:192.168.56.71 -H "X-Forwarded-For: 1.2.3.4" http://web.lab.test/ | grep Forwarded-For

# ── Lab 1.2 สองหลังบ้านและ failover ─────────────────────────
# บนเครื่อง Host
for i in 1 2 3 4 5 6; do curl -s --resolve web.lab.test:80:192.168.56.71 http://web.lab.test/ | head -1; done
# บนเครื่อง be2
sudo systemctl stop be-app
# บนเครื่อง Host
for i in 1 2 3 4 5 6; do curl -s -o /dev/null -w "%{http_code} %{time_total}s\n" --resolve web.lab.test:80:192.168.56.71 http://web.lab.test/; done
# บนเครื่อง be2
sudo systemctl start be-app
sudo firewall-cmd --add-rich-rule='rule family=ipv4 source address=192.168.56.71 drop'
# บนเครื่อง Host
for i in 1 2 3 4 5 6; do curl -s -o /dev/null -w "%{http_code} %{time_total}s\n" --resolve web.lab.test:80:192.168.56.71 http://web.lab.test/; done
# บนเครื่อง lb1
sudo grep -E "timed out|disabled" /var/log/nginx/error.log | tail -2
# บนเครื่อง be2
sudo firewall-cmd --reload

# ── Lab 1.3 HTTPS จาก Pebble ────────────────────────────────
# บนเครื่อง lb1
sudo dnf install -y epel-release
sudo dnf install -y certbot python3-certbot-nginx
certbot --version
sudo REQUESTS_CA_BUNDLE=/opt/pebble/certs/pebble.minica.pem certbot --nginx -d web.lab.test \
# บนเครื่อง Host
curl -s -o /dev/null -w "%{http_code} -> %{redirect_url}\n" --resolve web.lab.test:80:192.168.56.71 http://web.lab.test/

# ── การต่ออายุอัตโนมัติ ─────────────────────────────────────
# บนเครื่อง lb1
systemctl is-enabled certbot-renew.timer; systemctl is-active certbot-renew.timer
sudo systemctl enable --now certbot-renew.timer
systemctl list-timers certbot-renew.timer --no-pager | head -2
sudo REQUESTS_CA_BUNDLE=/opt/pebble/certs/pebble.minica.pem certbot renew --dry-run
sudo grep "Var server" /var/log/letsencrypt/letsencrypt.log | tail -1
sudo REQUESTS_CA_BUNDLE=/opt/pebble/certs/pebble.minica.pem certbot renew --dry-run --server https://localhost:14000/dir
echo "REQUESTS_CA_BUNDLE=/opt/pebble/certs/pebble.minica.pem" | sudo tee -a /etc/sysconfig/certbot
sudo sed -i 's/^CERTBOT_ARGS=""/CERTBOT_ARGS="--force-renewal"/' /etc/sysconfig/certbot
sudo systemctl start certbot-renew.service
sudo journalctl -u certbot-renew.service -n 6 -o cat --no-pager
sudo sed -i 's/^CERTBOT_ARGS="--force-renewal"/CERTBOT_ARGS=""/' /etc/sysconfig/certbot

# ── 1.5 Cache และ timeout ───────────────────────────────────
# บนเครื่อง lb1
sudo nginx -t
sudo systemctl reload nginx; echo "reload rc=$?"
sudo install -d -m 700 -o nginx -g nginx /var/cache/nginx
sudo restorecon -Rv /var/cache/nginx
sudo nginx -t && sudo systemctl reload nginx
for i in 1 2 3; do curl -sk -o /dev/null -D - --resolve web.lab.test:443:127.0.0.1 https://web.lab.test/static/logo | grep -iE "x-cache|x-backend" | tr "\r\n" "  "; echo; done
curl -sk -o /dev/null -w "%{http_code} %{time_total}s\n" --resolve web.lab.test:443:127.0.0.1 "https://web.lab.test/slow?s=3"
curl -sk -o /dev/null -w "%{http_code} %{time_total}s\n" --resolve web.lab.test:443:127.0.0.1 "https://web.lab.test/slow?s=8"
