#!/usr/bin/env bash
# Docker in Production: ปลอดภัย ดูแลง่าย และกู้คืนได้
# SysAdmin Pocket Series M06 Docker & Container Essentials
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── จำกัดหน่วยความจำและ CPU ─────────────────────────────────
docker run -d --name web -p 8080:80 --memory 256m --cpus 0.5 nginx:1.30
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" web
docker run --rm --cpus 0.5 alpine:3.22 cat /sys/fs/cgroup/cpu.max
docker run --rm alpine:3.22 cat /sys/fs/cgroup/cpu.max
docker run --name hog --memory 64m alpine:3.22 sh -c "tail /dev/zero"
docker inspect hog --format "exit={{.State.ExitCode}} oom={{.State.OOMKilled}}"

# ── ระบบไฟล์อ่านอย่างเดียว ──────────────────────────────────
docker run -d --name ro --read-only -p 8080:80 nginx:1.30
docker ps -a --filter name=ro --format "{{.Names}} {{.Status}}"
docker logs ro 2>&1 | grep -iE "emerg|read-only" | head -2
docker rm -f ro
docker run -d --name ro --read-only --tmpfs /var/cache/nginx --tmpfs /var/run --tmpfs /tmp -p 8080:80 nginx:1.30
curl -s -o /dev/null -w "%{http_code}\n" localhost:8080
docker exec ro touch /usr/share/nginx/html/hack.html

# ── Docker socket คือสิทธิ์ root ────────────────────────────
docker run --rm -v /:/host alpine:3.22 head -1 /host/etc/shadow | cut -c1-12

# ── Rootless Docker ─────────────────────────────────────────
sudo useradd -m rl
sudo loginctl enable-linger rl
grep rl /etc/subuid
dockerd-rootless-setuptool.sh check
dockerd-rootless-setuptool.sh install
systemctl --user is-active docker
docker info --format "{{.SecurityOptions}}"
docker run -d --name rweb -p 8088:80 nginx:1.30
ps -o user,pid,cmd -C nginx | head -3
docker run -d --name rweb80 -p 80:80 nginx:1.30

# ── สแกนช่องโหว่ใน image ────────────────────────────────────
docker run --rm -v trivy-cache:/root/.cache aquasec/trivy:0.76.2 image --quiet --scanners vuln --severity HIGH,CRITICAL nginx:1.30 2>&1 | grep "^Total"
docker run --rm -v trivy-cache:/root/.cache aquasec/trivy:0.76.2 image --quiet --scanners vuln --severity HIGH,CRITICAL nginx:1.30-alpine 2>&1 | grep "^Total"
docker run --rm -v trivy-cache:/root/.cache aquasec/trivy:0.76.2 image --quiet --scanners vuln --severity CRITICAL --exit-code 1 nginx:1.30 >/dev/null 2>&1; echo "exit=$?"

# ── ตั้งการหมุน log ให้ทุก container ────────────────────────
docker run -d --name chatty alpine:3.22 sh -c "while :; do echo log-line-\$(date +%s%N); done"
sudo du -sh $(docker inspect chatty --format "{{.LogPath}}")
sudo systemctl restart docker
docker run -d --name chatty alpine:3.22 sh -c "while :; do echo log-line-\$(date +%s%N); done"
docker inspect chatty --format "{{.HostConfig.LogConfig}}"
# ⚠️ ค่าใน daemon.json มีผลกับ container ที่สร้างใหม่เท่านั้น container ที่มีอยู่ก่อนยังใช้ค่าเดิมจนกว่าจะสร้างใหม่ หลังแก้ไฟล์ให้สั่ง `docker compose up -d --force-recreate` ในทุก stack ถ้า daemon.json มี JSON ผิดรูปแบบ Docker จะเริ่มไม่ได้ ตรวจด้วย `python3 -m json.tool /etc/docker/daemon.json` ก่อน restart ทุกครั้ง
docker run -d --name jd --log-driver journald alpine:3.22 sh -c "echo hello-journald; sleep 2"
sudo journalctl CONTAINER_NAME=jd --no-pager -o cat | tail -1

# ── อัปเดตด้วย Compose ──────────────────────────────────────
cat .env
curl -sI localhost:8080 | grep Server
sed -i "s/1.30.5/1.30.6/" .env
docker compose pull
docker compose up -d
curl -sI localhost:8080 | grep Server
docker compose up -d
sed -i "s/1.30.6/1.30.5/" .env && docker compose up -d
curl -sI localhost:8080 | grep Server

# ── Watchtower ──────────────────────────────────────────────
docker run --name watchtower -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower:1.7.1 --run-once
docker version --format "API {{.Server.APIVersion}} min {{.Server.MinAPIVersion}}"

# ── สำรองฐานข้อมูลด้วย dump ─────────────────────────────────
cd ~/stacks/wordpress
mkdir -p ~/backup
docker compose exec -T db sh -c "mariadb-dump -uroot -p\"\$(cat /run/secrets/db_root_password)\" --single-transaction wordpress" > ~/backup/wordpress-$(date +%F).sql
ls -lh ~/backup

# ── สำรอง volume ด้วย container ชั่วคราว ────────────────────
docker run --rm -v wordpress_wp_data:/data:ro -v ~/backup:/backup alpine:3.22 tar czf /backup/wp_data-$(date +%F).tar.gz -C /data .
ls -lh ~/backup

# ── ทดสอบกู้คืน ─────────────────────────────────────────────
docker compose down -v
docker compose up -d
docker run --rm -v wordpress_wp_data:/data -v ~/backup:/backup alpine:3.22 sh -c "rm -rf /data/* && tar xzf /backup/wp_data-$(date +%F).tar.gz -C /data"
docker compose exec -T db sh -c "mariadb -uroot -p\"\$(cat /run/secrets/db_root_password)\" wordpress" < ~/backup/wordpress-$(date +%F).sql
docker compose restart wordpress
curl -s localhost:8080/ | grep -o "<title>[^<]*"

# ── 4.5 Troubleshooting ─────────────────────────────────────
docker run -d --name crash --restart unless-stopped alpine:3.22 sh -c "echo starting; echo config missing >&2; exit 3"
docker ps -a --filter name=crash --format "{{.Names}} {{.Status}}"
docker inspect crash --format "exit={{.State.ExitCode}} restarts={{.RestartCount}}"
docker logs --tail 2 crash
docker run -d --name p1 -p 8080:80 nginx:1.30
docker run -d --name p2 -p 8080:80 nginx:1.30
sudo mkdir -p /srv/appdata && ls -ld /srv/appdata
docker run --rm -u 1001 -v /srv/appdata:/data alpine:3.22 touch /data/test
sudo chown 1001:1001 /srv/appdata && docker run --rm -u 1001 -v /srv/appdata:/data alpine:3.22 touch /data/test && ls -ln /srv/appdata
docker run --rm alpine:3.22 cat /etc/resolv.conf | grep -v "^#"
docker network create dnstest; docker run --rm --network dnstest busybox:1.37 cat /etc/resolv.conf | grep -v "^#"

# ── ดิสก์และการทำความสะอาด ──────────────────────────────────
docker system df
df -h /var/lib/docker | tail -1
