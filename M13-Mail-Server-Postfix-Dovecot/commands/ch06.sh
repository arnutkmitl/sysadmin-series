#!/usr/bin/env bash
# บทที่ 6 Capstone: ระบบอีเมลสององค์กร
# SysAdmin Pocket Series M13 Mail Server
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── ผลบน mail1 ──────────────────────────────────────────────
# บนเครื่อง mail1
sudo ./check-mail.sh

# ── รอบแรก ──────────────────────────────────────────────────
# บนเครื่อง mail2
sudo ./check-mail.sh -v

# ── certificate และ Dovecot ─────────────────────────────────
# บนเครื่อง mail2
sudo dnf install -y dovecot dovecot-pigeonhole sqlite
sudo python3 -m venv /opt/certbot
sudo /opt/certbot/bin/pip install -q --upgrade pip
sudo /opt/certbot/bin/pip install -q certbot
sudo ln -s /opt/certbot/bin/certbot /usr/bin/certbot
sudo ./setup-pebble.sh | tail -2
sudo firewall-cmd --permanent --add-service={http,imaps,pop3s,smtp-submission,smtps}
sudo firewall-cmd --reload
export REQUESTS_CA_BUNDLE=/opt/pebble/certs/pebble.minica.pem
sudo --preserve-env=REQUESTS_CA_BUNDLE certbot certonly --standalone --server https://localhost:14000/dir -d mail.example.org --agree-tos -m admin@example.org --no-eff-email --non-interactive --deploy-hook "systemctl reload postfix dovecot"
sed 's/mail\.example\.com/mail.example.org/g' mail1-local.conf > mail2-local.conf
diff mail1-local.conf mail2-local.conf
sudo sed -i 's/^!include auth-system.conf.ext/#!include auth-system.conf.ext/' /etc/dovecot/conf.d/10-auth.conf
sudo install -m 644 mail2-local.conf /etc/dovecot/local.conf
sudo install -d -m 755 /etc/dovecot/sieve
sudo install -m 644 junk.sieve /etc/dovecot/sieve/junk.sieve
sudo sievec /etc/dovecot/sieve/junk.sieve
for u in malee admin info support; do sudo ./add-mailuser.sh $u@example.org; done
sudo cut -d: -f1,3- /etc/dovecot/users
sudo doveconf -n > /dev/null && echo config-ok
sudo systemctl enable --now dovecot
sudo doveadm mailbox status -u malee@example.org messages INBOX

# ── Postfix ─────────────────────────────────────────────────
# บนเครื่อง mail2
sudo postconf -e "virtual_transport = lmtp:unix:private/dovecot-lmtp" "smtpd_tls_cert_file = /etc/letsencrypt/live/mail.example.org/fullchain.pem" "smtpd_tls_key_file = /etc/letsencrypt/live/mail.example.org/privkey.pem" "smtpd_tls_security_level = may" "smtpd_tls_auth_only = yes" "smtp_tls_security_level = may" "smtpd_tls_loglevel = 1" "smtp_tls_loglevel = 1" "smtpd_sasl_type = dovecot" "smtpd_sasl_path = private/auth" "smtpd_sasl_auth_enable = no" "smtpd_sender_login_maps = lmdb:/etc/postfix/sender_login" "smtpd_recipient_restrictions = check_policy_service unix:private/quota-status"
sudo postconf -M submission/inet="submission inet n - n - - smtpd" 465/inet="465 inet n - n - - smtpd"
sudo postconf -P "submission/inet/syslog_name=postfix/submission" "submission/inet/smtpd_tls_security_level=encrypt" "submission/inet/smtpd_sasl_auth_enable=yes" "submission/inet/smtpd_client_restrictions=permit_sasl_authenticated,reject" "submission/inet/smtpd_sender_restrictions=reject_sender_login_mismatch" "submission/inet/smtpd_relay_restrictions=permit_sasl_authenticated,reject"
sudo postconf -P "465/inet/syslog_name=postfix/submissions" "465/inet/smtpd_tls_wrappermode=yes" "465/inet/smtpd_sasl_auth_enable=yes" "465/inet/smtpd_client_restrictions=permit_sasl_authenticated,reject" "465/inet/smtpd_sender_restrictions=reject_sender_login_mismatch" "465/inet/smtpd_relay_restrictions=permit_sasl_authenticated,reject"
sudo postfix check
sudo systemctl restart postfix

# ── timer และรอบสุดท้าย ─────────────────────────────────────
# บนเครื่อง mail2
sudo install -m 750 backup-mail.sh /usr/local/sbin/backup-mail.sh
sudo install -m 644 certbot-renew.service certbot-renew.timer mail-backup.service mail-backup.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now certbot-renew.timer mail-backup.timer
sudo systemctl start mail-backup.service
sudo ./check-mail.sh

# ── ขอใบเสนอราคาและตอบกลับ ──────────────────────────────────
# บนเครื่อง mail1
swaks --server mail.example.com --port 587 --tls --auth LOGIN --auth-user info@example.com --auth-password 'Info-Mail2569' --from info@example.com --to support@example.org --header 'From: =?UTF-8?B?...?= <info@example.com>' --header 'Subject: =?UTF-8?B?...?=' --header 'Message-Id: <rfq-2569-11@example.com>' --header 'Content-Type: text/plain; charset=UTF-8' --body 'รบกวนเสนอราคากระดาษ A4 80 แกรม จำนวน 500 รีม ส่งภายในสิ้นเดือนครับ' 2>&1 | grep -E "^<~  250 2.0.0|\*\*"
# บนเครื่อง mail2
sudo grep -E "Authentication-Results" -A1 $(sudo grep -rl "rfq-2569-11@example.com" /var/mail/vhosts/example.org/support/) | grep -oE "(dkim|spf|dmarc)=[a-z]+[^;]*" | cut -c1-70
swaks --server mail.example.org --port 465 --tlsc --auth LOGIN --auth-user support@example.org --auth-password 'Support-Mail2569' --from support@example.org --to info@example.com --header 'From: =?UTF-8?B?...?= <support@example.org>' --header 'Subject: =?UTF-8?B?...?=' --header 'In-Reply-To: <rfq-2569-11@example.com>' --header 'Content-Type: text/plain; charset=UTF-8' --body 'ราคารีมละ 105 บาท รวม 52,500 บาท ส่งได้ภายใน 7 วันค่ะ' 2>&1 | grep -E "^<~  250 2.0.0|\*\*"
# บนเครื่อง mail1
F=$(sudo grep -rl "In-Reply-To: <rfq-2569-11@example.com>" /var/mail/vhosts/example.com/info/); sudo grep -E "^Authentication-Results" -A1 "$F" | grep -oE "(dkim|spf|dmarc)=[a-z]+[^;]*" | cut -c1-70

# ── อีเมลปลอมระหว่างการเจรจา ────────────────────────────────
# PowerShell บนเครื่อง Windows
curl.exe -sS --url smtp://192.168.56.26:25 --mail-from ceo@example.com --mail-rcpt support@example.org -T forged-ceo.eml -v 2>&1 | Select-String "^< 5"
curl.exe -sS --url smtp://192.168.56.25:25 --mail-from support@example.org --mail-rcpt info@example.com -T forged-support.eml -v 2>&1 | Select-String "^< 250 2.0.0"
# บนเครื่อง mail1
sudo grep -E "opendmarc.*example.org (pass|fail)" /var/log/maillog | tail -2
sudo doveadm mailbox status -u info@example.com messages INBOX Junk

# ── 6.5 ข้อจำกัดของการตรวจจากตัวเครื่อง ─────────────────────
# บนเครื่อง ubu
ls -l /etc/ssl/certs/ | grep -i snakeoil
echo | openssl s_client -connect ubu1:993 2>/dev/null | grep -E "Verify return|subject="

# ── Ubuntu Server 26.04 ─────────────────────────────────────
# บนเครื่อง ubu
sudo ./check-mail.sh -v
