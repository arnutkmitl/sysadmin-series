#!/usr/bin/env bash
# WireGuard: Remote Access และ Site-to-Site
# SysAdmin Pocket Series M09 VPN Server: WireGuard & OpenVPN
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 1.1 แนวคิดและการติดตั้ง ─────────────────────────────────
sudo dnf install -y wireguard-tools
wg --version
modinfo wireguard | head -1
# บนเครื่อง laptop
sudo dnf install -y wireguard-tools
sudo sh -c "umask 077; wg genkey | tee /etc/wireguard/private.key | wg pubkey > /etc/wireguard/public.key"
sudo ls -l /etc/wireguard/
sudo cat /etc/wireguard/public.key
# บนเครื่อง laptop
sudo sh -c "umask 077; wg genkey | tee /etc/wireguard/private.key | wg pubkey > /etc/wireguard/public.key"
# บนเครื่อง laptop
sudo cat /etc/wireguard/public.key

# ── wg0.conf ────────────────────────────────────────────────
sudo tee /etc/wireguard/wg0.conf > /dev/null <<EOF
# /etc/wireguard/wg0.conf (vpn1)
[Interface]
Address = 10.9.0.1/24
ListenPort = 51820
PrivateKey = $(sudo cat /etc/wireguard/private.key)

# laptop
[Peer]
PublicKey = o/0GD+SbVymq6NAQcfvUgmjI5DvyorGAXu7VpAIugEQ=
AllowedIPs = 10.9.0.2/32
EOF
sudo chmod 600 /etc/wireguard/wg0.conf

# ── เปิด forwarding และ firewall ────────────────────────────
sysctl net.ipv4.ip_forward
echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/90-vpn.conf
sudo sysctl --system | grep ip_forward
sudo firewall-cmd --zone=internal --list-all | grep forward:
sudo firewall-cmd --permanent --add-port=51820/udp
sudo firewall-cmd --permanent --zone=internal --change-interface=enp0s9
sudo firewall-cmd --permanent --zone=internal --add-interface=wg0
sudo firewall-cmd --reload

# ── เริ่ม wg0 ───────────────────────────────────────────────
sudo systemctl enable --now wg-quick@wg0
sudo wg show
sudo firewall-cmd --get-active-zones

# ── Linux ───────────────────────────────────────────────────
# บนเครื่อง laptop
sudo tee /etc/wireguard/wg0.conf > /dev/null <<EOF
# /etc/wireguard/wg0.conf (laptop)
[Interface]
Address = 10.9.0.2/32
PrivateKey = $(sudo cat /etc/wireguard/private.key)

[Peer]
PublicKey = rSHCqecIz/ovo7jAAh+f7kaDBOmwJbcJPbyUxnlE/W0=
Endpoint = 192.168.56.90:51820
AllowedIPs = 10.9.0.0/24, 172.16.1.0/24
PersistentKeepalive = 25
EOF
# บนเครื่อง laptop
sudo chmod 600 /etc/wireguard/wg0.conf
# บนเครื่อง laptop
sudo wg-quick up wg0
# บนเครื่อง laptop
sudo wg show
# บนเครื่อง laptop
ip route get 172.16.1.10
# บนเครื่อง laptop
ping -c3 -W2 172.16.1.10 | tail -2
# บนเครื่อง laptop
curl -s http://172.16.1.10:8080/
# บนเครื่อง app1
ping -c1 -W2 10.9.0.2 | tail -1

# ── โทรศัพท์และเครื่องที่ไม่มี command line ─────────────────
sudo dnf install -y epel-release
sudo dnf install -y qrencode
sudo mkdir -m 700 /etc/wireguard/clients
sudo sh -c "umask 077; wg genkey | tee /etc/wireguard/clients/phone.key | wg pubkey > /etc/wireguard/clients/phone.pub"
sudo tee /etc/wireguard/clients/phone.conf > /dev/null <<EOF
[Interface]
Address = 10.9.0.3/32
PrivateKey = $(sudo cat /etc/wireguard/clients/phone.key)

[Peer]
PublicKey = $(sudo cat /etc/wireguard/public.key)
Endpoint = 192.168.56.90:51820
AllowedIPs = 10.9.0.0/24, 172.16.1.0/24
PersistentKeepalive = 25
EOF
sudo chmod 600 /etc/wireguard/clients/phone.conf
sudo ls -l /etc/wireguard/clients/phone.conf
sudo qrencode -t ansiutf8 -r /etc/wireguard/clients/phone.conf
sudo qrencode -t png -o /etc/wireguard/clients/phone.png -r /etc/wireguard/clients/phone.conf

# ── เพิ่ม peer โดยไม่ตัดคนที่เชื่อมอยู่ ─────────────────────
sudo tee -a /etc/wireguard/wg0.conf > /dev/null <<EOF

# phone
[Peer]
PublicKey = $(sudo cat /etc/wireguard/clients/phone.pub)
AllowedIPs = 10.9.0.3/32
EOF
sudo bash -c "wg syncconf wg0 <(wg-quick strip wg0)"
sudo wg show wg0 allowed-ips

# ── 1.4 Site-to-Site ────────────────────────────────────────
# บนเครื่อง vpn2
sudo dnf install -y wireguard-tools
# บนเครื่อง vpn2
sudo sh -c "umask 077; wg genkey | tee /etc/wireguard/s2s-private.key | wg pubkey > /etc/wireguard/s2s-public.key"
# บนเครื่อง vpn2
sudo cat /etc/wireguard/s2s-public.key
sudo sh -c "umask 077; wg genkey | tee /etc/wireguard/s2s-private.key | wg pubkey > /etc/wireguard/s2s-public.key"
sudo cat /etc/wireguard/s2s-public.key
sudo tee /etc/wireguard/wg1.conf > /dev/null <<EOF
# /etc/wireguard/wg1.conf (vpn1 สำนักงานใหญ่)
[Interface]
Address = 10.9.1.1/30
ListenPort = 51821
PrivateKey = $(sudo cat /etc/wireguard/s2s-private.key)

# สาขา (vpn2)
[Peer]
PublicKey = CG0fwDddzS8DVhWf/AWQImHHyb64CVP2MdinN5sorSs=
Endpoint = 192.168.56.91:51821
AllowedIPs = 10.9.1.2/32, 172.16.2.0/24
PersistentKeepalive = 25
EOF
sudo chmod 600 /etc/wireguard/wg1.conf
sudo firewall-cmd --permanent --add-port=51821/udp
sudo firewall-cmd --permanent --zone=internal --add-interface=wg1
sudo firewall-cmd --reload
sudo systemctl enable --now wg-quick@wg1
# บนเครื่อง vpn2
sudo tee /etc/wireguard/wg1.conf > /dev/null <<EOF
# /etc/wireguard/wg1.conf (vpn2 สาขา)
[Interface]
Address = 10.9.1.2/30
ListenPort = 51821
PrivateKey = $(sudo cat /etc/wireguard/s2s-private.key)

# สำนักงานใหญ่ (vpn1)
[Peer]
PublicKey = 203oJp7F6xl+q9H0lt+T74c7SkanUtSDOFyLWipfLR4=
Endpoint = 192.168.56.90:51821
AllowedIPs = 10.9.1.1/32, 172.16.1.0/24, 10.9.0.0/24
PersistentKeepalive = 25
EOF
# บนเครื่อง vpn2
sudo chmod 600 /etc/wireguard/wg1.conf
# บนเครื่อง vpn2
echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/90-vpn.conf
# บนเครื่อง vpn2
sudo sysctl --system > /dev/null
# บนเครื่อง vpn2
sudo firewall-cmd --permanent --add-port=51821/udp
# บนเครื่อง vpn2
sudo firewall-cmd --permanent --zone=internal --change-interface=enp0s9
# บนเครื่อง vpn2
sudo firewall-cmd --permanent --zone=internal --add-interface=wg1
# บนเครื่อง vpn2
sudo firewall-cmd --reload
# บนเครื่อง vpn2
sudo systemctl enable --now wg-quick@wg1
# บนเครื่อง vpn2
sudo wg show wg1
# บนเครื่อง app1
ping -c3 -W2 172.16.2.1 | tail -2
# บนเครื่อง vpn2
ping -c2 -W2 -I 172.16.2.1 172.16.1.10 | tail -2

# ── กล่อง Ubuntu ────────────────────────────────────────────
sudo apt install -y wireguard-tools qrencode
