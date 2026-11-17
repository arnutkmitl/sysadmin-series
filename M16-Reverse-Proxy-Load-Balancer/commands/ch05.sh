#!/usr/bin/env bash
# บทที่ 5 Production Patterns และ Troubleshooting
# SysAdmin Pocket Series M16 Reverse Proxy & Load Balancer
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 5.2 แก้ config ระหว่างวัน: reload กับ restart ───────────
# บนเครื่อง lb1
( /tmp/load.sh https://web.lab.test/ 3000 > /tmp/r1.txt ) & sleep 1
for i in 1 2 3 4 5; do sudo systemctl reload haproxy; sleep 1; done; wait; cat /tmp/r1.txt
( /tmp/load.sh https://web.lab.test/ 3000 > /tmp/r2.txt ) & sleep 1
for i in 1 2 3; do sudo systemctl restart haproxy; sleep 1; done; wait; cat /tmp/r2.txt

# ── Lab 5.1 HAProxy L4 หน้า nginx ───────────────────────────
# บนเครื่อง lb1
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.dist
sudo vi /etc/nginx/nginx.conf        # ลบ server { listen 80; ... } ทั้ง block
sudo mv /etc/nginx/conf.d/web.conf /etc/nginx/conf.d/web.conf.ch01
sudo haproxy -c -f /etc/haproxy/haproxy.cfg -f /etc/haproxy/conf.d
sudo systemctl reload haproxy
sudo firewall-cmd --add-port=8443/tcp
# บนเครื่อง Host
curl -s -H "Host: web.lab.test" http://192.168.56.71:8443/
# บนเครื่อง lb1
curl -s -m 3 -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8009/
sudo tail -1 /var/log/nginx/error.log

# ── Lab 5.2 redirect loop ───────────────────────────────────
# บนเครื่อง lb1
curl -skL --max-redirs 10 -o /dev/null -w "%{http_code} redirects=%{num_redirects}\n" --resolve loop.lab.test:443:127.0.0.1 https://loop.lab.test/
curl -sk -D - -o /dev/null --resolve loop.lab.test:443:127.0.0.1 https://loop.lab.test/ | grep -iE "^HTTP|^location"
sudo nginx -t && sudo systemctl reload nginx
curl -skL --max-redirs 10 -w "%{http_code} redirects=%{num_redirects}\n" --resolve loop.lab.test:443:127.0.0.1 https://loop.lab.test/

# ── 5.5 เฝ้าดู proxy ด้วย Prometheus ────────────────────────
# บนเครื่อง lb1
sudo haproxy -c -f /etc/haproxy/haproxy.cfg -f /etc/haproxy/conf.d && sudo systemctl reload haproxy
curl -s localhost:8404/metrics | grep -c "^haproxy_"
# บนเครื่อง lb2
curl -s localhost:8404/metrics | grep 'haproxy_server_status{proxy="web_back",server="be1",state="UP"'
# บนเครื่อง lb1
sudo install -d -o admin /opt/prom
cp prometheus.yml /opt/prom/
docker run -d --name prom --restart unless-stopped -p 9090:9090 \
sudo firewall-cmd --add-port=9090/tcp
curl -s "localhost:9090/api/v1/query?query=haproxy_backend_active_servers" | python3 -c "import sys,json;[print(r['metric']['instance'],r['metric']['proxy'],r['value'][1]) for r in json.load(sys.stdin)['data']['result']]"
