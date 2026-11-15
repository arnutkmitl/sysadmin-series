#!/usr/bin/env bash
# บทที่ 5 Production และ troubleshooting
# SysAdmin Pocket Series M13 Mail Server
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── เปลี่ยน userdb เป็น passwd-file ─────────────────────────
# บนเครื่อง mail1
sudo cp -a /etc/dovecot/local.conf /etc/dovecot/local.conf.ch04
sudo doveadm user somchai@example.com
sudo sed -i 's/^\([^:]*:[^:]*\)$/\1::::::/' /etc/dovecot/users
sudo doveadm user somchai@example.com

# ── ตั้ง quota ──────────────────────────────────────────────
# บนเครื่อง mail1
sudo sed -i 's/^protocols = imap pop3 lmtp$/protocols = imap pop3 lmtp\nmail_plugins = $mail_plugins quota/' /etc/dovecot/local.conf
sudo doveconf -n > /dev/null && echo config-ok
sudo doveconf -f protocol=lmtp -h mail_plugins
sudo doveconf -f protocol=imap -h mail_plugins
sudo systemctl restart dovecot
sudo sed -i 's/^\(support@example.com:.*::::::\)$/\1userdb_quota_rule=*:storage=1M/' /etc/dovecot/users
sudo ./add-mailuser.sh support@example.com
sudo cut -d: -f1,3- /etc/dovecot/users | grep support
sudo doveadm quota get -u somchai@example.com
sudo doveadm quota get -u support@example.com

# ── ปฏิเสธตั้งแต่ขั้น SMTP ──────────────────────────────────
# บนเครื่อง mail1
sudo postconf -e "smtpd_recipient_restrictions = check_policy_service unix:private/quota-status"
sudo systemctl reload postfix
head -c 450000 /dev/urandom > /tmp/report.bin
for i in 1 2 3; do swaks --server 127.0.0.1 --from admin@example.com --to support@example.com --header "Subject: report $i" --attach @/tmp/report.bin 2>&1 | grep -E "^<\*\*|^<-  250 2.0.0"; sleep 1; sudo doveadm quota get -u support@example.com | grep STORAGE; done
sudo grep 72CEBC3F /var/log/maillog | grep status= | cut -c1-200
# บนเครื่อง mail2
head -c 450000 /dev/urandom > /tmp/report.bin
echo "รายงานประจำเดือน" | mail -s "report from example.org" -a /tmp/report.bin -r malee@example.org support@example.com
# บนเครื่อง mail1
sudo grep -E "NOQUEUE.*support@example.com" /var/log/maillog | tail -1 | cut -c1-230

# ── 5.2 log และรายงานประจำวัน ───────────────────────────────
# บนเครื่อง mail1
cat /etc/logrotate.d/rsyslog
grep -E "^(weekly|rotate|compress|dateext)" /etc/logrotate.conf
sudo dnf install -y postfix-perl-scripts
sudo pflogsumm -d today /var/log/maillog
sudo systemctl daemon-reload
sudo systemctl enable --now mail-report.timer
sudo systemctl start mail-report.service
sudo doveadm search -u admin@example.com mailbox INBOX subject "mail log" | wc -l

# ── 5.3 queue ───────────────────────────────────────────────
# บนเครื่อง mail1
echo "ใบสั่งซื้อ" | mail -s "PO 2569-11" -r info@example.com buyer@[192.168.56.99]
echo "ใบสั่งซื้อ 2" | mail -s "PO 2569-12" -r info@example.com buyer@[192.168.56.99]
sudo postqueue -p
sudo postcat -h -q ED6BE9C776 | grep -E "^(From|To|Subject|Date):"
postconf maximal_queue_lifetime bounce_queue_lifetime delay_warning_time minimal_backoff_time maximal_backoff_time
sudo postsuper -h ED6BE9C776
sudo postsuper -H ED6BE9C776
sudo postsuper -d ED6BE9C776
sudo postsuper -d ALL deferred
sudo postqueue -p
# ⚠️ postsuper -d ลบอีเมลออกจากเครื่องทันทีโดยไม่แจ้งผู้ส่ง และกู้คืนไม่ได้ ใช้เมื่อแน่ใจว่าอีเมลเหล่านั้นไม่ต้องการแล้ว เช่น spam ที่เล็ดลอดออกไปจากบัญชีที่ถูกขโมยรหัสผ่าน ถ้าไม่แน่ใจ ให้พักไว้ด้วย postsuper -h ก่อน
sudo postqueue -p | tail -1
sudo postqueue -j | jq -r 'select(.sender=="suda@example.com") | .queue_id' | sudo postsuper -d -
sudo postqueue -p | grep -E "^[0-9A-F]" | awk '{print $1, $NF}'

# ── script backup ───────────────────────────────────────────
# บนเครื่อง mail1
sudo dnf install -y sqlite
sudo install -m 750 backup-mail.sh /usr/local/sbin/backup-mail.sh
sudo /usr/local/sbin/backup-mail.sh
sudo systemctl enable --now mail-backup.timer mail-report.timer
systemctl list-timers 'mail-*' --no-pager | head -3

# ── กู้คืนอีเมลที่ผู้ใช้ลบ ──────────────────────────────────
# บนเครื่อง mail1
sudo doveadm search -u somchai@example.com mailbox INBOX subject "ประชุมทีมวันจันทร์"
sudo doveadm expunge -u somchai@example.com mailbox INBOX subject "ประชุมทีมวันจันทร์"
B=/var/backups/mail/mail-20261115-1910.tar.gz
sudo mkdir -p /tmp/restore
sudo tar -xzf "$B" -C /tmp/restore var/mail/vhosts/example.com/somchai
sudo chown -R vmail:vmail /tmp/restore
sudo doveadm import -u somchai@example.com -s maildir:/tmp/restore/var/mail/vhosts/example.com/somchai Restored mailbox INBOX subject "ประชุมทีมวันจันทร์"
sudo doveadm mailbox list -u somchai@example.com
sudo doveadm search -u somchai@example.com mailbox Restored.INBOX subject "ประชุมทีมวันจันทร์"
sudo doveadm move -u somchai@example.com INBOX mailbox Restored.INBOX all
sudo doveadm search -u somchai@example.com mailbox INBOX subject "ประชุมทีมวันจันทร์" | wc -l
sudo doveadm mailbox list -u somchai@example.com
sudo rm -rf /tmp/restore

# ── 5.5 ต่ออายุ certificate อัตโนมัติ ───────────────────────
# บนเครื่อง mail1
sudo systemctl daemon-reload
sudo systemctl enable --now certbot-renew.timer
systemctl list-timers certbot-renew.timer --no-pager | head -2
sudo systemctl start certbot-renew.service
sudo tail -1 /var/log/letsencrypt/letsencrypt.log | cut -c1-100

# ── 5.7 docker-mailserver ───────────────────────────────────
# บนเครื่อง docker
cd ~/dms && docker compose pull
docker image ls ghcr.io/docker-mailserver/docker-mailserver --format "{{.Tag}} {{.Size}}"
docker compose up -d
docker exec mailserver cat /VERSION
docker exec mailserver openssl req -x509 -newkey rsa:2048 -nodes -days 365 -subj "/CN=mail.example.net" -addext "subjectAltName=DNS:mail.example.net" -keyout /tmp/docker-mailserver/ssl/key.pem -out /tmp/docker-mailserver/ssl/cert.pem
docker compose restart
docker ps --format "{{.Names}} {{.Status}}" | grep mailserver
docker exec mailserver postconf mail_version
docker exec mailserver dovecot --version
docker stats --no-stream --format "{{.Name}} {{.MemUsage}}" mailserver
docker exec mailserver setup email add somchai@example.net 'Somchai-Mail2569'
docker exec mailserver setup alias add postmaster@example.net somchai@example.net
docker exec mailserver setup email list
docker exec mailserver setup config dkim domain example.net
# บนเครื่อง mail2
swaks --server 192.168.56.30 --port 587 --tls --auth LOGIN --auth-user somchai@example.net --auth-password 'Somchai-Mail2569' --from somchai@example.net --to postmaster@example.net --header "Subject: hello dms" 2>&1 | grep -E "235|250 2.0.0|\*\*"
swaks --server 192.168.56.30 --port 25 --from x@example.org --to victim@gmail.com --quit-after RCPT 2>&1 | grep -E "^<\*\*"
printf 'a LOGIN somchai@example.net Somchai-Mail2569\nb STATUS INBOX (MESSAGES)\nc LOGOUT\n' | openssl s_client -connect 192.168.56.30:993 -quiet 2>/dev/null | grep STATUS

# ── Ubuntu Server 26.04 ─────────────────────────────────────
# บนเครื่อง ubu
sudo doveconf -n > /dev/null && echo config-ok
sudo sed -i 's/quota_storage_grace = 10%/quota_storage_grace = 10M/' /etc/dovecot/local.conf
sudo doveconf -n > /dev/null && echo config-ok
sudo systemctl restart dovecot
sudo doveadm quota get -u somchai@example.com
