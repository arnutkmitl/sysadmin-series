#!/usr/bin/env bash
# บทที่ 6 โปรเจกต์จบเล่ม: Multi-Service Proxy ที่ไม่มีจุดล่มจุดเดียว
# SysAdmin Pocket Series M16 Reverse Proxy & Load Balancer
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 6.2 ให้ DNS ชี้ไปที่ VIP ────────────────────────────────
# บนเครื่อง lb1
sudo ./setup-pebble.sh 192.168.56.75
dig +short -p 8053 @127.0.0.1 app.lab.test
sudo REQUESTS_CA_BUNDLE=/opt/pebble/certs/pebble.minica.pem certbot renew --force-renewal --no-random-sleep-on-renew --cert-name web.lab.test
sudo ./setup-pebble.sh 192.168.56.75 | head -2
sudo REQUESTS_CA_BUNDLE=/opt/pebble/certs/pebble.minica.pem certbot renew --force-renewal --no-random-sleep-on-renew 2>&1 | grep success

# ── 6.3 บริการที่สาม app.lab.test ───────────────────────────
# บนเครื่อง be1
sudo install -m 644 be-app2.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now be-app2
sudo firewall-cmd --permanent --add-rich-rule='rule family=ipv4 source address=192.168.56.71 port port=8081 protocol=tcp accept'
sudo firewall-cmd --permanent --add-rich-rule='rule family=ipv4 source address=192.168.56.72 port port=8081 protocol=tcp accept'
sudo firewall-cmd --reload
curl -s localhost:8081/ | head -1

# ── 6.4 ACME ที่ใช้ได้จากทั้งสองเครื่อง ─────────────────────
# บนเครื่อง lb1
sudo sed -i "s/^http01_address = .*/http01_address = 0.0.0.0/" /etc/letsencrypt/renewal/*.conf
sudo firewall-cmd --permanent --add-rich-rule='rule family=ipv4 source address=192.168.56.72 port port=8888 protocol=tcp accept'
sudo firewall-cmd --reload
# บนเครื่อง lb2
sudo semanage port -a -t http_cache_port_t -p tcp 8888

# ── 6.5 ส่งใบรับรองไป lb2 อย่างปลอดภัย ──────────────────────
# บนเครื่อง lb1
sudo ssh-keygen -q -t ed25519 -N "" -C root@lb1-certsync -f /root/.ssh/certsync
sudo cat /root/.ssh/certsync.pub
# บนเครื่อง lb2
sudo useradd -r -m -s /bin/bash certsync
sudo install -m 750 haproxy-cert-recv /usr/local/sbin/
sudo install -m 755 certsync-wrap /usr/local/bin/
echo "certsync ALL=(root) NOPASSWD: /usr/local/sbin/haproxy-cert-recv" | sudo tee /etc/sudoers.d/certsync
sudo chmod 440 /etc/sudoers.d/certsync
sudo visudo -cf /etc/sudoers.d/certsync
sudo install -d -m 700 -o certsync -g certsync /home/certsync/.ssh
echo 'command="/usr/local/bin/certsync-wrap",no-pty,no-port-forwarding,no-agent-forwarding,no-X11-forwarding ssh-ed25519 AAAA... root@lb1-certsync' | sudo tee /home/certsync/.ssh/authorized_keys
sudo chown certsync:certsync /home/certsync/.ssh/authorized_keys
sudo chmod 600 /home/certsync/.ssh/authorized_keys
sudo restorecon -R /home/certsync/.ssh
# บนเครื่อง lb1
sudo sh -c "ssh-keyscan -p 2222 -t ed25519 192.168.56.72 >> /root/.ssh/known_hosts"
sudo REQUESTS_CA_BUNDLE=/opt/pebble/certs/pebble.minica.pem certbot certonly --standalone \
sudo REQUESTS_CA_BUNDLE=/opt/pebble/certs/pebble.minica.pem certbot renew --force-renewal --no-random-sleep-on-renew 2>&1 | grep -E "success|installed"
# บนเครื่อง lb2
sudo ls -l /etc/haproxy/certs
sudo journalctl -t sudo --since -5min -o cat --no-pager | grep COMMAND | tail -1

# ── Lab 6.1 รันครั้งแรก ─────────────────────────────────────
# บนเครื่อง lb1
chmod +x check-proxy.sh
./check-proxy.sh; echo "rc=$?"
sudo semanage port -l | grep -w 8081
sudo semanage port -a -t http_cache_port_t -p tcp 8081
./check-proxy.sh; echo "rc=$?"

# ── Lab 6.2 หลังบ้านดับหนึ่งเครื่อง ─────────────────────────
# บนเครื่อง be1
sudo systemctl stop be-app be-app2
# บนเครื่อง lb1
./check-proxy.sh; echo "rc=$?"
# บนเครื่อง be1
sudo systemctl start be-app be-app2

# ── Lab 6.3 ต่ออายุใบรับรองขณะ VIP อยู่ที่ lb2 ──────────────
# บนเครื่อง lb1
sudo systemctl stop keepalived
ip -4 -br a show enp0s8 | awk '{print $3,$4}'
python3 serial.py
sudo REQUESTS_CA_BUNDLE=/opt/pebble/certs/pebble.minica.pem certbot renew --force-renewal --no-random-sleep-on-renew --cert-name web.lab.test 2>&1 | grep -E "success|installed"
python3 serial.py
./check-proxy.sh | head -1
sudo systemctl start keepalived
