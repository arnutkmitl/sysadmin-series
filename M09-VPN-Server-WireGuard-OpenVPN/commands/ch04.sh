#!/usr/bin/env bash
# โปรเจกต์จบเล่ม: Enterprise VPN
# SysAdmin Pocket Series M09 VPN Server: WireGuard & OpenVPN
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── ขั้นที่ 1 OpenVPN สำรองที่ TCP 443 ──────────────────────
sudo sed -e "s/^port 1194/port 443/" -e "s/^proto udp/proto tcp/" -e "s/^dev tun0/dev tun1/" -e "s/^server 10.10.0.0 /server 10.10.1.0 /" -e "s/status-server.log/status-tcp443.log/" -e "s#^\# /etc/openvpn/server/server.conf#\# /etc/openvpn/server/tcp443.conf#" /etc/openvpn/server/server.conf | sudo tee /etc/openvpn/server/tcp443.conf > /dev/null
sudo grep -E "^(port|proto|dev|server|status)" /etc/openvpn/server/tcp443.conf
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --reload
sudo systemctl enable --now openvpn-server@tcp443
ip -br a show tun1
# บนเครื่อง laptop
sudo wg-quick down wg0
sudo firewall-cmd --remove-port=1194/udp
# บนเครื่อง laptop
sudo systemctl start openvpn-client@somchai
# บนเครื่อง laptop
sudo journalctl -u openvpn-client@somchai -o cat --since=-1min | grep -E "link remote|poll timeout|Initialization"
# บนเครื่อง laptop
ip -br a show tun0
# บนเครื่อง laptop
curl -s http://172.16.1.10:8080/
# บนเครื่อง laptop
sudo systemctl stop openvpn-client@somchai
sudo firewall-cmd --reload
# บนเครื่อง laptop
sudo wg-quick up wg0

# ── ขั้นที่ 2 ไฟล์ของพนักงาน 20 คน ──────────────────────────
chmod 755 add-users.sh
sudo ./add-users.sh users.txt | tail -3
sudo wg show wg0 peers | wc -l
sudo ./add-users.sh users.txt | wc -l
sudo wg show wg0 peers | wc -l

# ── ขั้นที่ 3 PresharedKey ของโทรศัพท์ ──────────────────────
sudo sh -c "umask 077; wg genpsk > /etc/wireguard/clients/phone.psk"
sudo sed -i "\#^PublicKey = $(sudo cat /etc/wireguard/clients/phone.pub)#a PresharedKey = $(sudo cat /etc/wireguard/clients/phone.psk)" /etc/wireguard/wg0.conf
sudo sed -i "/^\[Peer\]/a PresharedKey = $(sudo cat /etc/wireguard/clients/phone.psk)" /etc/wireguard/clients/phone.conf
sudo bash -c "wg syncconf wg0 <(wg-quick strip wg0)"
sudo wg show wg0 preshared-keys | grep -c "(none)"
sudo qrencode -t png -o /etc/wireguard/clients/phone.png -r /etc/wireguard/clients/phone.conf

# ── ขั้นที่ 4 ตรวจรับด้วย check-vpn.sh ──────────────────────
sudo ./check-vpn.sh server
# บนเครื่อง vpn2
sudo ./check-vpn.sh branch
# บนเครื่อง laptop
sudo ./check-vpn.sh client

# ── ขั้นที่ 5 ซ้อมให้ script จับความผิดปกติ ─────────────────
sudo chmod 600 /etc/openvpn/server/crl.pem
sudo firewall-cmd --zone=internal --change-interface=wg0
sudo ./check-vpn.sh server | grep -E "FAIL|----" -A1
# บนเครื่อง laptop
sudo ./check-vpn.sh client | grep -E "^FAIL|^ผ่าน"
sudo firewall-cmd --reload
sudo install -m 644 /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn/server/crl.pem
sudo ./check-vpn.sh server | tail -1
# บนเครื่อง laptop
sudo ./check-vpn.sh client | tail -1
