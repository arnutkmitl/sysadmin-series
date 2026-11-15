#!/usr/bin/env bash
# บทที่ 2 Dovecot และการยืนยันตัวตน
# SysAdmin Pocket Series M13 Mail Server
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 2.2 certificate จาก Pebble ──────────────────────────────
# บนเครื่อง mail1
sudo dnf install -y certbot
sudo python3 -m venv /opt/certbot
sudo /opt/certbot/bin/pip install -q --upgrade pip
sudo /opt/certbot/bin/pip install -q certbot
sudo ln -s /opt/certbot/bin/certbot /usr/bin/certbot
certbot --version
chmod +x setup-pebble.sh
sudo ./setup-pebble.sh
sudo ss -ltnp | grep pebble
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload
export REQUESTS_CA_BUNDLE=/opt/pebble/certs/pebble.minica.pem
sudo --preserve-env=REQUESTS_CA_BUNDLE certbot certonly --standalone --server https://localhost:14000/dir -d mail.example.com --agree-tos -m admin@example.com --no-eff-email --non-interactive
sudo openssl x509 -in /etc/letsencrypt/live/mail.example.com/cert.pem -noout -issuer -ext subjectAltName -enddate
sudo --preserve-env=REQUESTS_CA_BUNDLE certbot reconfigure --cert-name mail.example.com --deploy-hook "systemctl reload postfix dovecot" --non-interactive
sudo grep -E "authenticator|hook" /etc/letsencrypt/renewal/mail.example.com.conf
sudo --preserve-env=REQUESTS_CA_BUNDLE certbot renew --cert-name mail.example.com --force-renewal
sudo journalctl -u dovecot -u postfix --since "-10 min" --no-pager | grep -i reload

# ── 2.3 ติดตั้งและตั้งค่า Dovecot ───────────────────────────
# บนเครื่อง mail1
sudo dnf install -y dovecot
dovecot --version
grep -n -v '^\s*#' /etc/dovecot/dovecot.conf | grep -v ':$'
grep -n '^!include' /etc/dovecot/conf.d/10-auth.conf
sudo sed -i 's/^!include auth-system.conf.ext/#!include auth-system.conf.ext/' /etc/dovecot/conf.d/10-auth.conf
sudo install -m 644 local.conf /etc/dovecot/local.conf

# ── 2.4 ผู้ใช้อีเมลและรหัสผ่าน ──────────────────────────────
# บนเครื่อง mail1
chmod +x add-mailuser.sh
sudo ./add-mailuser.sh somchai@example.com
sudo ./add-mailuser.sh suda@example.com
sudo cut -c1-40 /etc/dovecot/users
sudo ls -l /etc/dovecot/users
sudo ./add-mailuser.sh test@example.com
sudo ./add-mailuser.sh someone@gmail.com
sudo systemctl enable --now dovecot
sudo ss -tlnp | grep dovecot
sudo ls -l /var/spool/postfix/private/ | grep -E 'auth|dovecot'
sudo doveadm auth test somchai@example.com Somchai-Mail2569
sudo doveadm auth test somchai@example.com wrongpass
sudo doveadm user somchai@example.com
sudo doveadm mailbox list -u somchai@example.com

# ── 2.5 ให้ Postfix ส่งอีเมลเข้ากล่องผ่าน LMTP ──────────────
# บนเครื่อง mail1
sudo postconf -e "virtual_transport = lmtp:unix:private/dovecot-lmtp"
swaks --to somchai@example.com --from admin@example.com --server 127.0.0.1 --header "Subject: via lmtp" --silent 2
sudo grep "to=<somchai@example.com>" /var/log/maillog | tail -1

# ── 2.6 TLS ของ Postfix ─────────────────────────────────────
# บนเครื่อง mail1
sudo postconf -e "smtpd_tls_cert_file = /etc/letsencrypt/live/mail.example.com/fullchain.pem" "smtpd_tls_key_file = /etc/letsencrypt/live/mail.example.com/privkey.pem" "smtpd_tls_security_level = may" "smtpd_tls_auth_only = yes" "smtp_tls_security_level = may" "smtpd_tls_loglevel = 1" "smtp_tls_loglevel = 1"
echo QUIT | openssl s_client -connect mail.example.com:25 -starttls smtp -brief

# ── 2.7 ทดสอบ IMAPS และ POP3S ───────────────────────────────
# บนเครื่อง mail1
sudo firewall-cmd --permanent --add-service={imaps,pop3s,smtp-submission,smtps}
sudo firewall-cmd --reload
sudo firewall-cmd --list-services
printf 'a LOGIN somchai@example.com Somchai-Mail2569\nb STATUS INBOX (MESSAGES UNSEEN)\nc LOGOUT\n' | openssl s_client -connect mail.example.com:993 -quiet
curl -s --url "imaps://mail.example.com/" -u somchai@example.com:Somchai-Mail2569
printf 'USER somchai@example.com\nPASS Somchai-Mail2569\nSTAT\nQUIT\n' | openssl s_client -connect mail.example.com:995 -quiet
sudo grep "imap-login: Login" /var/log/maillog | tail -1

# ── 2.8 SASL และ submission ─────────────────────────────────
# บนเครื่อง mail1
sudo postconf -e "smtpd_sasl_type = dovecot" "smtpd_sasl_path = private/auth" "smtpd_sasl_auth_enable = no" "smtpd_sender_login_maps = lmdb:/etc/postfix/sender_login"
sudo postconf -M submission/inet="submission inet n - n - - smtpd"
sudo postconf -P "submission/inet/syslog_name=postfix/submission" "submission/inet/smtpd_tls_security_level=encrypt" "submission/inet/smtpd_sasl_auth_enable=yes" "submission/inet/smtpd_client_restrictions=permit_sasl_authenticated,reject" "submission/inet/smtpd_sender_restrictions=reject_sender_login_mismatch" "submission/inet/smtpd_relay_restrictions=permit_sasl_authenticated,reject"
sudo postconf -M 465/inet="465 inet n - n - - smtpd"
sudo postconf -P "465/inet/syslog_name=postfix/submissions" "465/inet/smtpd_tls_wrappermode=yes" "465/inet/smtpd_sasl_auth_enable=yes" "465/inet/smtpd_client_restrictions=permit_sasl_authenticated,reject" "465/inet/smtpd_sender_restrictions=reject_sender_login_mismatch" "465/inet/smtpd_relay_restrictions=permit_sasl_authenticated,reject"
sudo postfix check
sudo systemctl reload postfix
sudo ss -tlnp | grep master

# ── ทดสอบจาก mail2 ──────────────────────────────────────────
scp -P 52245 admin@127.0.0.1:/opt/pebble/certs/lab-root.pem .
scp -P 52246 lab-root.pem admin@127.0.0.1:
# บนเครื่อง mail2
sudo cp lab-root.pem /etc/pki/ca-trust/source/anchors/m13-lab-root.pem
sudo update-ca-trust
swaks --server mail.example.com --port 587 --quit-after EHLO 2>&1 | grep -E "STARTTLS|AUTH"
swaks --server mail.example.com --port 587 --tls --quit-after AUTH --auth LOGIN --auth-user somchai@example.com --auth-password 'Somchai-Mail2569' 2>&1 | grep -E "STARTTLS|AUTH|235"
swaks --server mail.example.com --port 587 --tls --auth LOGIN --auth-user somchai@example.com --auth-password 'Somchai-Mail2569' --from somchai@example.com --to malee@example.org --header "Subject: from Thunderbird-like client 587"
echo U29tY2hhaS1NYWlsMjU2OQ== | base64 -d
swaks --server mail.example.com --port 465 --tlsc --auth LOGIN --auth-user suda@example.com --auth-password 'Suda-Mail2569' --from suda@example.com --to malee@example.org --header "Subject: via 465" --silent 2 && echo sent-465
sudo grep "to=<malee@example.org>" /var/log/maillog | tail -2
# บนเครื่อง mail1
sudo grep "client=.*sasl_username=" /var/log/maillog | tail -1

# ── กรณีที่ต้องถูกปฏิเสธ ────────────────────────────────────
# บนเครื่อง mail2
swaks --server mail.example.com --port 25 --tls --quit-after EHLO 2>&1 | grep -E "AUTH" || echo "no AUTH on port 25"
swaks --server mail.example.com --port 587 --tls --auth LOGIN --auth-user somchai@example.com --auth-password 'wrong-pass' --from somchai@example.com --to malee@example.org 2>&1 | grep -E "^<~\*|^\*\*\*"
swaks --server mail.example.com --port 587 --tls --auth LOGIN --auth-user somchai@example.com --auth-password 'Somchai-Mail2569' --from suda@example.com --to malee@example.org 2>&1 | grep -E "^<~\*|^\*\*\*"
swaks --server mail.example.com --port 587 --tls --from somchai@example.com --to malee@example.org 2>&1 | grep -E "^<~\*|^\*\*\*"
# บนเครื่อง mail1
sudo grep -E "submission/smtpd.*(warning|NOQUEUE)" /var/log/maillog | tail -3

# ── Ubuntu Server 26.04 ─────────────────────────────────────
# บนเครื่อง ubu
sudo apt install -y dovecot-imapd dovecot-pop3d dovecot-lmtpd
dovecot --version
grep -v '^\s*#' /etc/dovecot/dovecot.conf | grep -v '^$'
sudo grep "to=<somchai@example.com>.*status=bounced" /var/log/mail.log | tail -1
sudo doveconf -f protocol=lmtp -h auth_username_format
sudo systemctl reload dovecot
swaks --to somchai@example.com --from admin@example.com --server 127.0.0.1 --header "Subject: ubuntu lmtp 2" --silent 2
sudo doveadm mailbox status -u somchai@example.com messages INBOX
sudo doveadm auth test somchai@example.com Somchai-Mail2569 | head -1
sudo postconf -M submission/inet="submission inet n - n - - smtpd"
swaks --server 127.0.0.1 --port 587 --tls --auth LOGIN --auth-user somchai@example.com --auth-password 'Somchai-Mail2569' --from somchai@example.com --to somchai@example.com --header "Subject: ubuntu 587 n" 2>&1 | grep -E "235|queued"
