#!/usr/bin/env bash
# บทที่ 1 DNS ของอีเมลและ Postfix
# SysAdmin Pocket Series M13 Mail Server
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── record ของ example.com ──────────────────────────────────
# บนเครื่อง mail1
dig +short mx example.com
dig +short txt example.com
dig +short mail.example.com
dig +short -x 192.168.56.25

# ── zone ของ example.org ────────────────────────────────────
# บนเครื่อง ns1
sudo tee /var/named/example.org.zone > /dev/null <<'END'
; /var/named/example.org.zone  โดเมนขององค์กรที่สองใน Lab
$TTL 3600
@       IN  SOA  ns1.example.com. hostmaster.example.org. (
                 2026111501 3600 900 1209600 300 )
        IN  NS   ns1.example.com.
        IN  MX   10 mail.example.org.
        IN  TXT  "v=spf1 mx -all"
mail    IN  A    192.168.56.26
END
sudo chown root:named /var/named/example.org.zone
sudo chmod 640 /var/named/example.org.zone
sudo named-checkzone example.org /var/named/example.org.zone
sudo sed -i 's|^    include "/etc/named.rfc1912.zones";|    zone "example.org" IN {\n        type primary;\n        file "example.org.zone";\n    };\n&|' /etc/named.conf
sudo sed -n '/zone "example.org"/,/};/p' /etc/named.conf
sudo sed -i 's/2026111204 3600 900 1209600 300 )/2026111501 3600 900 1209600 300 )/' /var/named/192.168.56.rev
echo "26      IN  PTR  mail.example.org." | sudo tee -a /var/named/192.168.56.rev
sudo named-checkzone 56.168.192.in-addr.arpa /var/named/192.168.56.rev
sudo named-checkconf && sudo rndc reload
# บนเครื่อง mail1
dig +short mx example.org
dig +short mail.example.org
dig +short txt example.org
dig +short -x 192.168.56.26

# ── 1.2 ติดตั้ง Postfix ─────────────────────────────────────
# บนเครื่อง mail1
sudo dnf install -y postfix s-nail swaks perl-Sys-Hostname
postconf mail_version
postconf -n

# ── 1.3 ตั้งค่าหลักของ Postfix ──────────────────────────────
# บนเครื่อง mail1
sudo postconf -e "myhostname = mail.example.com" "mydomain = example.com" "myorigin = \$mydomain" "inet_interfaces = all" "inet_protocols = ipv4" "mynetworks = 127.0.0.0/8" "smtpd_banner = \$myhostname ESMTP" "disable_vrfy_command = yes" "smtpd_helo_required = yes" "message_size_limit = 26214400"
postconf myhostname mydomain myorigin inet_interfaces mydestination mynetworks
# ⚠️ ห้ามเพิ่มวงเครือข่ายอื่นลงใน mynetworks เพื่อแก้ปัญหาผู้ใช้ส่งอีเมลไม่ได้ ทุก IP ใน mynetworks ส่งอีเมลไปที่ใดก็ได้โดยไม่ต้องใส่รหัสผ่าน ถ้าใส่ทั้งวงของบริษัท เครื่องลูกข่ายที่ติดมัลแวร์เครื่องเดียวจะส่ง spam ในนามองค์กรได้ทันที บทที่ 2 ให้ผู้ใช้ส่งอีเมลด้วยการยืนยันตัวตนแทน
sudo postfix check
sudo systemctl enable --now postfix
sudo firewall-cmd --permanent --add-service=smtp
sudo firewall-cmd --reload
sudo ss -tlnp | grep ':25 '

# ── 1.4 virtual domain และกล่องอีเมล ────────────────────────
# บนเครื่อง mail1
sudo groupadd -g 5000 vmail
sudo useradd -u 5000 -g vmail -M -d /var/mail/vhosts -s /sbin/nologin vmail
sudo install -d -o vmail -g vmail -m 770 /var/mail/vhosts
ls -ldZ /var/mail/vhosts
sudo tee /etc/postfix/vmailbox > /dev/null <<'END'
# ที่อยู่อีเมล            โฟลเดอร์ Maildir ใต้ /var/mail/vhosts (ต้องลงท้ายด้วย /)
somchai@example.com   example.com/somchai/
suda@example.com      example.com/suda/
admin@example.com     example.com/admin/
info@example.com      example.com/info/
support@example.com   example.com/support/
END
sudo tee /etc/postfix/virtual > /dev/null <<'END'
# ชื่อที่ RFC กำหนดให้ทุกโดเมนต้องรับ ส่งต่อให้ผู้ดูแล
postmaster@example.com  admin@example.com
abuse@example.com       admin@example.com
END
sudo postmap lmdb:/etc/postfix/vmailbox
sudo postmap lmdb:/etc/postfix/virtual
sudo postconf -e "virtual_mailbox_domains = example.com" "virtual_mailbox_base = /var/mail/vhosts" "virtual_mailbox_maps = lmdb:/etc/postfix/vmailbox" "virtual_alias_maps = lmdb:/etc/postfix/virtual" "virtual_uid_maps = static:5000" "virtual_gid_maps = static:5000"
sudo postfix check
sudo systemctl reload postfix
postmap -q somchai@example.com lmdb:/etc/postfix/vmailbox
postmap -q abuse@example.com lmdb:/etc/postfix/virtual
swaks --to somchai@example.com --from admin@example.com --server 127.0.0.1 --header "Subject: test 1"
sudo find /var/mail/vhosts -type f
sudo grep "to=<somchai@example.com>" /var/log/maillog | tail -1
swaks --to postmaster@example.com --from somchai@example.com --server 127.0.0.1 --header "Subject: test alias" > /dev/null
swaks --to nobody@example.com --from somchai@example.com --server 127.0.0.1
sudo grep -E "to=<admin@example.com>, orig_to=<postmaster" /var/log/maillog | tail -1

# ── 1.5 ส่งอีเมลข้ามโดเมน ───────────────────────────────────
# บนเครื่อง mail1
echo "สวัสดีจาก example.com" | mail -s "hello example.org" -r somchai@example.com malee@example.org
sudo grep "to=<malee@example.org>" /var/log/maillog | tail -1
# บนเครื่อง mail2
sudo grep -E "from=<somchai@example.com>|to=<malee@example.org>" /var/log/maillog | tail -2
sudo find /var/mail/vhosts -type f

# ── 1.6 กัน open relay ──────────────────────────────────────
# บนเครื่อง mail1
postconf smtpd_relay_restrictions
# บนเครื่อง mail2
swaks --server mail.example.com --from spammer@example.org --to victim@gmail.com
# บนเครื่อง mail1
sudo postconf -e "smtpd_relay_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination"
sudo systemctl reload postfix
postconf smtpd_relay_restrictions
# บนเครื่อง mail2
swaks --server mail.example.com --from spammer@example.org --to victim@gmail.com --quit-after RCPT --silent 1 2>&1 | grep -E "RCPT|<\*\*"
swaks --server mail.example.com --from malee@example.org --to somchai@example.com --header "Subject: from example.org" --silent 2

# ── Ubuntu Server 26.04 ─────────────────────────────────────
# บนเครื่อง ubu
postconf mail_version default_database_type mydestination
sudo postconf -e "mydestination = \$myhostname, localhost.\$mydomain, localhost"
postconf mydestination
