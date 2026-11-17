#!/usr/bin/env bash
# บทที่ 3 Traefik
# SysAdmin Pocket Series M16 Reverse Proxy & Load Balancer
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ──  ────────────────────────────────────────────────────────
# บนเครื่อง lb1
sudo systemctl disable --now haproxy

# ── Lab 3.1 Traefik และ Dashboard ───────────────────────────
# บนเครื่อง lb1
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker admin
docker --version; docker compose version
sudo install -d -o admin -g admin /opt/traefik /opt/traefik/dynamic /opt/traefik/acme
cd /opt/traefik
docker run --rm httpd:2.4-alpine htpasswd -nbB admin LabTraefik-2569 > dynamic/users.htpasswd
chmod 700 acme
docker compose up -d
docker compose ps --format "{{.Name}} {{.Status}}"

# ── ใบรับรองจาก Pebble ──────────────────────────────────────
# บนเครื่อง lb1
docker logs traefik 2>&1 | grep -E "certificate" | cut -c1-120
sudo ls -l acme

# ── Lab 3.2 route หลาย container ────────────────────────────
# บนเครื่อง Host
for i in 1 2 3 4; do curl -s --ssl-no-revoke --cacert lab-root.pem --resolve app.lab.test:443:192.168.56.71 https://app.lab.test/ | grep Hostname; done
curl -s -o /dev/null -w "%{http_code}\n" --ssl-no-revoke --cacert lab-root.pem --resolve admin.lab.test:443:192.168.56.71 https://admin.lab.test/
curl -s --ssl-no-revoke --cacert lab-root.pem -u admin:LabTraefik-2569 --resolve admin.lab.test:443:192.168.56.71 https://admin.lab.test/ | grep -E "Hostname|X-Forwarded-For|X-Real-Ip|X-Forwarded-Proto"
curl -s -o /dev/null -w "%{http_code} -> %{redirect_url}\n" --resolve app.lab.test:80:192.168.56.71 http://app.lab.test/

# ── 3.4 file provider: ส่งต่อไปเครื่องที่ไม่ใช่ container ────
# บนเครื่อง Host
for i in 1 2; do curl -s --ssl-no-revoke --cacert lab-root.pem --resolve web.lab.test:443:192.168.56.71 https://web.lab.test/ | grep -E "backend|X-Forwarded-For|Proto"; done

# ── 3.5 middleware: rate limit ──────────────────────────────
# บนเครื่อง lb1
seq 1 30 | xargs -P 10 -I{} curl -s -o /dev/null -w "%{http_code}\n" --resolve app.lab.test:443:127.0.0.1 https://app.lab.test/ | sort | uniq -c

# ── 3.6 ความปลอดภัยของ docker.sock ──────────────────────────
# บนเครื่อง lb1
docker run --rm --user 0 -v /var/run/docker.sock:/var/run/docker.sock:ro curlimages/curl -s \
docker rm ro-socket-test
# ⚠️ อย่าเชื่อว่า `:ro` ทำให้ docker.sock ปลอดภัย เพราะช่องโหว่ใน Traefik หรือในไฟล์ dynamic ที่คนอื่นแก้ได้ ก็เท่ากับสิทธิ์ root บน lb1 ในงานจริงให้ใช้ docker socket proxy ที่อนุญาตเฉพาะ API สำหรับอ่านข้อมูล container หรือแยกเครื่องที่รัน Traefik ออกจากเครื่องที่มีข้อมูลสำคัญ
docker compose down
sudo systemctl enable --now haproxy
