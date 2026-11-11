#!/usr/bin/env bash
# Dockerfile: สร้าง Image ของเราเอง
# SysAdmin Pocket Series M06 Docker & Container Essentials
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── CMD กับ ENTRYPOINT ──────────────────────────────────────
cd ~/ch03/pinger
docker build -q -t pinger:1.0 .
docker run --rm pinger:1.0
docker run --rm pinger:1.0 1.1.1.1
docker run --rm --entrypoint echo pinger:1.0 hello

# ── 3.2 Multi-stage Build ───────────────────────────────────
cd ~/ch03/node-app
docker build -f Dockerfile.single -t hello:single .
docker build -t hello:1.0 .
docker images hello
docker run -d --name hello -p 3000:3000 -e APP_VERSION=1.0 hello:1.0
curl -s localhost:3000/; echo
docker exec hello id
docker ps --format "table {{.Names}}\t{{.Status}}"

# ── ลำดับคำสั่งกับ build cache ──────────────────────────────
sed -i "s/hello-docker/hello-docker-v2/" src/server.ts
docker build -t hello:1.1 . 2>&1 | grep -c CACHED

# ── .dockerignore ───────────────────────────────────────────
du -sh node_modules
docker build -f Dockerfile.single -t hello:single . 2>&1 | grep "transferring context" | tail -1
mv .dockerignore dockerignore.off
docker build -f Dockerfile.single -t hello:noignore . 2>&1 | grep "transferring context" | tail -1
mv dockerignore.off .dockerignore

# ── Lab 3.1 สร้าง Custom Nginx Image ────────────────────────
cd ~/ch03/nginx-custom
docker build -t mynginx:1.0 .
docker run -d --name mynginx -p 8085:80 mynginx:1.0
curl -s localhost:8085/ | grep h1
curl -sI localhost:8085/ | grep -iE "^server|x-content|x-frame"
docker images mynginx

# ── 3.4 Private Registry ────────────────────────────────────
cd ~/registry && docker compose up -d
docker tag hello:1.0 localhost:5000/hello:1.0
docker push localhost:5000/hello:1.0 2>&1 | tail -2
curl -s localhost:5000/v2/_catalog; curl -s localhost:5000/v2/hello/tags/list
docker rmi localhost:5000/hello:1.0
docker pull localhost:5000/hello:1.0 2>&1 | tail -2
docker tag hello:1.0 192.168.56.30:5000/hello:1.0
docker push 192.168.56.30:5000/hello:1.0 2>&1 | tail -2
echo "{ \"insecure-registries\": [\"192.168.56.30:5000\"] }" | sudo tee /etc/docker/daemon.json
sudo systemctl restart docker
docker info --format "{{.RegistryConfig.InsecureRegistryCIDRs}} {{range .RegistryConfig.IndexConfigs}}{{.Name}} secure={{.Secure}}; {{end}}"
docker push 192.168.56.30:5000/hello:1.0 2>&1 | tail -1
