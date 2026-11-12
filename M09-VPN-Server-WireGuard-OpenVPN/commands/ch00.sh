#!/usr/bin/env bash
# ก่อนเริ่ม: วิธีใช้หนังสือและเตรียมเครื่อง
# SysAdmin Pocket Series M09 VPN Server: WireGuard & OpenVPN
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── สิ่งที่ต้องเตรียม ───────────────────────────────────────
sudo nmcli con mod "Wired connection 1" con-name enp0s9 ipv4.method manual ipv4.addresses 172.16.1.1/24 ipv6.method disabled
sudo nmcli con up enp0s9
# บนเครื่อง vpn2
sudo nmcli con mod "Wired connection 1" con-name enp0s9 ipv4.method manual ipv4.addresses 172.16.2.1/24 ipv6.method disabled
# บนเครื่อง vpn2
sudo nmcli con up enp0s9
# บนเครื่อง app1
sudo nmcli con mod "Wired connection 1" con-name enp0s9 ipv4.method manual ipv4.addresses 172.16.1.10/24 ipv4.gateway 172.16.1.1 ipv6.method disabled
# บนเครื่อง app1
sudo nmcli con up enp0s9
# บนเครื่อง app1
ping -c1 -W2 172.16.1.1 | tail -2

# ── intranet บน app1 ────────────────────────────────────────
# บนเครื่อง app1
sudo mkdir -p /srv/intranet
# บนเครื่อง app1
echo "intranet ของสำนักงานใหญ่ (app1)" | sudo tee /srv/intranet/index.html
# บนเครื่อง app1
sudo tee /etc/systemd/system/intranet.service > /dev/null <<EOF
# /etc/systemd/system/intranet.service (app1)
[Unit]
Description=Intranet test page
After=network-online.target

[Service]
ExecStart=/usr/bin/python3 -m http.server 8080 --directory /srv/intranet
Restart=always

[Install]
WantedBy=multi-user.target
EOF
# บนเครื่อง app1
sudo systemctl daemon-reload
# บนเครื่อง app1
sudo systemctl enable --now intranet
# บนเครื่อง app1
sudo firewall-cmd --permanent --add-port=8080/tcp
# บนเครื่อง app1
sudo firewall-cmd --reload
# บนเครื่อง app1
curl -s http://172.16.1.10:8080/

# ── ทดสอบก่อนมี VPN ─────────────────────────────────────────
# บนเครื่อง laptop
ip route get 172.16.1.10
# บนเครื่อง laptop
curl -s -m 5 http://172.16.1.10:8080/; echo "exit=$?"
