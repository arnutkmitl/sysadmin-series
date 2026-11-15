#!/usr/bin/env bash
# บทที่ 4 DKIM, DMARC และ anti-spam
# SysAdmin Pocket Series M13 Mail Server
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 4.2 ติดตั้งแพ็กเกจ ──────────────────────────────────────
# บนเครื่อง mail1
sudo dnf install -y opendkim opendkim-tools opendmarc spamassassin spamass-milter dovecot-pigeonhole
opendmarc -V

# ── สร้างกุญแจ ──────────────────────────────────────────────
# บนเครื่อง mail1
sudo install -d -o opendkim -g opendkim -m 750 /etc/opendkim/keys/example.com
sudo opendkim-genkey -b 2048 -d example.com -s 202611 -D /etc/opendkim/keys/example.com
sudo chown opendkim:opendkim /etc/opendkim/keys/example.com/202611.private
sudo ls -l /etc/opendkim/keys/example.com

# ── KeyTable, SigningTable และ TrustedHosts ─────────────────
# บนเครื่อง mail1
sudo tee /etc/opendkim/KeyTable > /dev/null <<'END'
# ชื่อกุญแจ                        โดเมน:selector:ไฟล์กุญแจลับ
202611._domainkey.example.com   example.com:202611:/etc/opendkim/keys/example.com/202611.private
END
sudo tee /etc/opendkim/SigningTable > /dev/null <<'END'
# ผู้ส่งที่ตรงรูปแบบนี้ ลงลายเซ็นด้วยกุญแจชื่อนี้
*@example.com   202611._domainkey.example.com
END
sudo tee /etc/opendkim/TrustedHosts > /dev/null <<'END'
# เครื่องที่ส่งอีเมลผ่าน server นี้แล้วให้ลงลายเซ็น และไม่ต้องตรวจลายเซ็นขาเข้า
127.0.0.1
::1
END
sudo chgrp -R opendkim /etc/opendkim
sudo chmod 750 /etc/opendkim/keys
sudo sed -i -e 's/^Mode\tv$/Mode\tsv/' -e 's/^Selector\tdefault/#Selector\tdefault/' -e 's|^KeyFile\t/etc/opendkim/keys/default.private|#KeyFile\t/etc/opendkim/keys/default.private|' -e 's|^# KeyTable\t|KeyTable\t|' -e 's|^# SigningTable\t|SigningTable\t|' -e 's|^# ExternalIgnoreList\t|ExternalIgnoreList\t|' -e 's|^# InternalHosts\t|InternalHosts\t|' /etc/opendkim.conf
grep -vE '^\s*#|^\s*$' /etc/opendkim.conf
sudo opendkim -n && echo config-ok

# ── record DKIM ใน DNS ──────────────────────────────────────
# บนเครื่อง mail1
sudo cat /etc/opendkim/keys/example.com/202611.txt
# บนเครื่อง ns1
sudo sed -i 's/2026111501 ; serial/2026111502 ; serial/' /var/named/example.com.zone
cat 202611.txt | sudo tee -a /var/named/example.com.zone > /dev/null
sudo named-checkzone example.com /var/named/example.com.zone
sudo rndc reload example.com IN internal
# บนเครื่อง mail1
sudo systemctl enable --now opendkim
sudo unbound-control flush_zone example.com > /dev/null
sudo opendkim-testkey -d example.com -s 202611 -vvv

# ── 4.4 ต่อ milter เข้า Postfix และ SELinux ─────────────────
# บนเครื่อง mail1
sudo postconf -e "smtpd_milters = unix:/run/opendkim/opendkim.sock" "non_smtpd_milters = unix:/run/opendkim/opendkim.sock" "milter_default_action = accept"
sudo systemctl restart postfix
sudo grep "opendkim.sock: Permission denied" /var/log/maillog | tail -1
sudo ausearch -m AVC -ts today | grep -o 'avc: .*' | grep 'name="opendkim.sock"' | tail -1
sudo semanage port -l | grep milter
ps -eZ | grep -E "opendkim|opendmarc" | awk '{print $1, $NF}'
sudo sed -i 's|^Socket local:/run/opendkim/opendkim.sock|Socket inet:8891@localhost|' /etc/opendkim.conf
sudo systemctl restart opendkim
sudo ss -tlnp | grep ":8891 "
sudo postconf -e "smtpd_milters = inet:localhost:8891" "non_smtpd_milters = inet:localhost:8891"
sudo systemctl restart postfix
echo "ทดสอบลายเซ็น DKIM" | mail -s "dkim test from example.com" -r somchai@example.com malee@example.org
sudo grep "DKIM-Signature field added" /var/log/maillog | tail -1

# ── ตั้งค่า OpenDMARC ───────────────────────────────────────
# บนเครื่อง mail1
sudo sed -i -e 's|^# AuthservID name|AuthservID mail.example.com|' -e 's|^# TrustedAuthservIDs HOSTNAME|TrustedAuthservIDs mail.example.com|' -e 's|^# IgnoreAuthenticatedClients false|IgnoreAuthenticatedClients true|' -e 's|^# IgnoreHosts /etc/opendmarc/ignore.hosts|IgnoreHosts /etc/opendmarc/ignore.hosts|' -e 's|^# RejectFailures false|RejectFailures true|' -e 's|^# HistoryFile /var/spool/opendmarc/opendmarc.dat|HistoryFile /var/spool/opendmarc/opendmarc.dat|' /etc/opendmarc.conf
printf '127.0.0.1\n::1\n' | sudo tee /etc/opendmarc/ignore.hosts
sudo sed -i 's|^Socket local:/run/opendmarc/opendmarc.sock|Socket inet:8893@localhost|' /etc/opendmarc.conf
grep -vE '^\s*#|^\s*$' /etc/opendmarc.conf
sudo systemctl enable --now opendmarc
sudo postconf -e "smtpd_milters = inet:localhost:8891, inet:localhost:8893"
sudo systemctl restart postfix

# ── record DMARC ────────────────────────────────────────────
# บนเครื่อง ns1
echo '_dmarc  IN  TXT  "v=DMARC1; p=none; rua=mailto:dmarc@example.com; adkim=r; aspf=r"' | sudo tee -a /var/named/example.com.zone
# บนเครื่อง mail1
dig +short txt _dmarc.example.com
echo "dmarc@example.com       admin@example.com" | sudo tee -a /etc/postfix/virtual
sudo postmap lmdb:/etc/postfix/virtual
postmap -q dmarc@example.com lmdb:/etc/postfix/virtual

# ── ทดสอบอีเมลจริง ──────────────────────────────────────────
# บนเครื่อง mail2
echo "ทดสอบลายเซ็น DKIM" | mail -s "dkim test from example.org" -r malee@example.org somchai@example.com
# บนเครื่อง mail1
sudo grep "opendmarc.*example.org" /var/log/maillog | tail -2
# บนเครื่อง mail2
swaks --server mail.example.com --port 587 --tls --auth LOGIN --auth-user somchai@example.com --auth-password 'Somchai-Mail2569' --from somchai@example.com --to malee@example.org --header "Subject: signed via 587" --silent 2 && echo sent
sudo grep -E "signed via 587" -l -r /var/mail/vhosts/example.org/malee/ | head -1 | xargs sudo grep -c "^DKIM-Signature: v=1; a=rsa-sha256; c=relaxed/relaxed; d=example.com"

# ── อีเมลปลอมผู้ส่ง ภายใต้ p=none, quarantine และ reject ────
# บนเครื่อง mail2
swaks --server mail.example.com --port 25 --from ceo@example.com --to somchai@example.com --header "From: ผู้บริหาร <ceo@example.com>" --header "Subject: โอนเงินด่วน" --body "กรุณาโอนเงินให้คู่ค้าภายในวันนี้" --silent 2 && echo forged-accepted
# บนเครื่อง mail1
sudo grep -E "opendmarc.*: example.com" /var/log/maillog | tail -2
# บนเครื่อง ns1
sudo sed -i -e 's/2026111502 ; serial/2026111503 ; serial/' -e 's/p=none; rua=mailto:dmarc@example.com/p=quarantine; rua=mailto:dmarc@example.com/' /var/named/example.com.zone
sudo rndc reload example.com IN internal
# บนเครื่อง mail1
sudo unbound-control flush_zone example.com > /dev/null
# บนเครื่อง mail2
swaks --server mail.example.com --port 25 --from ceo@example.com --to somchai@example.com --header "From: ผู้บริหาร <ceo@example.com>" --header "Subject: โอนเงินด่วน 2" --body "กรุณาโอนเงิน" 2>&1 | grep -E "^<\*\*|^<-  250 2.0.0"
# บนเครื่อง mail1
sudo grep B785A2D53 /var/log/maillog | grep lmtp | cut -c1-120
F=$(sudo grep -rl "B785A2D53" /var/mail/vhosts/example.com/somchai/ | head -1); sudo sed -n '1,/^$/p' "$F" | grep -E "^Authentication-Results"
# บนเครื่อง ns1
sudo sed -i -e 's/2026111503 ; serial/2026111504 ; serial/' -e 's/p=quarantine; rua=/p=reject; rua=/' /var/named/example.com.zone
sudo rndc reload example.com IN internal
# บนเครื่อง mail1
sudo unbound-control flush_zone example.com > /dev/null
# บนเครื่อง mail2
swaks --server mail.example.com --port 25 --from ceo@example.com --to somchai@example.com --header "From: ผู้บริหาร <ceo@example.com>" --header "Subject: โอนเงินด่วน 3" --body "กรุณาโอนเงิน" 2>&1 | grep -E "^<\*\*|^<-  250 2.0.0"
# บนเครื่อง mail1
sudo grep milter-reject /var/log/maillog | tail -1
echo "ส่งจริงหลังตั้ง p=reject" | mail -s "after p=reject" -r somchai@example.com malee@example.org
# บนเครื่อง mail2
F=$(sudo grep -rl "after p=reject" /var/mail/vhosts/example.org/malee/ | head -1); sudo grep -E "^Authentication-Results" -A1 "$F" | grep -E "dmarc=|spf=|dkim="

# ── รายงาน DMARC ────────────────────────────────────────────
# บนเครื่อง mail1
sudo head -20 /var/spool/opendmarc/opendmarc.dat

# ── กฎและคะแนน ──────────────────────────────────────────────
# บนเครื่อง mail1
sudo sa-update -v
sudo systemctl enable --now spamassassin
sudo install -m 644 local.cf /etc/mail/spamassassin/local.cf
sudo spamassassin --lint && echo lint-ok
sudo systemctl restart spamassassin

# ── spamass-milter ──────────────────────────────────────────
# บนเครื่อง mail1
echo 'EXTRA_FLAGS="-m -r 15 -i 127.0.0.1"' | sudo tee -a /etc/sysconfig/spamass-milter
echo 'SOCKET="inet:8890@localhost"' | sudo tee -a /etc/sysconfig/spamass-milter
sudo systemctl enable --now spamass-milter
sudo ss -tlnp | grep ":8890 "
sudo postconf -e "smtpd_milters = inet:localhost:8891, inet:localhost:8893, inet:localhost:8890"
sudo systemctl reload postfix
# บนเครื่อง mail2
swaks --server mail.example.com --from malee@example.org --to somchai@example.com --header "Subject: ลดราคาพิเศษ" --body 'XJS*C4JDBQADN1.NSBN3*2IDNEN*GTUBE-STANDARD-ANTI-UBE-TEST-EMAIL*C.34X' 2>&1 | grep -E "^<\*\*|^<-  250 2.0.0"
# บนเครื่อง mail1
sudo grep "spamd: result" /var/log/maillog | grep GTUBE | tail -1 | cut -c1-110
sudo grep -E "spamd: result" /var/log/maillog | tail -2 | cut -c1-110
F=$(sudo grep -rlF "โอนเงินด่วน ค่าสินค้า" /var/mail/vhosts/example.com/somchai/ | head -1); sudo sed -n '1,/^$/p' "$F" | grep -E "^X-Spam-(Flag|Status)" -A1

# ── 4.7 Sieve ย้าย spam เข้า Junk ───────────────────────────
# บนเครื่อง mail1
sudo tee -a /etc/dovecot/local.conf > /dev/null <<'END'

# บทที่ 4: ให้ LMTP รัน Sieve และใช้ junk.sieve กับทุกคน
protocol lmtp {
  mail_plugins = $mail_plugins sieve
}
plugin {
  sieve_before = /etc/dovecot/sieve/junk.sieve
}
END
sudo install -d -m 755 /etc/dovecot/sieve
sudo install -m 644 junk.sieve /etc/dovecot/sieve/junk.sieve
sudo sievec /etc/dovecot/sieve/junk.sieve
ls -l /etc/dovecot/sieve/
sudo doveconf -n > /dev/null && echo config-ok
sudo systemctl reload dovecot
# บนเครื่อง mail2
swaks --server mail.example.com --from malee@example.org --to somchai@example.com --header "Subject: โอนเงินด่วน ค่าสินค้า งวด 2" --body "รบกวนโอนเงินค่าสินค้าภายในวันนี้ค่ะ" --silent 2 && echo sent
# PowerShell บนเครื่อง Windows
curl.exe -sS --url smtp://192.168.56.25:25 --mail-from billing@example.org --mail-rcpt somchai@example.com -T forged.eml
# บนเครื่อง mail1
sudo grep fileinto /var/log/maillog | tail -2 | cut -c1-190
sudo doveadm mailbox status -u somchai@example.com messages Junk

# ── 4.8 postscreen ──────────────────────────────────────────
# บนเครื่อง mail1
postconf -M smtp/inet
sudo postconf -M "smtp/inet=smtp inet n - n - 1 postscreen" "smtpd/pass=smtpd pass - - n - - smtpd" "dnsblog/unix=dnsblog unix - - n - 0 dnsblog" "tlsproxy/unix=tlsproxy unix - - n - 0 tlsproxy"
postconf -M smtp/inet smtpd/pass dnsblog/unix tlsproxy/unix
printf '# IP หรือวงที่ห้ามส่งอีเมลเข้ามาเลย\n#203.0.113.0/24  reject\n' | sudo tee /etc/postfix/postscreen_access.cidr > /dev/null
sudo postconf -e "postscreen_access_list = permit_mynetworks, cidr:/etc/postfix/postscreen_access.cidr" "postscreen_denylist_action = drop" "postscreen_greet_action = enforce" "postscreen_dnsbl_sites = zen.spamhaus.org*3, bl.spamcop.net*2" "postscreen_dnsbl_threshold = 3" "postscreen_dnsbl_action = enforce" "postscreen_cache_map = lmdb:\$data_directory/postscreen_cache"
sudo postfix check
sudo systemctl restart postfix
# บนเครื่อง mail2
swaks --server mail.example.com --from malee@example.org --to somchai@example.com --header "Subject: through postscreen 2" --silent 2 && echo sent
(exec 3<>/dev/tcp/192.168.56.25/25; printf 'EHLO bot.example.net\r\n' >&3; sleep 7; printf 'MAIL FROM:<x@bot.example.net>\r\nRCPT TO:<somchai@example.com>\r\nQUIT\r\n' >&3; timeout 4 cat <&3) | tail -4
# บนเครื่อง mail1
sudo grep postscreen /var/log/maillog | grep -vE "CONNECT|DISCONNECT" | tail -4 | cut -c1-170

# ── Ubuntu Server 26.04 ─────────────────────────────────────
# บนเครื่อง ubu
sudo grep -E "opendkim|milter-reject" /var/log/mail.log | grep -E "B0B8749FFD|can't load" | head -3 | cut -c39-190
opendkim[42908]: can't load key from /etc/opendkim/keys/example.com/202611.private: Permission denied
sudo chgrp -R opendkim /etc/opendkim
sudo chmod 750 /etc/opendkim/keys
sudo systemctl restart opendkim
sudo postqueue -f
sudo grep "DKIM-Signature field added" /var/log/mail.log | tail -1 | cut -c39-
