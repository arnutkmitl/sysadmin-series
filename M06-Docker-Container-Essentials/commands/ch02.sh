#!/usr/bin/env bash
# Docker Compose: ขึ้นระบบหลาย Container ด้วยไฟล์เดียว
# SysAdmin Pocket Series M06 Docker & Container Essentials
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 2.1 Docker Compose คืออะไร ──────────────────────────────
docker compose version

# ── แปลง Lab 1.4 เป็นไฟล์ compose ───────────────────────────
cd ~/web-php
docker compose up -d
docker compose ps --format "table {{.Name}}	{{.Image}}	{{.Status}}"
docker compose ps --format "{{.Service}}: {{.Ports}}"
curl -s localhost:8080

# ── คำสั่งประจำวัน ──────────────────────────────────────────
docker compose logs --tail 2 web
docker compose exec web getent hosts php
docker compose stop
docker compose start
docker compose down

# ── restart policy ──────────────────────────────────────────
docker inspect -f "{{.HostConfig.RestartPolicy.Name}}" wordpress-wordpress-1
sudo systemctl restart docker
docker compose ps --format "table {{.Service}}\t{{.Status}}"

# ── 2.3 ตัวแปร, ไฟล์ .env และ Secret ────────────────────────
cd ~/stacks/lemp
docker compose config --quiet
cp .env.example .env
sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=$(head -c 12 /dev/urandom | base64)/" .env
docker compose config | grep -A2 "DB_HOST" | head -3

# ── Secret ──────────────────────────────────────────────────
cd ~/stacks/wordpress
cp .env.example .env
head -c 18 /dev/urandom | base64 > secrets/db_password.txt; head -c 18 /dev/urandom | base64 > secrets/db_root_password.txt
chmod 600 secrets/*.txt; ls -l secrets
docker compose up -d
curl -s -o /dev/null -w "%{http_code}\n" localhost:8080/
docker compose logs wordpress 2>&1 | grep -o "PHP Warning.*denied" | head -1
docker compose exec wordpress ls -ln /run/secrets/
chmod 700 secrets; chmod 644 secrets/*.txt; ls -ld secrets
curl -s -o /dev/null -w "%{http_code} %{redirect_url}\n" localhost:8080/

# ── Stack 2 LEMP (Nginx + PHP-FPM + MySQL) ──────────────────
cd ~/stacks/lemp
docker compose up -d --build
curl -s localhost:8081/
docker compose ps --format "table {{.Service}}\t{{.Image}}\t{{.Status}}"

# ── Stack 3 Monitoring (Prometheus + Node Exporter + Grafana) ────
cd ~/stacks/monitoring
docker compose up -d
curl -s localhost:9090/api/v1/targets | python3 -c "import sys,json; [print(t[\"labels\"][\"job\"], t[\"health\"]) for t in json.load(sys.stdin)[\"data\"][\"activeTargets\"]]"
curl -s localhost:3000/api/health

# ── Stack 4 GitLab CE ───────────────────────────────────────
cd ~/stacks/gitlab
docker compose up -d
docker compose ps --format "table {{.Service}}	{{.Status}}"
docker compose exec gitlab grep "^Password:" /etc/gitlab/initial_root_password

# ── Stack 5 Nextcloud + MariaDB + Redis ─────────────────────
cd ~/stacks/nextcloud
grep -v PASSWORD .env
docker compose up -d
curl -s localhost:8083/status.php; echo
docker compose exec -u www-data app php occ config:system:get memcache.locking
curl -s -o /dev/null -w "%{http_code}\n" http://192.168.56.30:8083/login
curl -s -o /dev/null -w "%{http_code}\n" -H "Host: nc.lab.test:8083" http://localhost:8083/login

# ── Stack 6 Portainer CE ────────────────────────────────────
cd ~/stacks/portainer
docker compose up -d
curl -sk -o /dev/null -w "%{http_code}\n" https://localhost:9443/
docker compose logs portainer | grep setup_token
