#!/usr/bin/env bash
# บทที่ 3 Webmail และ client
# SysAdmin Pocket Series M13 Mail Server
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 3.2 ติดตั้งแพ็กเกจ ──────────────────────────────────────
# บนเครื่อง mail1
sudo dnf install -y nginx php-fpm roundcubemail
sudo ls -lZd /var/lib/roundcubemail /var/log/roundcubemail /etc/roundcubemail
grep -E "^(user|group|listen) " /etc/php-fpm.d/www.conf

# ── 3.3 ชื่อ autoconfig ใน DNS ──────────────────────────────
# บนเครื่อง ns1
sudo sed -i 's/2026111205 ; serial/2026111501 ; serial/' /var/named/example.com.zone
echo "autoconfig IN  CNAME mail" | sudo tee -a /var/named/example.com.zone
sudo named-checkzone example.com /var/named/example.com.zone
sudo rndc reload example.com IN internal
# บนเครื่อง mail1
sudo unbound-control flush_zone example.com
dig +short autoconfig.example.com

# ── 3.4 Nginx และ certificate แบบ webroot ───────────────────
# บนเครื่อง mail1
sudo install -d /var/www/letsencrypt /var/www/autoconfig/mail
sudo install -m 644 mail.example.com.conf /etc/nginx/conf.d/mail.example.com.conf
sudo nginx -t
sudo systemctl enable --now php-fpm nginx
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
export REQUESTS_CA_BUNDLE=/opt/pebble/certs/pebble.minica.pem
sudo --preserve-env=REQUESTS_CA_BUNDLE certbot certonly --webroot -w /var/www/letsencrypt --server https://localhost:14000/dir --cert-name mail.example.com -d mail.example.com -d autoconfig.example.com --deploy-hook "systemctl reload postfix dovecot nginx" --non-interactive
sudo grep -E "authenticator|webroot|hook" /etc/letsencrypt/renewal/mail.example.com.conf
sudo openssl x509 -in /etc/letsencrypt/live/mail.example.com/cert.pem -noout -ext subjectAltName
sudo --preserve-env=REQUESTS_CA_BUNDLE certbot renew --cert-name mail.example.com --dry-run --server https://localhost:14000/dir

# ── 3.5 ตั้งค่า Roundcube ───────────────────────────────────
# บนเครื่อง mail1
sudo tail -1 /var/log/roundcubemail/errors.log
sudo install -m 644 99-roundcube.ini /etc/php.d/99-roundcube.ini
sudo install -m 640 -g apache config.inc.php /etc/roundcubemail/config.inc.php
sudo sed -i "s|DES_KEY_PLACEHOLDER|$(openssl rand -base64 18)|" /etc/roundcubemail/config.inc.php
sudo grep -c DES_KEY_PLACEHOLDER /etc/roundcubemail/config.inc.php
sudo systemctl restart php-fpm
curl -s -o /dev/null -w '%{http_code} %{redirect_url}\n' http://mail.example.com/
curl -s https://mail.example.com/ | grep -oE "<title>[^<]*</title>"
sudo ls -l /var/lib/roundcubemail/roundcube.db
curl -s -o /dev/null -w '%{http_code}\n' https://mail.example.com/bin/initdb.sh

# ── SELinux บล็อกการ login ครั้งแรก ─────────────────────────
# บนเครื่อง mail1
sudo grep "Permission denied" /var/log/roundcubemail/errors.log | tail -1
sudo ausearch -m AVC -ts recent | grep -o 'avc: .*'
sudo ausearch -m AVC -ts recent | audit2why
sudo setsebool -P httpd_can_sendmail 1
getsebool httpd_can_sendmail httpd_can_network_connect

# ── ทดสอบ webmail ───────────────────────────────────────────
# บนเครื่อง mail1
sudo grep -E "client=.*sasl_username=somchai" /var/log/maillog | tail -1
sudo grep "to=<malee@example.org>" /var/log/maillog | tail -1
sudo doveadm mailbox status -u somchai@example.com messages Sent

# ── เตรียมเครื่อง Windows ───────────────────────────────────
# PowerShell บนเครื่อง Windows
Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value "192.168.56.25 mail.example.com autoconfig.example.com"
ping -n 1 mail.example.com
scp -P 52245 admin@127.0.0.1:/opt/pebble/certs/lab-root.pem .
certutil -user -addstore Root lab-root.pem
# ⚠️ root certificate ที่เพิ่มเข้าคลังของ Windows ทำให้เครื่องเชื่อถือทุก certificate ที่ CA นั้นออก ใช้กับ root ของ Lab บนเครื่องทดสอบเท่านั้น เมื่อเลิกใช้ Lab ให้ลบออกด้วย `certutil -user -delstore Root "Pebble Root CA 2d362d"` โดยใช้ชื่อตามที่หน้าต่างแสดง
curl.exe -s --ssl-no-revoke --cacert lab-root.pem -o NUL -w "webmail %{http_code}\n" https://mail.example.com/
curl.exe -s --ssl-no-revoke --cacert lab-root.pem --url "imaps://mail.example.com/" -u somchai@example.com:Somchai-Mail2569

# ── 3.7 autoconfig สำหรับ Thunderbird ───────────────────────
# บนเครื่อง mail1
sudo install -m 644 config-v1.1.xml /var/www/autoconfig/mail/config-v1.1.xml
curl -s "https://autoconfig.example.com/mail/config-v1.1.xml?emailaddress=somchai@example.com" | grep -E "hostname|port|socketType"
# PowerShell บนเครื่อง Windows
curl.exe -s --ssl-no-revoke --cacert lab-root.pem "https://autoconfig.example.com/mail/config-v1.1.xml?emailaddress=somchai@example.com" | Select-String hostname

# ── Ubuntu Server 26.04 ─────────────────────────────────────
# บนเครื่อง ubu
sudo tail -1 /var/log/nginx/error.log
sudo apt install -y --no-install-recommends nginx php-fpm php8.5-sqlite3 php8.5-intl php8.5-mbstring php8.5-xml php8.5-zip php8.5-gd
curl -sfLO https://github.com/roundcube/roundcubemail/releases/download/1.6.20/roundcubemail-1.6.20-complete.tar.gz
sudo tar xzf roundcubemail-1.6.20-complete.tar.gz -C /var/www
sudo mv /var/www/roundcubemail-1.6.20 /var/www/roundcube
sudo install -d -o www-data -g www-data -m 750 /var/lib/roundcube-db
sudo chown -R www-data:www-data /var/www/roundcube/temp /var/www/roundcube/logs
sudo ls -l /var/lib/roundcube-db/
curl -sk --resolve mail.example.com:443:127.0.0.1 -o /dev/null -w '%{http_code}\n' https://mail.example.com/installer/
