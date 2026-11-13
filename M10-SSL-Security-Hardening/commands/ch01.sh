#!/usr/bin/env bash
# SSL/TLS ให้ได้เกรด A+
# SysAdmin Pocket Series M10 SSL & Security Hardening
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 1.2 ทบทวน certbot กับ Pebble ────────────────────────────
export REQUESTS_CA_BUNDLE=/opt/pebble/certs/pebble.minica.pem
sudo --preserve-env=REQUESTS_CA_BUNDLE certbot --nginx --server https://localhost:14000/dir -d site.lab.test -d www.lab.test --agree-tos -m admin@lab.test --no-eff-email --non-interactive --redirect
curl -sI http://site.lab.test/ | head -1
curl -s https://site.lab.test/

# ── certbot ต่ออายุเมื่อใด ──────────────────────────────────
sudo systemctl daemon-reload
sudo systemctl enable --now certbot-renew.timer
systemctl list-timers certbot-renew.timer --no-pager | head -2
sudo tail -2 /etc/letsencrypt/renewal/site.lab.test.conf

# ── deploy hook ─────────────────────────────────────────────
sudo tee /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh > /dev/null <<'EOF'
#!/bin/sh
# /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh
# รันหลัง certbot ได้ใบรับรองใหม่ทุกครั้ง ให้ Nginx โหลดใบใหม่
systemctl reload nginx
EOF
sudo chmod 755 /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh
sudo --preserve-env=REQUESTS_CA_BUNDLE certbot renew --dry-run --server https://localhost:14000/dir --no-random-sleep-on-renew

# ── 1.3 อ่าน chain ด้วย openssl ─────────────────────────────
# บนเครื่อง attacker
openssl s_client -connect site.lab.test:443 -servername site.lab.test -showcerts < /dev/null 2>/dev/null | grep -E "^ *[0-9] s:|^ *i:|Protocol|Cipher is|Peer signature type|Negotiated|Verify return"
# บนเครื่อง attacker
openssl s_client -connect site.lab.test:443 -servername site.lab.test < /dev/null 2>/dev/null | openssl x509 -noout -issuer -dates -ext subjectAltName

# ── สร้างกุญแจและจำกัดสิทธิ์ ────────────────────────────────
sudo sh -c 'tsig-keygen -a hmac-sha256 certbot-key > /etc/named/certbot.key'
sudo chown root:named /etc/named/certbot.key
sudo chmod 640 /etc/named/certbot.key
sudo named-checkconf && sudo systemctl reload named

# ── ไฟล์ credentials ของ certbot ────────────────────────────
sudo install -m 600 /dev/null /etc/letsencrypt/rfc2136.ini
sudo tee /etc/letsencrypt/rfc2136.ini > /dev/null <<'EOF'
dns_rfc2136_server = 127.0.0.1
dns_rfc2136_port = 53
dns_rfc2136_name = certbot-key
dns_rfc2136_algorithm = HMAC-SHA256
EOF
sudo awk -F'"' '/secret/ {print "dns_rfc2136_secret = " $2}' /etc/named/certbot.key | sudo sh -c 'cat >> /etc/letsencrypt/rfc2136.ini'
$ sudo stat -c '%a %U %n' /etc/letsencrypt/rfc2136.ini
600 root /etc/letsencrypt/rfc2136.ini
$ sudo grep -c . /etc/letsencrypt/rfc2136.ini
5

# ── ขอใบ wildcard ───────────────────────────────────────────
sudo --preserve-env=REQUESTS_CA_BUNDLE certbot certonly --dns-rfc2136 --dns-rfc2136-credentials /etc/letsencrypt/rfc2136.ini --dns-rfc2136-propagation-seconds 5 --server https://localhost:14000/dir -d 'lab.test' -d '*.lab.test' --non-interactive
printf 'server 127.0.0.1\nzone lab.test\nupdate add evil.lab.test. 60 A 6.6.6.6\nsend\n' | sudo nsupdate -k /etc/named/certbot.key
sudo grep REFUSED /var/named/data/named.run | tail -1

# ── ใช้ใบ wildcard กับเว็บใหม่ ──────────────────────────────
sudo mkdir -p /usr/share/nginx/app
echo "app.lab.test (wildcard)" | sudo tee /usr/share/nginx/app/index.html
sudo nginx -t && sudo systemctl reload nginx
curl -s https://app.lab.test/
sudo certbot certificates 2>/dev/null | grep -E "Name|Identifiers|Expiry"

# ── 1.5 crypto-policies: ตั้งความแข็งของการเข้ารหัสทั้งเครื่อง ────
update-crypto-policies --show
grep -E "^protocol@TLS|^min_rsa_size|^min_dh_size" /usr/share/crypto-policies/policies/{DEFAULT,FUTURE}.pol

# ── policy ชนะ config ของโปรแกรม ────────────────────────────
echo | openssl s_client -connect app.lab.test:443 -servername app.lab.test -tls1_1 2>&1 | grep -o "no protocols available"
for v in tls1 tls1_1 tls1_2; do echo | openssl s_client -connect app.lab.test:443 -servername app.lab.test -$v -cipher 'DEFAULT:@SECLEVEL=0' 2>&1 | grep -oE "^Protocol: .*|alert protocol version" | head -1 | sed "s/^/$v: /"; done

# ── FUTURE: แข็งขึ้น แต่ต้องรู้ว่าอะไรพัง ───────────────────
sudo update-crypto-policies --set FUTURE
sudo nginx -t
curl -sS -o /dev/null https://rockylinux.org
sudo dnf makecache --refresh
sudo update-crypto-policies --set DEFAULT
sudo systemctl restart nginx

# ── HSTS ────────────────────────────────────────────────────
sudo nginx -t && sudo systemctl reload nginx
curl -sI https://site.lab.test/ | grep -i strict

# ── 1.6 วัดผลด้วย testssl.sh ────────────────────────────────
# บนเครื่อง attacker
sudo dnf install -y epel-release
# บนเครื่อง attacker
sudo dnf install -y testssl
# บนเครื่อง attacker
rpm -q testssl
# บนเครื่อง attacker
testssl --quiet --color 0 --add-ca ~/lab-root.pem site.lab.test
# บนเครื่อง attacker
testssl --quiet --color 0 --add-ca ~/lab-root.pem -p -h site.lab.test

# ── chain ไม่ครบ ────────────────────────────────────────────
# บนเครื่อง attacker
curl -sS https://app.lab.test/
# บนเครื่อง attacker
echo | openssl s_client -connect app.lab.test:443 -servername app.lab.test 2>/dev/null | grep -E "^ *[0-9] s:|^ *i:|Verify return code"

# ── ชื่อไม่ตรง ──────────────────────────────────────────────
# บนเครื่อง attacker
curl -sS https://192.168.56.80/
# บนเครื่อง attacker
curl -s https://sec1.lab.test/

# ── ใบรับรองหมดอายุหรือใกล้หมด ──────────────────────────────
# บนเครื่อง attacker
echo | openssl s_client -connect site.lab.test:443 -servername site.lab.test 2>/dev/null | openssl x509 -noout -checkend $((30*86400)); echo rc=$?
# บนเครื่อง attacker
echo | openssl s_client -connect site.lab.test:443 -servername site.lab.test 2>/dev/null | openssl x509 -noout -checkend $((100*86400)); echo rc=$?
