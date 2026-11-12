#!/bin/bash
# check-dns.sh: ตรวจรับโปรเจกต์จบเล่ม Complete DNS Infrastructure
#   sudo ./check-dns.sh primary      รันบน ns1
#   sudo ./check-dns.sh secondary    รันบน ns2
#   ./check-dns.sh client            รันบนเครื่องลูกข่ายใน LAN เช่น pc1
set -uo pipefail

NS1=192.168.56.50
NS2=192.168.56.51
LAN_GW=10.8.0.1
DOMAIN=example.com
DHCP_DOMAIN=lan.example.com
WWW_INTERNAL=192.168.56.20
XFER_KEY=/etc/named.xfer.key

pass=0; fail=0
check() {   # check "คำอธิบาย" คำสั่ง...
    local desc=$1; shift
    if "$@" >/dev/null 2>&1; then
        printf 'PASS  %s\n' "$desc"; pass=$((pass + 1))
    else
        printf 'FAIL  %s\n' "$desc"; fail=$((fail + 1))
    fi
}
ans()    { dig +short +time=3 +tries=1 "$@" | tail -1; }          # คำตอบบรรทัดสุดท้าย
status() { dig +time=5 +tries=2 "$@" | grep -oE 'status: [A-Z]+' | cut -d' ' -f2; }
is()     { [ "$1" = "$2" ]; }
secret() { awk -v k="$1" '$0 ~ "key \""k"\"" {f=1} f && /secret/ {gsub(/[";]/, "", $2); print $2; exit}' "$XFER_KEY"; }
signed() { local k=$1; shift; dig +short +time=3 +tries=1 -y "hmac-sha256:$k:$(secret "$k")" "$@" | tail -1; }
serial() { awk '{print $3}'; }

ptr_complete() {   # ทุก A ในวง 192.168.56 ของ zone internal ต้องมี PTR ที่ชี้กลับมาชื่อเดิม
    local name ip back n=0
    while read -r name ip; do
        back=$(dig +short -x "$ip" @"$NS1")
        [ "$back" = "$name" ] || return 1
        n=$((n + 1))
    done < <(dig +noall +answer -y "hmac-sha256:internal-xfer:$(secret internal-xfer)" @"$NS1" "$DOMAIN" AXFR |
             awk '$4 == "A" && $5 ~ /^192\.168\.56\./ {print $1, $5}')
    [ "$n" -gt 0 ]
}

key_perm_ok() {   # ไฟล์กุญแจทุกไฟล์ต้องเป็น 640 และกลุ่ม named
    local f
    for f in /etc/named.xfer.key /etc/named.ddns.key; do
        [ "$(stat -c '%a %G' "$f")" = "640 named" ] || return 1
    done
}

same_serial() {   # same_serial กุญแจ zone: serial ของ ns1 และ ns2 ต้องเท่ากันและไม่ว่าง
    local a b
    a=$(signed "$1" @"$NS1" "$2" SOA | serial)
    b=$(signed "$1" @"$NS2" "$2" SOA | serial)
    [ -n "$a" ] && [ "$a" = "$b" ]
}

synced_to() {   # chronyc sources ต้องมี * หน้าแหล่งเวลาที่กำหนด
    chronyc -n sources | grep -qE "^\^\* +$1 "
}

case "${1:-}" in
primary)
    for s in named unbound kea-dhcp4 kea-dhcp-ddns chronyd; do
        check "$s เปิดเองตอนบูตและ active" bash -c "systemctl is-enabled --quiet $s && systemctl is-active --quiet $s"
    done
    check "named-checkconf -z ผ่านทุก zone" named-checkconf -z
    check "BIND ปิด recursion (ชื่อนอกโดเมนได้ REFUSED)" is "$(status @$NS1 www.rockylinux.org)" REFUSED
    check "view internal: www ได้ $WWW_INTERNAL" is "$(ans @$NS1 www.$DOMAIN)" "$WWW_INTERNAL"
    ext_www=$(signed external-xfer @$NS1 www.$DOMAIN)
    check "view external: www ได้ IP ในวง 203.0.113 ($ext_www)" test "${ext_www%.*}" = 203.0.113
    check "view external: ไม่มีชื่อ db1" is "$(status -y hmac-sha256:external-xfer:$(secret external-xfer) @$NS1 db1.$DOMAIN)" NXDOMAIN
    check "AXFR ที่ไม่มีกุญแจถูกปฏิเสธ" bash -c "dig @$NS1 $DOMAIN AXFR | grep -q 'Transfer failed'"
    check "ทุก A ในวง 192.168.56 มี PTR ตรงกัน" ptr_complete
    check "ไฟล์กุญแจสิทธิ์ 640 กลุ่ม named" key_perm_ok
    check "Unbound ตอบชื่อบน Internet พร้อม flag ad" bash -c "dig @127.0.0.1 www.isc.org | grep -q 'flags:.* ad'"
    check "Unbound ปฏิเสธลายเซ็นที่ผิด (dnssec-failed.org)" is "$(status @127.0.0.1 dnssec-failed.org)" SERVFAIL
    check "Unbound ตอบ db1.$DOMAIN" is "$(ans @127.0.0.1 db1.$DOMAIN)" 192.168.56.40
    check "Unbound ตอบ PTR ของ $LAN_GW" is "$(ans @127.0.0.1 -x $LAN_GW)" "ns1.$DOMAIN."
    check "Kea รอรับที่ $LAN_GW:67" bash -c "ss -ulnp | grep -q '$LAN_GW:67 '"
    check "firewall เปิด dns dhcp ntp" bash -c "s=\$(firewall-cmd --list-services); for x in dns dhcp ntp; do echo \" \$s \" | grep -q \" \$x \" || exit 1; done"
    check "ns1 ซิงก์เวลาแล้ว (Leap status Normal)" bash -c "chronyc tracking | grep -q 'Leap status *: Normal'"
    check "chrony ตอบเครื่องอื่นได้ (มี client อย่างน้อยหนึ่งเครื่อง)" bash -c "[ \$(chronyc -n clients | tail -n +3 | wc -l) -ge 1 ]"
    ;;
secondary)
    check "named เปิดเองตอนบูตและ active" bash -c "systemctl is-enabled --quiet named && systemctl is-active --quiet named"
    for z in example.com.internal example.com.external 192.168.56.rev lan.example.com.internal 10.8.0.rev; do
        check "มี zone ที่คัดลอกมา slaves/$z" test -s /var/named/slaves/$z
    done
    check "serial ของ $DOMAIN view internal ตรงกับ ns1" same_serial internal-xfer "$DOMAIN"
    check "serial ของ $DOMAIN view external ตรงกับ ns1" same_serial external-xfer "$DOMAIN"
    check "serial ของ $DHCP_DOMAIN ตรงกับ ns1" same_serial internal-xfer "$DHCP_DOMAIN"
    check "ns2 ตอบ db1.$DOMAIN จาก view internal" is "$(ans @127.0.0.1 db1.$DOMAIN)" 192.168.56.40
    check "ns2 ใช้ ns1 เป็นแหล่งเวลา" synced_to "$NS1"
    ;;
client)
    me=$(ip -4 -o addr show | awk -v gw="${LAN_GW%.*}." '$4 ~ "^"gw {split($4, a, "/"); print a[1]; exit}')
    check "มี IP ในวง ${LAN_GW%.*}.0/24" test -n "$me"
    check "ได้ IP จาก DHCP" bash -c "ip -4 route | grep -q 'proto dhcp src $me'"
    check "DNS server คือ $LAN_GW" grep -q "^nameserver $LAN_GW" /etc/resolv.conf
    check "search domain มี $DHCP_DOMAIN และ $DOMAIN" bash -c "grep '^search' /etc/resolv.conf | grep -qw $DHCP_DOMAIN && grep '^search' /etc/resolv.conf | grep -qw $DOMAIN"
    check "www.$DOMAIN ได้ $WWW_INTERNAL (view internal)" is "$(ans www.$DOMAIN)" "$WWW_INTERNAL"
    check "ชื่อบน Internet resolve ได้" is "$(status www.isc.org)" NOERROR
    check "ชื่อของเครื่องนี้ถูกบันทึกใน DNS ($(hostname -s).$DHCP_DOMAIN)" is "$(ans $(hostname -s).$DHCP_DOMAIN)" "$me"
    check "PTR ของ $me ชี้กลับมาที่ชื่อเครื่องนี้" is "$(ans -x $me)" "$(hostname -s).$DHCP_DOMAIN."
    check "ซิงก์เวลากับ $LAN_GW" synced_to "$LAN_GW"
    check "เวลาเหลื่อมจาก NTP ไม่เกิน 0.1 วินาที" bash -c "chronyc tracking | awk '/System time/ {exit (\$4 < 0.1) ? 0 : 1}'"
    ;;
*)
    echo "usage: $0 primary|secondary|client" >&2; exit 2 ;;
esac

echo "----"
echo "ผ่าน $pass จาก $((pass + fail)) ข้อ"
[ "$fail" -eq 0 ]
