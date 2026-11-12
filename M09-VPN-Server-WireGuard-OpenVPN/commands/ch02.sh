#!/usr/bin/env bash
# OpenVPN: PKI, Server และไฟล์ .ovpn
# SysAdmin Pocket Series M09 VPN Server: WireGuard & OpenVPN
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 2.1 ติดตั้งและสร้าง PKI ─────────────────────────────────
sudo dnf install -y openvpn easy-rsa
openvpn --version | head -1
# บนเครื่อง laptop
sudo dnf install -y epel-release
# บนเครื่อง laptop
sudo dnf install -y openvpn
sudo mkdir -m 700 /etc/openvpn/easy-rsa
sudo cp -r /usr/share/easy-rsa/3/* /etc/openvpn/easy-rsa/
sudo /etc/openvpn/easy-rsa/easyrsa --pki=/etc/openvpn/easy-rsa/pki --batch init-pki
sudo /etc/openvpn/easy-rsa/easyrsa --pki=/etc/openvpn/easy-rsa/pki --batch --req-cn="Example Office VPN CA" build-ca nopass
sudo /etc/openvpn/easy-rsa/easyrsa --pki=/etc/openvpn/easy-rsa/pki --batch --req-cn=vpn1.example.com gen-req vpn1 nopass
sudo /etc/openvpn/easy-rsa/easyrsa --pki=/etc/openvpn/easy-rsa/pki --batch sign-req server vpn1
sudo openssl x509 -in /etc/openvpn/easy-rsa/pki/issued/vpn1.crt -noout -subject -enddate -ext extendedKeyUsage
sudo /etc/openvpn/easy-rsa/easyrsa --pki=/etc/openvpn/easy-rsa/pki --batch build-client-full somchai nopass
sudo /etc/openvpn/easy-rsa/easyrsa --pki=/etc/openvpn/easy-rsa/pki --batch build-client-full suda nopass
sudo /etc/openvpn/easy-rsa/easyrsa --pki=/etc/openvpn/easy-rsa/pki --batch gen-crl
sudo openssl crl -in /etc/openvpn/easy-rsa/pki/crl.pem -noout -nextupdate
sudo ls /etc/openvpn/easy-rsa/pki/inline/private/

# ── 2.2 ตั้ง OpenVPN Server ─────────────────────────────────
sudo install -m 600 /etc/openvpn/easy-rsa/pki/ca.crt /etc/openvpn/easy-rsa/pki/issued/vpn1.crt /etc/openvpn/easy-rsa/pki/private/vpn1.key /etc/openvpn/server/
sudo install -m 644 /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn/server/
sudo openvpn --genkey tls-crypt /etc/openvpn/server/tc.key
sudo tee /etc/openvpn/server/server.conf > /dev/null <<EOF
# /etc/openvpn/server/server.conf
port 1194
proto udp
dev tun0
ca ca.crt
cert vpn1.crt
key vpn1.key
dh none
tls-crypt tc.key
crl-verify crl.pem
server 10.10.0.0 255.255.255.0
topology subnet
push "route 172.16.1.0 255.255.255.0"
keepalive 10 60
data-ciphers AES-256-GCM:CHACHA20-POLY1305
user openvpn
group openvpn
persist-tun
status /run/openvpn-server/status-server.log 30
verb 3
EOF
sudo firewall-cmd --permanent --add-port=1194/udp
sudo firewall-cmd --permanent --zone=internal --add-interface=tun0
sudo firewall-cmd --reload
sudo systemctl enable --now openvpn-server@server
sudo journalctl -u openvpn-server@server -o cat | grep -E "^DCO|Initialization"
ip -br a show tun0

# ── 2.3 ไฟล์ .ovpn และการเชื่อม Client ──────────────────────
sudo install -m 755 make-ovpn /usr/local/bin/make-ovpn
sudo make-ovpn somchai
sudo grep secure_path /etc/sudoers
sudo /usr/local/bin/make-ovpn somchai

# ── Linux ───────────────────────────────────────────────────
sudo install -o admin -g admin -m 600 /etc/openvpn/clients/somchai.ovpn /home/admin/somchai.ovpn
# บนเครื่อง laptop
scp -P 2222 admin@192.168.56.90:somchai.ovpn ~/
rm /home/admin/somchai.ovpn
# บนเครื่อง laptop
sudo wg-quick down wg0
# บนเครื่อง laptop
sudo install -m 600 ~/somchai.ovpn /etc/openvpn/client/somchai.conf
# บนเครื่อง laptop
sudo systemctl start openvpn-client@somchai
# บนเครื่อง laptop
sudo journalctl -u openvpn-client@somchai -o cat | grep -E "link remote|Initialization"
# บนเครื่อง laptop
ip -br a show tun0
# บนเครื่อง laptop
curl -s http://172.16.1.10:8080/
sudo journalctl -u openvpn-server@server -o cat | grep somchai | grep -E "Peer Connection|pool returned|Data Channel"
sudo grep CLIENT_LIST /run/openvpn-server/status-server.log

# ── ถอนสิทธิ์เมื่อพนักงานลาออก ──────────────────────────────
sudo /usr/local/bin/make-ovpn suda
sudo install -o admin -g admin -m 600 /etc/openvpn/clients/suda.ovpn /home/admin/suda.ovpn
# บนเครื่อง laptop
scp -P 2222 admin@192.168.56.90:suda.ovpn ~/
rm /home/admin/suda.ovpn
# บนเครื่อง laptop
sudo install -m 600 ~/suda.ovpn /etc/openvpn/client/suda.conf
# บนเครื่อง laptop
sudo systemctl start openvpn-client@suda
# บนเครื่อง laptop
ip -br a show tun1
# บนเครื่อง laptop
sudo systemctl stop openvpn-client@suda
sudo /etc/openvpn/easy-rsa/easyrsa --pki=/etc/openvpn/easy-rsa/pki --batch revoke-issued suda
sudo /etc/openvpn/easy-rsa/easyrsa --pki=/etc/openvpn/easy-rsa/pki --batch gen-crl
sudo install -m 644 /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn/server/crl.pem
# บนเครื่อง laptop
sudo systemctl start openvpn-client@suda
# บนเครื่อง laptop
ip -br a show tun1
# บนเครื่อง laptop
sudo systemctl stop openvpn-client@suda
sudo journalctl -u openvpn-server@server -o cat | grep -E "CRL: loaded|error=certificate revoked" | tail -2

# ── ต่ออายุ ─────────────────────────────────────────────────
sudo openssl x509 -in /etc/openvpn/easy-rsa/pki/issued/somchai.crt -noout -serial
sudo /etc/openvpn/easy-rsa/easyrsa --pki=/etc/openvpn/easy-rsa/pki --batch renew somchai
sudo openssl x509 -in /etc/openvpn/easy-rsa/pki/issued/somchai.crt -noout -serial
sudo /usr/local/bin/make-ovpn somchai
sudo install -o admin -g admin -m 600 /etc/openvpn/clients/somchai.ovpn /home/admin/somchai.ovpn
# บนเครื่อง laptop
scp -P 2222 admin@192.168.56.90:somchai.ovpn ~/
rm /home/admin/somchai.ovpn
# บนเครื่อง laptop
sudo install -m 600 ~/somchai.ovpn /etc/openvpn/client/somchai.conf
# บนเครื่อง laptop
sudo systemctl restart openvpn-client@somchai
sudo /etc/openvpn/easy-rsa/easyrsa --pki=/etc/openvpn/easy-rsa/pki --batch revoke-renewed somchai
sudo /etc/openvpn/easy-rsa/easyrsa --pki=/etc/openvpn/easy-rsa/pki --batch gen-crl
sudo install -m 644 /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn/server/crl.pem
# บนเครื่อง laptop
sudo systemctl restart openvpn-client@somchai
# บนเครื่อง laptop
ping -c2 -W2 10.10.0.1 | tail -2
sudo ls /etc/openvpn/easy-rsa/pki/inline/private/ | grep somchai
sudo /etc/openvpn/easy-rsa/easyrsa --pki=/etc/openvpn/easy-rsa/pki --batch inline somchai
sudo ls /etc/openvpn/easy-rsa/pki/inline/private/ | grep somchai
# ⚠️ อย่า revoke-renewed ก่อนผู้ใช้เปลี่ยนเป็นไฟล์ใหม่ ไฟล์เดิมของผู้ใช้มี certificate ใบเก่า ซึ่งจะเชื่อมไม่ได้ทันทีที่ CRL ใหม่ถูกติดตั้ง
# บนเครื่อง laptop
sudo systemctl stop openvpn-client@somchai
# บนเครื่อง laptop
sudo wg-quick up wg0

# ── กล่อง Ubuntu ────────────────────────────────────────────
sudo apt install -y openvpn easy-rsa
sudo mkdir -m 700 /etc/openvpn/easy-rsa
sudo cp -r /usr/share/easy-rsa/* /etc/openvpn/easy-rsa/
