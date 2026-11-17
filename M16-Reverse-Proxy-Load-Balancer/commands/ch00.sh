#!/usr/bin/env bash
# ก่อนเริ่ม: วิธีใช้หนังสือและเตรียม Lab Reverse Proxy
# SysAdmin Pocket Series M16 Reverse Proxy & Load Balancer
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── สร้าง VM สี่เครื่อง ─────────────────────────────────────
# PowerShell บนเครื่อง Windows
VBoxManage clonevm server --snapshot base-10.2 --options link --name lb1 --register
VBoxManage discardstate lb1
VBoxManage modifyvm lb1 --memory 1536 --cpus 2
VBoxManage modifyvm lb1 --natpf1 delete ssh
VBoxManage modifyvm lb1 --natpf1 "ssh,tcp,127.0.0.1,52271,,2222"
VBoxManage startvm lb1 --type headless
ssh -p 52271 admin@127.0.0.1
# บนเครื่อง lb1
sudo hostnamectl set-hostname lb1.lab.local
sudo nmcli con mod enp0s8 ipv4.addresses 192.168.56.71/24
sudo nmcli con up enp0s8
# บนเครื่อง Host
for ip in 71 72 73 74; do ssh -p 2222 admin@192.168.56.$ip hostname; done

# ── แอปหลังบ้าน be-app ──────────────────────────────────────
# บนเครื่อง be1
sudo install -m 755 be-app.py /usr/local/bin/be-app.py
sudo install -m 644 be-app.service /etc/systemd/system/
sudo mkdir -p /etc/be-app
sudo systemctl daemon-reload
sudo systemctl enable --now be-app
curl -s localhost:8080/
sudo firewall-cmd --permanent --add-rich-rule='rule family=ipv4 source address=192.168.56.71 port port=8080 protocol=tcp accept'
sudo firewall-cmd --permanent --add-rich-rule='rule family=ipv4 source address=192.168.56.72 port port=8080 protocol=tcp accept'
sudo firewall-cmd --reload
# บนเครื่อง lb1
curl -s 192.168.56.73:8080/
# บนเครื่อง Host
curl -s -m 5 -o /dev/null -w "%{http_code}\n" http://192.168.56.73:8080/

# ── Pebble: Let's Encrypt จำลองใน Lab ───────────────────────
# บนเครื่อง lb1
chmod +x setup-pebble.sh
sudo ./setup-pebble.sh
dig +short @127.0.0.1 -p 8053 web.lab.test
