#!/usr/bin/env bash
# บทที่ 4 High Availability ด้วย keepalived
# SysAdmin Pocket Series M16 Reverse Proxy & Load Balancer
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 4.2 HAProxy บน lb2 ──────────────────────────────────────
# บนเครื่อง lb1
sudo tar czf /tmp/hap.tgz -C /etc/haproxy haproxy.cfg certs
sudo chown admin /tmp/hap.tgz
# PowerShell บนเครื่อง Windows
scp -P 2222 admin@192.168.56.71:/tmp/hap.tgz .
scp -P 2222 hap.tgz admin@192.168.56.72:/tmp/
# บนเครื่อง lb2
sudo dnf install -y haproxy policycoreutils-python-utils socat tar
sudo tar xzf /tmp/hap.tgz -C /etc/haproxy
rm /tmp/hap.tgz
sudo chmod 700 /etc/haproxy/certs
sudo restorecon -R /etc/haproxy
sudo semanage port -a -t http_port_t -p tcp 8404
sudo firewall-cmd --permanent --add-service=http --add-service=https
sudo firewall-cmd --permanent --add-port=8404/tcp
sudo firewall-cmd --reload
sudo haproxy -c -f /etc/haproxy/haproxy.cfg && sudo systemctl enable --now haproxy
for d in web api; do curl -sk --resolve $d.lab.test:443:127.0.0.1 https://$d.lab.test/ | head -1; done

# ── Lab 4.1 VIP แรก ─────────────────────────────────────────
# บนเครื่อง Host
diff keepalived-lb1.conf keepalived-lb2.conf
# บนเครื่อง lb1
sudo dnf install -y keepalived
keepalived --version 2>&1 | head -1
sudo firewall-cmd --permanent --add-rich-rule='rule protocol value=vrrp accept'
sudo firewall-cmd --reload
sudo install -m 600 keepalived-lb1.conf /etc/keepalived/keepalived.conf
sudo systemctl enable --now keepalived
ip -4 -br a show enp0s8
sudo journalctl -u keepalived -o cat --no-pager | grep -iE "script|STATE"
sudo semanage fcontext -l | grep -i keepalived
sudo install -D -m 755 chk_haproxy.sh /usr/libexec/keepalived/chk_haproxy.sh
sudo restorecon -R /usr/libexec/keepalived
ls -Z /usr/libexec/keepalived/chk_haproxy.sh
sudo sed -i 's#script "/usr/bin/systemctl is-active --quiet haproxy"#script "/usr/libexec/keepalived/chk_haproxy.sh"#' /etc/keepalived/keepalived.conf
sudo systemctl restart keepalived
sudo journalctl -u keepalived --since -10s -o cat --no-pager | grep -iE "script|STATE"

# ── Lab 4.2 วัดคำขอที่หายระหว่างย้าย VIP ────────────────────
# บนเครื่อง Host
python vip_probe.py 40 test1.txt &
# บนเครื่อง lb1
sudo systemctl stop haproxy
sudo systemctl start haproxy
# บนเครื่อง Host
awk '{print $2,$3}' test1.txt | uniq -c
sed -n 45,50p test1.txt
# บนเครื่อง lb2
sudo journalctl -u keepalived --since -60s -o short-precise --no-pager | grep STATE
# ⚠️ คำสั่ง `VBoxManage controlvm lb1 poweroff` ปิด VM ทันทีโดยไม่ shutdown ข้อมูลที่ยังไม่ได้เขียนลงดิสก์จะหาย ใช้กับเครื่อง Lab ที่ไม่มีข้อมูลสำคัญเท่านั้น
# บนเครื่อง Host
python vip_probe.py 150 test2.txt &
# PowerShell บนเครื่อง Windows
VBoxManage controlvm lb1 poweroff
VBoxManage startvm lb1 --type headless
# บนเครื่อง Host
awk '{print $2,$3}' test2.txt | uniq -c
# บนเครื่อง lb2
sudo journalctl -u keepalived --since -160s -o short-precise --no-pager | grep STATE
