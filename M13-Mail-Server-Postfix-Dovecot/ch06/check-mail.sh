#!/bin/bash
# check-mail.sh: ตรวจ mail server ตามเล่ม M13 ว่าพร้อมใช้งานจริงหรือไม่
#   sudo ./check-mail.sh                ตรวจโดเมนของเครื่องนี้ (อ่านจาก postconf mydomain)
#   sudo ./check-mail.sh -v             แสดงเหตุผลของข้อที่ FAIL ด้วย
#   sudo DOMAIN=example.org ./check-mail.sh
# ข้อที่ขึ้น SKIP คือส่วนที่เครื่องนี้ไม่ได้ติดตั้ง เช่น Roundcube หรือ SpamAssassin ไม่นับเป็น FAIL
set -uo pipefail
# ใน pipeline ใช้ grep ... >/dev/null ไม่ใช้ grep -q: grep -q หยุดอ่านกลางทาง คำสั่งต้นทางโดน SIGPIPE แล้ว pipefail ทำให้ผลกลับข้าง

DOMAIN=${DOMAIN:-$(postconf -h mydomain 2>/dev/null)}
HOST=${HOST:-$(postconf -h myhostname 2>/dev/null)}
SELECTOR=${SELECTOR:-202611}      # selector ของ DKIM
CERT_DAYS=${CERT_DAYS:-14}        # certificate ต้องเหลืออายุมากกว่ากี่วัน
QUEUE_MAX=${QUEUE_MAX:-20}        # อีเมลค้างใน queue ได้ไม่เกินกี่ฉบับ
VERBOSE=0; [ "${1:-}" = "-v" ] && VERBOSE=1

if [ "$(id -u)" -ne 0 ]; then
    echo "ต้องรันด้วย sudo" >&2; exit 2
fi
for c in postconf dig openssl swaks ss; do
    command -v $c >/dev/null || { echo "ไม่พบคำสั่ง $c ติดตั้งก่อน" >&2; exit 2; }
done

n=0; pass=0; fail=0; skip=0
why=""
check() {   # check "คำอธิบาย" ฟังก์ชัน   ฟังก์ชันคืน 0 = PASS, 1 = FAIL, 3 = SKIP
    local desc=$1; shift
    n=$((n + 1)); why=""
    "$@" >/dev/null 2>&1
    case $? in
        0) printf '[PASS] %02d %s\n' "$n" "$desc"; pass=$((pass + 1)) ;;
        3) printf '[SKIP] %02d %s\n' "$n" "$desc"; skip=$((skip + 1)) ;;
        *) printf '[FAIL] %02d %s\n' "$n" "$desc"; fail=$((fail + 1))
           [ "$VERBOSE" = 1 ] && [ -n "$why" ] && printf '            %s\n' "$why" ;;
    esac
    return 0
}
because() { why=$*; return 1; }
have() { command -v "$1" >/dev/null 2>&1; }
pc() { postconf -h "$1" 2>/dev/null; }
pcP() { postconf -P "$1" 2>/dev/null | sed 's/^[^=]*= //'; }

# ---------- ค่าจากระบบ ----------
IP=$(dig +short "$HOST" A | tail -1)
DBT=$(pc default_database_type)
if [ -f /var/log/maillog ]; then LOG=/var/log/maillog; else LOG=/var/log/mail.log; fi
SUB=$(postconf -M submission/inet 2>/dev/null)

# ---------- DNS ----------
dns_mx()    { dig +short MX "$DOMAIN" | grep -i " $HOST\.\?$" >/dev/null || because "MX ของ $DOMAIN ไม่ชี้ไปที่ $HOST"; }
dns_a()     { [ -n "$IP" ] && ip -4 -o addr show | grep " $IP/" >/dev/null || because "A ของ $HOST ($IP) ไม่ใช่ IP ของเครื่องนี้"; }
dns_ptr()   { [ "$(dig +short -x "$IP" | sed 's/\.$//')" = "$HOST" ] || because "PTR ของ $IP ไม่ใช่ $HOST"; }
dns_spf()   { dig +short TXT "$DOMAIN" | grep 'v=spf1' | grep -- '-all' >/dev/null || because "ไม่มี SPF ที่ลงท้ายด้วย -all"; }
dns_dkim()  {
    have opendkim-testkey || return 3
    opendkim-testkey -d "$DOMAIN" -s "$SELECTOR" -vvv 2>&1 | grep 'key OK' >/dev/null || because "opendkim-testkey ไม่ได้ key OK"
}
dns_dmarc() { dig +short TXT "_dmarc.$DOMAIN" | grep -E 'p=(quarantine|reject)' >/dev/null || because "DMARC ไม่ใช่ quarantine หรือ reject"; }

# ---------- service และ port ----------
svc()       { systemctl is-active --quiet "$1" || because "$1 ไม่ทำงาน"; }
svc_opt()   { systemctl list-unit-files "$1.service" 2>/dev/null | grep "^$1" >/dev/null || return 3; svc "$1"; }
port()      { ss -tln | awk '{print $4}' | grep -E "[:.]$1\$" >/dev/null || because "ไม่มีโปรแกรมฟัง port $1"; }
no_port()   { ! ss -tln | awk '{print $4}' | grep -E "[:.]$1\$" >/dev/null || because "port $1 ยังเปิดอยู่"; }

# ---------- TLS ----------
cert_ok() {   # cert_ok port [starttls]
    local opt=""; [ -n "${2:-}" ] && opt="-starttls $2"
    local out end
    out=$(echo | timeout 10 openssl s_client -connect "$HOST:$1" -servername "$HOST" $opt 2>/dev/null)
    echo "$out" | grep 'Verify return code: 0 (ok)' >/dev/null || { because "certificate ที่ port $1 ตรวจไม่ผ่าน"; return 1; }
    end=$(echo "$out" | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
    [ $(( ($(date -d "$end" +%s) - $(date +%s)) / 86400 )) -gt "$CERT_DAYS" ] || because "certificate ที่ port $1 เหลือไม่ถึง $CERT_DAYS วัน"
}

# ---------- Postfix ----------
relay_rule() { pc smtpd_relay_restrictions | grep 'reject_unauth_destination' >/dev/null || because "smtpd_relay_restrictions ไม่มี reject_unauth_destination"; }
mynet()      {   # ทุกค่าใน mynetworks ต้องเป็น loopback ของเครื่องตัวเอง
    local m
    for m in $(pc mynetworks | tr ',' ' '); do
        [[ $m =~ ^(127\.0\.0\.0/8|\[::1\]/128|\[::ffff:127\.0\.0\.0\]/104)$ ]] || { because "mynetworks มี $m"; return 1; }
    done
}
auth25()     { ! swaks --server "$IP" --port 25 --tls --quit-after EHLO 2>&1 | grep -E '250.AUTH' >/dev/null || because "port 25 เสนอ AUTH"; }
auth587()    {
    swaks --server "$IP" --port 587 --quit-after EHLO 2>&1 | grep -E '250.AUTH' >/dev/null && { because "port 587 เสนอ AUTH ก่อน STARTTLS"; return 1; }
    swaks --server "$IP" --port 587 --tls --quit-after EHLO 2>&1 | grep -E '250.AUTH' >/dev/null || because "port 587 ไม่เสนอ AUTH หลัง STARTTLS"
}
sender_map() {
    [ -n "$(pc smtpd_sender_login_maps)" ] || { because "ไม่ได้ตั้ง smtpd_sender_login_maps"; return 1; }
    echo "$SUB" | grep 'reject_sender_login_mismatch' >/dev/null || because "submission ไม่มี reject_sender_login_mismatch"
}
rfc_alias()  {
    local a
    for a in postmaster abuse; do
        postmap -q "$a@$DOMAIN" "$(pc virtual_alias_maps | awk '{print $1}')" >/dev/null || { because "ไม่มี alias $a@$DOMAIN"; return 1; }
    done
}
queue_len()  { local q; q=$(postqueue -p | grep -cE '^[0-9A-F]'); [ "$q" -le "$QUEUE_MAX" ] || because "อีเมลค้างใน queue $q ฉบับ"; }
milter_err() { ! journalctl --since "-1 hour" -q 2>/dev/null | grep 'connect to Milter service' >/dev/null || because "ชั่วโมงที่ผ่านมา Postfix ต่อ milter ไม่ได้"; }

# ---------- Dovecot ----------
dc_ssl()     { [ "$(doveconf -h ssl 2>/dev/null)" = required ] || because "ssl = $(doveconf -h ssl 2>/dev/null)"; }
dc_users()   {   # ทุกกล่องใน vmailbox ต้อง login ได้ คือมีบรรทัดใน /etc/dovecot/users
    local map u miss=""
    map=$(pc virtual_mailbox_maps | awk '{print $1}'); map=${map#*:}
    for u in $(grep -vE '^\s*(#|$)' "$map" | awk '{print $1}'); do
        grep "^$u:" /etc/dovecot/users >/dev/null || miss="$miss $u"
    done
    [ -z "$miss" ] || because "ไม่มีรหัสผ่าน:$miss"
}

# ---------- เส้นทางอีเมลจริง ----------
dkim_sign() {   # ส่งอีเมลถึง postmaster ของโดเมนเอง แล้วดูว่า OpenDKIM เซ็น
    have opendkim || return 3
    local mid="check-mail.$$.$(date +%s)@$DOMAIN" id
    printf 'Message-ID: <%s>
Subject: check-mail

ตรวจลายเซ็นโดย check-mail.sh
' "$mid" | sendmail -f "postmaster@$DOMAIN" "postmaster@$DOMAIN"
    sleep 4
    id=$(grep -oE "[0-9A-F]+: message-id=<$mid>" "$LOG" | cut -d: -f1 | head -1)
    [ -n "$id" ] || { because "ไม่พบอีเมลทดสอบใน $LOG"; return 1; }
    grep -E "opendkim.*$id: DKIM-Signature field added \(s=$SELECTOR, d=$DOMAIN\)" "$LOG" >/dev/null || because "อีเมลทดสอบ $id ไม่ได้ลายเซ็นของ $DOMAIN"
}

# ---------- ส่วนเสริม ----------
spam_milter() { svc_opt spamassassin; local r=$?; [ $r = 3 ] && return 3; [ $r = 0 ] || return 1
                pc smtpd_milters | grep 8890 >/dev/null || because "spamass-milter ไม่อยู่ใน smtpd_milters"; }
postscreen()  { postconf -M smtp/inet | grep postscreen >/dev/null || return 3
                [[ $(pc postscreen_cache_map) != btree:* ]] || because "postscreen_cache_map ยังเป็น btree"; }
quota()       { doveconf -h mail_plugins 2>/dev/null | grep quota >/dev/null || return 3
                pc smtpd_recipient_restrictions | grep quota-status >/dev/null || because "Postfix ไม่ถาม quota-status"; }
webmail()     { [ -d /usr/share/roundcubemail ] || [ -d /var/www/roundcube ] || return 3
                [ "$(curl -s -o /dev/null -w '%{http_code}' "https://$HOST/")" = 200 ] || because "https://$HOST/ ไม่ตอบ 200"; }
renew_timer() { have certbot || return 3
                systemctl is-active --quiet certbot-renew.timer || systemctl is-active --quiet certbot.timer || because "ไม่มี timer ต่ออายุ certificate"; }
backup_new()  { [ -d /var/backups/mail ] || return 3
                find /var/backups/mail -name 'mail-*.tar.gz' -mmin -1560 | grep . >/dev/null || because "ไม่มี backup ใน 26 ชั่วโมงที่ผ่านมา"; }
disk_mail()   { local u; u=$(df --output=pcent /var/mail | tail -1 | tr -dc 0-9); [ "$u" -lt 80 ] || because "ดิสก์ของ /var/mail ใช้ไป $u%"; }

echo "check-mail.sh  $HOST  ($DOMAIN, $IP)  $(date '+%F %T')"
echo "--- DNS"
check "MX ของ $DOMAIN ชี้ไปที่ $HOST"            dns_mx
check "A ของ $HOST เป็น IP ของเครื่องนี้"           dns_a
check "PTR ของ $IP เป็น $HOST"                    dns_ptr
check "SPF ของ $DOMAIN ลงท้ายด้วย -all"            dns_spf
check "DKIM selector $SELECTOR ตรงกับกุญแจในเครื่อง" dns_dkim
check "DMARC เป็น quarantine หรือ reject"          dns_dmarc
echo "--- service และ port"
check "postfix ทำงาน"                              svc postfix
check "dovecot ทำงาน"                              svc dovecot
check "opendkim ทำงาน"                             svc_opt opendkim
check "opendmarc ทำงาน"                            svc_opt opendmarc
check "port 25, 465, 587 และ 993 เปิด"              eval 'port 25 && port 465 && port 587 && port 993'
check "port 110 และ 143 ที่ไม่เข้ารหัสปิด"             eval 'no_port 110 && no_port 143'
echo "--- TLS"
check "certificate ที่ 25 (STARTTLS) ใช้ได้เกิน $CERT_DAYS วัน"  cert_ok 25 smtp
check "certificate ที่ 465 ใช้ได้เกิน $CERT_DAYS วัน"            cert_ok 465
check "certificate ที่ 993 ใช้ได้เกิน $CERT_DAYS วัน"            cert_ok 993
echo "--- Postfix"
check "ไม่เป็น open relay (reject_unauth_destination)"  relay_rule
check "mynetworks มีแค่เครื่องตัวเอง"                     mynet
check "port 25 ไม่เสนอ AUTH"                           auth25
check "port 587 เสนอ AUTH หลัง STARTTLS เท่านั้น"         auth587
check "ผู้ใช้ส่งได้เฉพาะในนามตัวเอง"                       sender_map
check "มี postmaster และ abuse"                        rfc_alias
check "queue ค้างไม่เกิน $QUEUE_MAX ฉบับ"                 queue_len
check "ชั่วโมงที่ผ่านมาไม่มีข้อผิดพลาดการต่อ milter"           milter_err
echo "--- Dovecot"
check "ssl = required"                               dc_ssl
check "ทุกกล่องใน vmailbox มีรหัสผ่าน"                    dc_users
echo "--- เส้นทางอีเมล"
check "อีเมลขาออกได้ลายเซ็น DKIM จริง"                    dkim_sign
echo "--- ส่วนเสริม"
check "SpamAssassin ต่อกับ Postfix"                     spam_milter
check "postscreen ใช้ cache ที่ใช้ได้"                     postscreen
check "quota ถูกตรวจตั้งแต่ขั้น SMTP"                      quota
check "webmail ตอบที่ https://$HOST/"                  webmail
check "มี timer ต่ออายุ certificate"                      renew_timer
check "มี backup ภายใน 26 ชั่วโมง"                        backup_new
check "ดิสก์ของ /var/mail ใช้ไม่ถึง 80%"                    disk_mail

echo "สรุป: PASS $pass  FAIL $fail  SKIP $skip  จาก $n ข้อ"
[ "$fail" -eq 0 ]
