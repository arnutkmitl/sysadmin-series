#!/bin/bash
# check-vpn.sh: ตรวจรับโปรเจกต์จบเล่ม Enterprise VPN
#   sudo ./check-vpn.sh server     รันบน vpn1 สำนักงานใหญ่
#   sudo ./check-vpn.sh branch     รันบน vpn2 สาขา
#   sudo ./check-vpn.sh client     รันบน laptop ขณะเชื่อม WireGuard อยู่
set -uo pipefail

VPN1=192.168.56.90
APP1=172.16.1.10
BRANCH_LAN=172.16.2.1
USERS=20

pass=0; fail=0
check() {   # check "คำอธิบาย" คำสั่ง...
    local desc=$1; shift
    if "$@" >/dev/null 2>&1; then
        printf 'PASS  %s\n' "$desc"; pass=$((pass + 1))
    else
        printf 'FAIL  %s\n' "$desc"; fail=$((fail + 1))
    fi
}
is()      { [ "$1" = "$2" ]; }
up()      { systemctl is-enabled --quiet "$1" && systemctl is-active --quiet "$1"; }
fresh()   {   # fresh wg1: handshake ล่าสุดของทุก peer ต้องไม่เกิน 180 วินาที
    local ts now n=0
    now=$(date +%s)
    for ts in $(wg show "$1" latest-handshakes | awk '{print $2}'); do
        [ $((now - ts)) -le 180 ] || return 1
        n=$((n + 1))
    done
    [ "$n" -gt 0 ]
}
all_psk() {   # ทุก peer ของ wg0 ต้องมี PresharedKey
    ! wg show wg0 preshared-keys | grep -q '(none)'
}
in_zone() {   # in_zone zone interface...
    local z=$1 i list; shift
    list=" $(firewall-cmd --zone="$z" --list-interfaces) "
    for i in "$@"; do [[ $list == *" $i "* ]] || return 1; done
}
has_ports() {
    local p list
    list=" $(firewall-cmd --list-ports) "
    for p in "$@"; do [[ $list == *" $p "* ]] || return 1; done
}
crl_ok() {   # crl.pem ต้องอ่านได้ทุกคน และยังเหลืออายุเกิน 30 วัน
    local f=/etc/openvpn/server/crl.pem next
    [ "$(stat -c %a "$f")" = 644 ] || return 1
    next=$(openssl crl -in "$f" -noout -nextupdate | cut -d= -f2)
    [ $(( $(date -d "$next" +%s) - $(date +%s) )) -gt $((30 * 86400)) ]
}
files_ok() {   # files_ok pattern: มีอย่างน้อย USERS ไฟล์ และทุกไฟล์สิทธิ์ 600
    local f n=0
    for f in $1; do
        [ "$(stat -c %a "$f")" = 600 ] || return 1
        n=$((n + 1))
    done
    [ "$n" -ge "$USERS" ]
}
tcp_open() { timeout 3 bash -c "</dev/tcp/$1/$2"; }

case "${1:-}" in
server)
    for s in wg-quick@wg0 wg-quick@wg1 openvpn-server@server openvpn-server@tcp443 vnstat openvpn-crl.timer; do
        check "$s เปิดเองตอนบูตและ active" up "$s"
    done
    check "ip_forward เปิดอยู่" is "$(sysctl -n net.ipv4.ip_forward)" 1
    check "firewall เปิด 51820/udp 51821/udp 1194/udp 443/tcp" has_ports 51820/udp 51821/udp 1194/udp 443/tcp
    check "wg0 tun0 tun1 อยู่ใน zone vpn" in_zone vpn wg0 tun0 tun1
    check "wg1 และ enp0s9 อยู่ใน zone internal" in_zone internal wg1 enp0s9
    check "policy vpn-to-lan มี target REJECT" bash -c "firewall-cmd --info-policy=vpn-to-lan | grep -q 'target: REJECT'"
    check "ทุก peer ของ wg0 มี PresharedKey" all_psk
    check "wg0 มี peer อย่างน้อย $USERS คน" test "$(wg show wg0 peers | wc -l)" -ge "$USERS"
    check "site-to-site wg1 มี handshake ภายใน 3 นาที" fresh wg1
    check "OpenVPN ใช้ tls-crypt ทั้ง UDP และ TCP" bash -c "grep -q '^tls-crypt' /etc/openvpn/server/server.conf && grep -q '^tls-crypt' /etc/openvpn/server/tcp443.conf"
    check "crl.pem สิทธิ์ 644 และอายุเหลือเกิน 30 วัน" crl_ok
    check "ไฟล์ .ovpn ครบ $USERS คน สิทธิ์ 600" files_ok "/etc/openvpn/clients/*.ovpn"
    check "ไฟล์ WireGuard ของผู้ใช้ครบ $USERS คน สิทธิ์ 600" files_ok "/etc/wireguard/clients/*.conf"
    ;;
branch)
    check "wg-quick@wg1 เปิดเองตอนบูตและ active" up wg-quick@wg1
    check "wg1 มี handshake ภายใน 3 นาที" fresh wg1
    check "ip_forward เปิดอยู่" is "$(sysctl -n net.ipv4.ip_forward)" 1
    check "วง LAN สาขา ($BRANCH_LAN) ping $APP1 ได้" ping -c2 -W2 -I "$BRANCH_LAN" "$APP1"
    check "วง LAN สาขาเปิด intranet ได้" curl -s -m 5 --interface "$BRANCH_LAN" "http://$APP1:8080/"
    ;;
client)
    check "wg0 มี handshake ภายใน 3 นาที" fresh wg0
    check "ใช้ PresharedKey" bash -c "! wg show wg0 preshared-keys | grep -q '(none)'"
    check "route ไป $APP1 ผ่าน wg0" bash -c "ip route get $APP1 | grep -q 'dev wg0'"
    check "ping $APP1 ได้" ping -c2 -W2 "$APP1"
    check "เปิด intranet http://$APP1:8080/ ได้" curl -s -m 5 "http://$APP1:8080/"
    check "SSH ไป $APP1 ถูกปิดกั้น" bash -c "! timeout 5 bash -c '</dev/tcp/$APP1/2222'"
    check "OpenVPN สำรองที่ $VPN1 TCP 443 รอรับอยู่" tcp_open "$VPN1" 443
    ;;
*)
    echo "usage: $0 server|branch|client" >&2; exit 2 ;;
esac

echo "----"
echo "ผ่าน $pass ไม่ผ่าน $fail"
[ "$fail" -eq 0 ]
