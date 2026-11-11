#!/usr/bin/env bash
# Docker Fundamentals: Container, Image, Volume และ Network
# SysAdmin Pocket Series M06 Docker & Container Essentials
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 1.1 ติดตั้ง Docker CE ───────────────────────────────────
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
docker version --format "Client {{.Client.Version}} / Server {{.Server.Version}}"
systemctl is-enabled docker
docker info --format "{{.Driver}} cgroup v{{.CgroupVersion}}"
sudo docker run --rm hello-world

# ── ใช้ docker โดยไม่ต้อง sudo ──────────────────────────────
sudo usermod -aG docker $USER
exit
id

# ── 1.2 วงจรชีวิตของ Container ──────────────────────────────
docker run -d --name web1 -p 8080:80 nginx:1.30
docker ps --format "table {{.Names}}	{{.Status}}	{{.Ports}}"
curl -sI http://localhost:8080 | head -2

# ── ดู log และเข้าไปใน container ────────────────────────────
docker logs web1 2>&1 | tail -3
docker exec web1 nginx -v

# ── หยุด เริ่มใหม่ และลบ ────────────────────────────────────
docker stop web1
docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
docker start web1
docker rm web1
docker rm -f web1
# ⚠️ `docker rm` ลบไฟล์ทุกไฟล์ที่ container เขียนไว้ภายในตัวมัน กู้คืนไม่ได้ ข้อมูลที่ต้องอยู่รอดต้องเก็บใน volume ตามหัวข้อ 1.4 ก่อนลบเสมอ
docker run --rm alpine:3.22 cat /etc/alpine-release
docker ps -a --format "{{.Names}}" | wc -l

# ── ดู image ในเครื่อง ──────────────────────────────────────
docker images
docker image inspect nginx:1.30 --format "{{.Os}}/{{.Architecture}} created {{.Created}}"

# ── Tag และการ pin รุ่น ─────────────────────────────────────
docker pull nginx:1.30.6
docker images nginx
docker rmi nginx:1.30.6

# ── Named Volume ────────────────────────────────────────────
docker volume create dbdata
docker volume ls
docker volume inspect dbdata --format "{{.Mountpoint}}"
docker run -d --name db1 -e MYSQL_ROOT_PASSWORD=Lab-Pass-2569 -v dbdata:/var/lib/mysql mysql:8.4
docker exec db1 mysql -uroot -pLab-Pass-2569 -e "CREATE DATABASE shop; CREATE TABLE shop.orders(id INT PRIMARY KEY, item VARCHAR(40)); INSERT INTO shop.orders VALUES (1,'keyboard'),(2,'monitor');"
docker rm -f db1
docker run -d --name db2 -e MYSQL_ROOT_PASSWORD=Lab-Pass-2569 -v dbdata:/var/lib/mysql mysql:8.4
docker exec db2 mysql -uroot -pLab-Pass-2569 -e "SELECT * FROM shop.orders;"

# ── Bind Mount ──────────────────────────────────────────────
mkdir -p ~/site && echo "<h1>bind mount</h1>" > ~/site/index.html
docker run -d --name b1 -p 8081:80 -v ~/site:/usr/share/nginx/html:ro nginx:1.30
curl -s http://localhost:8081
echo "<h1>edited on host</h1>" > ~/site/index.html; curl -s http://localhost:8081
docker exec b1 touch /usr/share/nginx/html/x

# ── 1.5 Network ─────────────────────────────────────────────
docker network ls

# ── Bridge ที่สร้างเองเรียกกันด้วยชื่อได้ ───────────────────
docker run -d --name a1 nginx:1.30
docker run --rm busybox:1.37 ping -c1 -W2 a1
docker inspect a1 --format "{{.NetworkSettings.Networks.bridge.IPAddress}}"
docker rm -f a1
docker network create labnet
docker run -d --name a1 --network labnet nginx:1.30
docker run --rm --network labnet busybox:1.37 ping -c1 -W2 a1
docker rm -f a1

# ── Lab 1.4 Nginx กับ PHP-FPM บน network เดียวกัน ───────────
mkdir -p ~/lab14/html ~/lab14/conf
docker network create labnet
docker run -d --name php --network labnet -v ~/lab14/html:/var/www/html:ro php:8.4-fpm
docker run -d --name web --network labnet -p 8080:80 -v ~/lab14/html:/var/www/html:ro -v ~/lab14/conf/default.conf:/etc/nginx/conf.d/default.conf:ro nginx:1.30
curl -s localhost:8080
docker exec web getent hosts php
docker rm -f php
docker run -d --name php -v ~/lab14/html:/var/www/html:ro php:8.4-fpm
curl -s -o /dev/null -w "%{http_code}
docker logs web 2>&1 | grep -E "error|emerg" | tail -1 | cut -c1-160

# ── Port mapping กับ firewalld ──────────────────────────────
sudo firewall-cmd --list-ports; sudo firewall-cmd --list-services
sudo firewall-cmd --get-active-zones
docker run -d --name fw -p 8082:80 nginx:1.30
docker run -d --name fwlocal -p 127.0.0.1:8083:80 nginx:1.30
docker ps --format "{{.Names}} {{.Ports}}"

# ── กล่อง Ubuntu ────────────────────────────────────────────
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
