#!/usr/bin/env bash
# Production: ความปลอดภัย การเฝ้าดู และการแก้ปัญหา
# SysAdmin Pocket Series M09 VPN Server: WireGuard & OpenVPN
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── PresharedKey ของ WireGuard ──────────────────────────────
sudo sh -c "umask 077; wg genpsk > /etc/wireguard/clients/laptop.psk"
sudo sed -i "\#^PublicKey = o/0GD+SbVymq6NAQcfvUgmjI5DvyorGAXu7VpAIugEQ=#a PresharedKey = $(sudo cat /etc/wireguard/clients/laptop.psk)" /etc/wireguard/wg0.conf
sudo bash -c "wg syncconf wg0 <(wg-quick strip wg0)"
sudo wg show wg0 | grep -E "^peer|preshared"
# บนเครื่อง laptop
sudo wg-quick down wg0
# บนเครื่อง laptop
sudo wg-quick up wg0
# บนเครื่อง laptop
ping -c2 -W2 172.16.1.10 | tail -2
sudo install -o admin -g admin -m 600 /etc/wireguard/clients/laptop.psk /home/admin/laptop.psk
# บนเครื่อง laptop
scp -P 2222 admin@192.168.56.90:laptop.psk ~/
rm /home/admin/laptop.psk
# บนเครื่อง laptop
sudo sed -i "\#^PublicKey = rSHCqecIz/ovo7jAAh+f7kaDBOmwJbcJPbyUxnlE/W0=#a PresharedKey = $(cat ~/laptop.psk)" /etc/wireguard/wg0.conf
# บนเครื่อง laptop
rm ~/laptop.psk
# บนเครื่อง laptop
sudo wg-quick down wg0
# บนเครื่อง laptop
sudo wg-quick up wg0
# บนเครื่อง laptop
ping -c2 -W2 172.16.1.10 | tail -2
# บนเครื่อง laptop
sudo wg show wg0 | grep -E "preshared|handshake"

# ── OpenVPN: tls-crypt และ cipher ───────────────────────────
sudo journalctl -u openvpn-server@server -o cat | grep "Data Channel: cipher" | tail -1

# ── จำกัดสิทธิ์ผู้ใช้ VPN ด้วย firewalld ────────────────────
sudo firewall-cmd --permanent --new-zone=vpn
for i in wg0 tun0 tun1; do sudo firewall-cmd --permanent --zone=internal --remove-interface=$i; sudo firewall-cmd --permanent --zone=vpn --add-interface=$i; done
sudo firewall-cmd --permanent --new-policy=vpn-to-lan
sudo firewall-cmd --permanent --policy=vpn-to-lan --add-ingress-zone=vpn
sudo firewall-cmd --permanent --policy=vpn-to-lan --add-egress-zone=internal
sudo firewall-cmd --permanent --policy=vpn-to-lan --set-target=REJECT
sudo firewall-cmd --permanent --policy=vpn-to-lan --add-port=8080/tcp
sudo firewall-cmd --permanent --policy=vpn-to-lan --add-protocol=icmp
sudo firewall-cmd --reload
sudo firewall-cmd --get-active-zones
# บนเครื่อง laptop
curl -s http://172.16.1.10:8080/
# บนเครื่อง laptop
ping -c1 -W2 172.16.1.10 | tail -2
# บนเครื่อง laptop
ssh -p 2222 -o ConnectTimeout=5 admin@172.16.1.10
# บนเครื่อง vpn2
ssh -p 2222 -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=accept-new admin@172.16.1.10 true; echo $?

# ── WireGuard ───────────────────────────────────────────────
sudo wg show wg0 latest-handshakes
sudo wg show wg0 transfer
sudo wg show wg0 latest-handshakes | while read key ts; do age=$(( $(date +%s) - ts )); [ $age -gt 180 ] && echo "$(sudo grep -B2 "$key" /etc/wireguard/wg0.conf | head -1) offline"; done

# ── OpenVPN ─────────────────────────────────────────────────
# บนเครื่อง laptop
sudo wg-quick down wg0
# บนเครื่อง laptop
sudo systemctl start openvpn-client@somchai
sleep 30
sudo awk -F, '/^CLIENT_LIST/ {print $2, $4, $8}' /run/openvpn-server/status-server.log
# บนเครื่อง laptop
sudo systemctl stop openvpn-client@somchai
# บนเครื่อง laptop
sudo wg-quick up wg0

# ── vnStat ──────────────────────────────────────────────────
sudo dnf install -y vnstat
sudo systemctl enable --now vnstat
vnstat -tr 5 -i wg0
vnstat -i wg0 -m

# ── ต่ออายุ CRL อัตโนมัติ ───────────────────────────────────
sudo tee /etc/systemd/system/openvpn-crl.service > /dev/null <<EOF
[Unit]
Description=Renew OpenVPN CRL

[Service]
Type=oneshot
ExecStart=/bin/sh /etc/openvpn/easy-rsa/easyrsa --pki=/etc/openvpn/easy-rsa/pki --batch gen-crl
ExecStart=/usr/bin/install -m 644 /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn/server/crl.pem
EOF
sudo tee /etc/systemd/system/openvpn-crl.timer > /dev/null <<EOF
[Unit]
Description=Renew OpenVPN CRL monthly

[Timer]
OnCalendar=monthly
Persistent=true

[Install]
WantedBy=timers.target
EOF
sudo systemctl daemon-reload
sudo systemctl start openvpn-crl.service
sudo openssl crl -in /etc/openvpn/server/crl.pem -noout -lastupdate
sudo systemctl enable --now openvpn-crl.timer
systemctl list-timers openvpn-crl.timer

# ── เชื่อมไม่ได้: เปิด log ของ WireGuard ────────────────────
echo "module wireguard +p" | sudo tee /sys/kernel/debug/dynamic_debug/control
sudo dmesg | grep wireguard | tail -3
echo "module wireguard -p" | sudo tee /sys/kernel/debug/dynamic_debug/control
sudo timeout 10 tcpdump -ni enp0s8 udp port 51820 -c 2

# ── เชื่อมได้แต่เข้าวง LAN ไม่ได้ ───────────────────────────
sysctl net.ipv4.ip_forward
sudo firewall-cmd --get-zone-of-interface=wg0
ip route get 10.9.0.2 from 172.16.1.10 iif enp0s9

# ── DNS: ชื่อเครื่องไม่ทำงานหรือรั่วออกนอกอุโมงค์ ───────────
echo 'push "dhcp-option DNS 172.16.1.1"' | sudo tee -a /etc/openvpn/server/server.conf
sudo systemctl restart openvpn-server@server
# บนเครื่อง laptop
sudo wg-quick down wg0
# บนเครื่อง laptop
sudo systemctl start openvpn-client@somchai
# บนเครื่อง laptop
sudo journalctl -u openvpn-client@somchai -o cat | grep -E "dhcp-option|dns up"
# บนเครื่อง laptop
sudo systemctl stop openvpn-client@somchai
# บนเครื่อง laptop
sudo dnf install -y NetworkManager-openvpn
# บนเครื่อง laptop
sudo nmcli con import type openvpn file ~/somchai.ovpn
# บนเครื่อง laptop
sudo nmcli con up somchai
# บนเครื่อง laptop
grep nameserver /etc/resolv.conf
# บนเครื่อง laptop
sudo nmcli con down somchai
# บนเครื่อง laptop
sudo wg-quick up wg0
