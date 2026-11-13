#!/bin/bash
# security-audit.sh: ตรวจ server ตาม Security Hardening Checklist 30 ข้อ (ภาคผนวก ก)
#   sudo ./security-audit.sh            ตรวจครบ 30 ข้อ
#   sudo ./security-audit.sh -v         แสดงเหตุผลของข้อที่ FAIL ด้วย
# ค่าด้านล่างปรับตาม server ของผู้อ่าน หรือส่งผ่านตัวแปรแวดล้อม เช่น SITE=www.example.com
set -uo pipefail
# ใน pipeline ใช้ grep ... >/dev/null ไม่ใช้ grep -q: grep -q หยุดอ่านกลางทาง คำสั่งต้นทางโดน SIGPIPE แล้ว pipefail ทำให้ผลกลับข้าง

SITE=${SITE:-site.lab.test}                    # ชื่อเว็บที่ต้องมี HTTPS
SSH_GROUP=${SSH_GROUP:-sshusers}               # กลุ่มเดียวที่ SSH เข้าได้
ALLOWED_TCP=${ALLOWED_TCP:-"22 2222 53 80 443"}   # port TCP ที่ยอมให้ listen บนทุก IP
CERT_DAYS=${CERT_DAYS:-14}                     # ใบรับรองต้องเหลืออายุมากกว่ากี่วัน
VERBOSE=0; [ "${1:-}" = "-v" ] && VERBOSE=1

if [ "$(id -u)" -ne 0 ]; then
    echo "ต้องรันด้วย sudo" >&2; exit 2
fi
for c in openssl curl ss; do
    command -v $c >/dev/null || { echo "ไม่พบคำสั่ง $c ติดตั้งก่อน (dnf install -y $c)" >&2; exit 2; }
done

n=0; pass=0
why=""
check() {   # check "หมวด: คำอธิบาย" ฟังก์ชันหรือคำสั่ง...
    local desc=$1; shift
    n=$((n + 1)); why=""
    if "$@" >/dev/null 2>&1; then
        printf '[PASS] %02d %s\n' "$n" "$desc"; pass=$((pass + 1))
    else
        printf '[FAIL] %02d %s\n' "$n" "$desc"
        [ "$VERBOSE" = 1 ] && [ -n "$why" ] && printf '            %s\n' "$why"
    fi
    return 0
}
have() { command -v "$1" >/dev/null 2>&1; }
because() { why=$*; return 1; }

# ---------- ค่าจากระบบ ----------
SSHD=$(sshd -T 2>/dev/null)
sshv() { awk -v k="$1" '$1 == k { $1 = ""; sub(/^ /, ""); print; exit }' <<< "$SSHD"; }
if have getenforce; then MAC=selinux; elif have aa-status; then MAC=apparmor; else MAC=none; fi
if have firewall-cmd; then FW=firewalld; elif have ufw; then FW=ufw; else FW=none; fi
CERT=$(echo | timeout 5 openssl s_client -connect "$SITE:443" -servername "$SITE" 2>/dev/null)

# ---------- SSH ----------
ssh_root()  { [ "$(sshv permitrootlogin)" = no ] || because "permitrootlogin = $(sshv permitrootlogin)"; }
ssh_pass()  { [ "$(sshv passwordauthentication)" = no ] || because "passwordauthentication = yes"; }
ssh_tries() { [ "$(sshv maxauthtries)" -le 4 ] || because "maxauthtries = $(sshv maxauthtries)"; }
ssh_group() { [[ " $(sshv allowgroups) " == *" $SSH_GROUP "* ]] || because "allowgroups ไม่มี $SSH_GROUP"; }
ssh_2fa()   { [[ $(sshv authenticationmethods) == *keyboard-interactive* ]] || because "authenticationmethods = $(sshv authenticationmethods)"; }

# ---------- fail2ban ----------
f2b_up()    { systemctl is-active --quiet fail2ban || because "fail2ban ไม่ทำงาน"; }
f2b_jail()  { fail2ban-client status "$1" >/dev/null 2>&1 || because "ไม่มี jail $1"; }

# ---------- TLS ----------
https_ok()  { [ "$(curl -s -o /dev/null -w '%{http_code}' "https://$SITE/")" = 200 ] || because "https://$SITE/ ไม่ตอบ 200"; }
redirect()  {
    local loc
    loc=$(curl -s -o /dev/null -w '%{redirect_url}' "http://$SITE/")
    [[ $loc == https://* ]] || because "http://$SITE/ ไม่ redirect ไป https"
}
cert_days() {
    local end
    end=$(openssl x509 -noout -enddate <<< "$CERT" 2>/dev/null | cut -d= -f2)
    [ -n "$end" ] || { because "อ่านใบรับรองของ $SITE ไม่ได้"; return 1; }
    [ $(( ($(date -d "$end" +%s) - $(date +%s)) / 86400 )) -gt "$CERT_DAYS" ] || because "ใบรับรองเหลือน้อยกว่า $CERT_DAYS วัน"
}
no_old_tls() {
    local v
    [ -n "$CERT" ] || { because "ไม่มี HTTPS ให้ตรวจ"; return 1; }
    # SECLEVEL=0 ให้ openssl ฝั่งเราเสนอ TLS รุ่นเก่าได้ ไม่อย่างนั้น crypto-policies ของเครื่องนี้ปฏิเสธเองก่อนถึง server
    for v in tls1 tls1_1; do
        echo | timeout 5 openssl s_client -connect "$SITE:443" -servername "$SITE" "-$v" -cipher 'DEFAULT:@SECLEVEL=0' >/dev/null 2>&1 \
            && { because "server ยังรับ $v"; return 1; }
    done
    return 0
}
hsts()      { curl -sI "https://$SITE/" | grep -i '^strict-transport-security:.*max-age=[1-9]' >/dev/null || because "ไม่มี HSTS header"; }
cryptopol() {
    have update-crypto-policies || return 0     # Ubuntu ไม่มี crypto-policies ให้ผ่าน
    [[ $(update-crypto-policies --show) != LEGACY* ]] || because "crypto-policies เป็น LEGACY"
}

# ---------- MAC ----------
mac_on() {
    case $MAC in
        selinux)  [ "$(getenforce)" = Enforcing ] && grep -q '^SELINUX=enforcing' /etc/selinux/config \
                      || because "SELinux ไม่ใช่ Enforcing ทั้งตอนนี้และหลังรีบูต" ;;
        apparmor) aa-status --enabled || because "AppArmor ไม่ทำงาน" ;;
        *)        because "ไม่มี SELinux หรือ AppArmor" ;;
    esac
}
no_denials() {   # ไม่มี AVC denied ในวันนี้ (Ubuntu ดู apparmor="DENIED" ใน journal)
    case $MAC in
        # --input-logs: ถ้าไม่ใส่ ausearch จะอ่าน stdin แทน log เมื่อรันจาก cron หรือ ssh ที่ไม่มี terminal แล้วผ่านทุกครั้ง
        selinux)  ! ausearch --input-logs -m avc -ts today 2>/dev/null | grep denied >/dev/null || because "มี AVC denied วันนี้ ดู ausearch -m avc -ts today" ;;
        apparmor) ! journalctl -k --since today 2>/dev/null | grep 'apparmor="DENIED"' >/dev/null || because "มี AppArmor DENIED วันนี้" ;;
        *)        return 1 ;;
    esac
}

# ---------- Firewall ----------
fw_on() {
    case $FW in
        firewalld) systemctl is-active --quiet firewalld || because "firewalld ไม่ทำงาน" ;;
        ufw)       ufw status | grep 'Status: active' >/dev/null || because "ufw ไม่ทำงาน" ;;
        *)         because "ไม่มี firewall" ;;
    esac
}
fw_minimal() {   # zone หลักเปิดเฉพาะ port ใน ALLOWED_TCP
    local p bad=""
    if [ "$FW" = firewalld ]; then
        for p in $(firewall-cmd --list-services); do
            case $p in ssh|http|https|dns|dhcpv6-client) ;; *) bad="$bad $p" ;; esac
        done
        for p in $(firewall-cmd --list-ports); do
            [[ " $ALLOWED_TCP " == *" ${p%/tcp} "* ]] || bad="$bad $p"
        done
    elif [ "$FW" = ufw ]; then
        for p in $(ufw status | awk '/ALLOW/ {print $1}' | cut -d/ -f1 | sort -u); do
            [[ " $ALLOWED_TCP " == *" $p "* ]] || bad="$bad $p"
        done
    else
        return 1
    fi
    [ -z "$bad" ] || because "เปิดเกินที่กำหนด:$bad"
}

# ---------- Network และ kernel ----------
ports_ok() {   # port TCP ที่ listen บนทุก IP ต้องอยู่ใน ALLOWED_TCP (127.0.0.1 และ ::1 ไม่นับ)
    local p bad=""
    for p in $(ss -Hltn | awk '$4 !~ /^(127\.|\[::1\])/ { sub(/.*:/, "", $4); print $4 }' | sort -un); do
        [[ " $ALLOWED_TCP " == *" $p "* ]] || bad="$bad $p"
    done
    [ -z "$bad" ] || because "port ที่ไม่อยู่ในรายการ:$bad"
}
sysctl_is() { [ "$(sysctl -n "$1")" = "$2" ] || because "$1 = $(sysctl -n "$1") ควรเป็น $2"; }
no_redirects() {   # ทุก interface ต้องไม่รับ ICMP redirect: เมื่อเครื่องไม่ได้ forward kernel ใช้ค่า all OR ค่าของ interface
    local f bad=""
    for f in /proc/sys/net/ipv4/conf/*/accept_redirects /proc/sys/net/ipv6/conf/*/accept_redirects; do
        [ "$(cat "$f")" = 0 ] || bad="$bad $(echo "$f" | cut -d/ -f5,7)"
    done
    [ -z "$bad" ] || because "accept_redirects ยังเป็น 1:$bad"
}

# ---------- ผู้ใช้ ----------
one_root()  { [ "$(awk -F: '$3 == 0' /etc/passwd | wc -l)" = 1 ] || because "มีผู้ใช้ UID 0 มากกว่าหนึ่งคน"; }
no_empty()  { ! awk -F: '$2 == ""' /etc/shadow | grep . >/dev/null || because "มีบัญชีที่ไม่มีรหัสผ่าน"; }
pw_len() {
    local v
    v=$(cat /etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf 2>/dev/null \
        | awk -F= '/^[[:space:]]*minlen/ { gsub(/ /, "", $2); v = $2 } END { print (v == "" ? 8 : v) }')   # ไม่ได้ตั้ง = ค่าเริ่มต้น 8
    [ "$v" -ge 12 ] || because "pwquality minlen = $v"
}
faillock() {   # pam_faillock ต้องอยู่ใน PAM และ deny อยู่ระหว่าง 1-5 (ไม่ได้ตั้ง = ค่าเริ่มต้น 3)
    local pam=/etc/pam.d/system-auth v
    [ -f $pam ] || pam=/etc/pam.d/common-auth
    grep -q '^[^#]*pam_faillock' "$pam" || { because "pam_faillock ยังไม่เปิดใน $pam"; return 1; }
    v=$(awk -F= '/^[[:space:]]*deny/ { gsub(/ /, "", $2); v = $2 } END { print (v == "" ? 3 : v) }' /etc/security/faillock.conf)
    [ "$v" -gt 0 ] && [ "$v" -le 5 ] || because "faillock deny = $v"
}

# ---------- ระบบ ----------
umask_ok() {
    local v
    v=$(awk '/^UMASK/ { print $2 }' /etc/login.defs)
    [ "$v" = 027 ] || [ "$v" = 077 ] || because "UMASK ใน login.defs = $v"
}
autoupd() {
    if have dnf; then
        systemctl is-enabled --quiet dnf-automatic.timer \
            && grep -q '^upgrade_type *= *security' /etc/dnf/automatic.conf \
            && grep -q '^apply_updates *= *yes' /etc/dnf/automatic.conf \
            || because "dnf-automatic.timer ยังไม่เปิด หรือไม่ได้ตั้ง security + apply_updates"
    else
        systemctl is-enabled --quiet unattended-upgrades \
            && grep -q 'Unattended-Upgrade "1"' /etc/apt/apt.conf.d/20auto-upgrades \
            || because "unattended-upgrades ยังไม่เปิด"
    fi
}
aide_db() { [ -s /var/lib/aide/aide.db.gz ] || [ -s /var/lib/aide/aide.db ] || because "ยังไม่มีฐานข้อมูล AIDE"; }   # Rocky ใช้ .gz, Ubuntu ไม่บีบอัด
remote_log() {
    grep -rqsE '^[^#]*(action\(.*type="omfwd"|@@?[[:alnum:]])' /etc/rsyslog.conf /etc/rsyslog.d/ \
        || because "rsyslog ยังไม่ส่ง log ไปเครื่องอื่น"
}

echo "== security-audit.sh  $(hostname)  $(date '+%F %T') =="
check "SSH: ปิด root login"                       ssh_root
check "SSH: ปิดการล็อกอินด้วยรหัสผ่าน"               ssh_pass
check "SSH: MaxAuthTries ไม่เกิน 4"                ssh_tries
check "SSH: AllowGroups $SSH_GROUP"               ssh_group
check "SSH: บังคับ 2FA (key + OTP)"                ssh_2fa
check "fail2ban: ทำงานอยู่"                         f2b_up
check "fail2ban: jail sshd"                        f2b_jail sshd
check "fail2ban: jail recidive"                    f2b_jail recidive
check "TLS: https://$SITE ตอบ 200"                 https_ok
check "TLS: HTTP redirect ไป HTTPS"                 redirect
check "TLS: ใบรับรองเหลืออายุเกิน $CERT_DAYS วัน"      cert_days
check "TLS: ไม่รับ TLS 1.0 และ 1.1"                  no_old_tls
check "TLS: มี HSTS header"                        hsts
check "TLS: crypto-policies ไม่ใช่ LEGACY"           cryptopol
check "MAC: $MAC enforcing ทั้งตอนนี้และหลังรีบูต"      mac_on
check "MAC: ไม่มี denied วันนี้"                      no_denials
check "Firewall: $FW ทำงานอยู่"                     fw_on
check "Firewall: เปิดเฉพาะ port ที่กำหนด"              fw_minimal
check "Network: listen เฉพาะ port ที่กำหนด"           ports_ok
check "Kernel: ปิด ip_forward"                      sysctl_is net.ipv4.ip_forward 0
check "Kernel: ไม่รับ ICMP redirect"                 no_redirects
check "Kernel: เปิด TCP SYN cookies"                sysctl_is net.ipv4.tcp_syncookies 1
check "ผู้ใช้: UID 0 มีเพียง root"                     one_root
check "ผู้ใช้: ไม่มีบัญชีรหัสผ่านว่าง"                    no_empty
check "ผู้ใช้: รหัสผ่านยาวอย่างน้อย 12 ตัว"               pw_len
check "ผู้ใช้: ล็อกบัญชีเมื่อใส่รหัสผิดซ้ำ (faillock)"       faillock
check "ระบบ: UMASK 027"                           umask_ok
check "ระบบ: อัปเดตความปลอดภัยอัตโนมัติ"               autoupd
check "ระบบ: มีฐานข้อมูล AIDE"                       aide_db
check "ระบบ: ส่ง log ไปเครื่องอื่น"                     remote_log

pct=$((pass * 100 / n))
echo "== ผ่าน $pass/$n ($pct%) =="
[ "$pct" -ge 90 ]
