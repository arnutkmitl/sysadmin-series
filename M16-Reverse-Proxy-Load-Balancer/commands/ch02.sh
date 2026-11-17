#!/usr/bin/env bash
# บทที่ 2 HAProxy
# SysAdmin Pocket Series M16 Reverse Proxy & Load Balancer
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ──  ────────────────────────────────────────────────────────
# บนเครื่อง lb1
sudo systemctl disable --now nginx

# ── Lab 2.1 HAProxy กับสองหลังบ้าน ──────────────────────────
# บนเครื่อง lb1
sudo dnf install -y haproxy
haproxy -v | head -1
sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.dist
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
sudo systemctl enable --now haproxy
sudo journalctl -u haproxy -n 4 -o cat --no-pager
sudo dnf install -y policycoreutils-python-utils
sudo semanage port -l | grep -E "^http_port_t|^http_cache_port_t"
sudo semanage port -a -t http_port_t -p tcp 8404
sudo systemctl restart haproxy
sudo firewall-cmd --permanent --add-port=8404/tcp
sudo firewall-cmd --reload
for i in 1 2 3 4; do curl -s -H "Host: web.lab.test" http://127.0.0.1/ | head -1; done

# ── 2.3 วิธีเลือกหลังบ้าน ───────────────────────────────────
# บนเครื่อง lb1
for i in 1 2 3 4; do curl -sk -b /tmp/cj -c /tmp/cj --resolve web.lab.test:443:127.0.0.1 https://web.lab.test/ | head -1; done
grep SRV /tmp/cj | awk '{print $6"="$7}'

# ── Lab 2.2 ทำให้ be2 ไม่ผ่าน health check ──────────────────
# บนเครื่อง be2
sudo touch /etc/be-app/down
# บนเครื่อง lb1
sudo journalctl -u haproxy --since "-1min" -o cat --no-pager | grep be2
# บนเครื่อง Host
for i in 1 2 3 4; do curl -s --resolve web.lab.test:80:192.168.56.71 http://web.lab.test/ | head -1; done
# บนเครื่อง be2
sudo rm /etc/be-app/down

# ── Lab 2.3 ใบรับรองสำหรับ web และ api ──────────────────────
# บนเครื่อง lb1
sudo install -m 755 haproxy-deploy-hook.sh /etc/letsencrypt/renewal-hooks/deploy/haproxy.sh
sudo REQUESTS_CA_BUNDLE=/opt/pebble/certs/pebble.minica.pem certbot certonly --standalone \
sudo timeout 20 python3 -m http.server 8888 --bind 127.0.0.1 &
curl -s -o /dev/null -w "%{http_code}\n" -H "Host: api.lab.test" http://127.0.0.1/.well-known/acme-challenge/x
sudo setsebool -P haproxy_connect_any 1
curl -s -o /dev/null -w "%{http_code}\n" -H "Host: api.lab.test" http://127.0.0.1/.well-known/acme-challenge/x
sudo setsebool -P haproxy_connect_any 0
sudo semanage port -a -t http_cache_port_t -p tcp 8888
sudo REQUESTS_CA_BUNDLE=/opt/pebble/certs/pebble.minica.pem certbot certonly --standalone \
sudo ls /etc/haproxy/certs/
sudo REQUESTS_CA_BUNDLE=/opt/pebble/certs/pebble.minica.pem certbot certonly --standalone \
sudo ls -l /etc/haproxy/certs/
sudo haproxy -c -f /etc/haproxy/haproxy.cfg && sudo systemctl reload haproxy
# บนเครื่อง Host
curl -s --cacert lab-root.pem --resolve web.lab.test:443:192.168.56.71 https://web.lab.test/
echo $?
curl -s --ssl-no-revoke --cacert lab-root.pem --resolve api.lab.test:443:192.168.56.71 https://api.lab.test/ | grep -E "backend|Host|Proto"
python check_sni.py

# ── 2.6 ACL และจำกัดจำนวนคำขอ ───────────────────────────────
# บนเครื่อง lb1
for i in $(seq 1 14); do curl -sk -o /dev/null -w "%{http_code} " --resolve api.lab.test:443:127.0.0.1 https://api.lab.test/; done; echo

# ── 2.7 Runtime API: แก้สถานะโดยไม่ reload ──────────────────
# บนเครื่อง lb1
sudo dnf install -y socat
echo "set server web_back/be2 state drain" | sudo socat stdio /var/lib/haproxy/stats
echo "show servers state web_back" | sudo socat stdio /var/lib/haproxy/stats | awk 'NR>2{print $4, $6, $7}'
for i in 1 2 3 4; do curl -sk --resolve web.lab.test:443:127.0.0.1 https://web.lab.test/ | head -1; done
echo "set server web_back/be2 state ready" | sudo socat stdio /var/lib/haproxy/stats
