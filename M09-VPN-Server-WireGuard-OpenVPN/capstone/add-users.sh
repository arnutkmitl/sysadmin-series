#!/bin/bash
# add-users.sh: สร้างบัญชี VPN ทั้ง WireGuard และ OpenVPN ให้ผู้ใช้หลายคนจากไฟล์รายชื่อ
#   sudo ./add-users.sh users.txt      รันบน vpn1
# ไฟล์รายชื่อ บรรทัดละคน "ชื่อ เลขท้าย IP" เช่น "anan 11" ได้ IP 10.9.0.11 ใน WireGuard
# รันซ้ำได้ ผู้ใช้ที่มีอยู่แล้วจะไม่ถูกสร้างใหม่
set -euo pipefail
list=${1:?usage: add-users.sh users.txt}
easyrsa="/etc/openvpn/easy-rsa/easyrsa --pki=/etc/openvpn/easy-rsa/pki --batch"
wgconf=/etc/wireguard/wg0.conf
wgdir=/etc/wireguard/clients
endpoint=192.168.56.90:51820
routes="10.9.0.0/24, 172.16.1.0/24"
server_pub=$(cat /etc/wireguard/public.key)
umask 077
mkdir -p "$wgdir"

while read -r name n; do
    [ -z "$name" ] || [ "${name:0:1}" = "#" ] && continue

    # OpenVPN: certificate และไฟล์ .ovpn
    [ -f "/etc/openvpn/easy-rsa/pki/issued/$name.crt" ] || $easyrsa build-client-full "$name" nopass >/dev/null 2>&1
    /usr/local/bin/make-ovpn "$name" >/dev/null

    # WireGuard: กุญแจ ไฟล์ของผู้ใช้ QR code และ peer ใน wg0.conf
    if ! grep -qx "# $name" "$wgconf"; then
        if grep -q "^AllowedIPs = 10.9.0.$n/32" "$wgconf"; then
            echo "ข้าม $name: 10.9.0.$n มีผู้ใช้แล้ว" >&2; continue
        fi
        wg genkey | tee "$wgdir/$name.key" | wg pubkey > "$wgdir/$name.pub"
        wg genpsk > "$wgdir/$name.psk"
        cat > "$wgdir/$name.conf" <<CONF
[Interface]
Address = 10.9.0.$n/32
PrivateKey = $(cat "$wgdir/$name.key")

[Peer]
PublicKey = $server_pub
PresharedKey = $(cat "$wgdir/$name.psk")
Endpoint = $endpoint
AllowedIPs = $routes
PersistentKeepalive = 25
CONF
        qrencode -t png -o "$wgdir/$name.png" -r "$wgdir/$name.conf"
        printf '\n# %s\n[Peer]\nPublicKey = %s\nPresharedKey = %s\nAllowedIPs = 10.9.0.%s/32\n' \
            "$name" "$(cat "$wgdir/$name.pub")" "$(cat "$wgdir/$name.psk")" "$n" >> "$wgconf"
    fi
    echo "$name 10.9.0.$n $wgdir/$name.conf /etc/openvpn/clients/$name.ovpn"
done < "$list"

wg syncconf wg0 <(wg-quick strip wg0)
