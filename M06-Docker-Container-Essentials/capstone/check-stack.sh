#!/bin/bash
# check-stack.sh: ตรวจรับโปรเจกต์จบเล่ม M06
# ใช้: cd ~/capstone && ./check-stack.sh
# รันซ้ำหลัง docker compose down และ up ได้ ข้อ 8 ตรวจว่าโน้ตเดิมยังอยู่

cd "$(dirname "$0")" || exit 1
PORT=$(grep -E '^HTTP_PORT=' .env 2>/dev/null | cut -d= -f2)
URL="http://localhost:${PORT:-80}"
PROJECT=$(basename "$PWD")
pass=0
fail=0

# รอให้ทุก service ที่มี healthcheck พร้อม ไม่เกิน 90 วินาที
for i in $(seq 18); do
    docker compose ps --format '{{.Health}}' | grep -qE 'starting|unhealthy' || break
    sleep 5
done

check() {
    local name="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        printf 'PASS  %s\n' "$name"
        pass=$((pass + 1))
    else
        printf 'FAIL  %s\n' "$name"
        fail=$((fail + 1))
    fi
}

state() {
    docker compose ps --format '{{.Service}} {{.State}} {{.Health}}' | grep -q "^$1 $2"
}

# 1-5 ทุก service ทำงาน และตัวที่มี healthcheck ต้อง healthy
for svc in proxy app db redis; do
    check "$svc running and healthy" state "$svc" "running healthy"
done
check "portainer running" state portainer running

# 6-9 เส้นทางผ่าน reverse proxy
check "GET / via proxy returns app json" bash -c "curl -fsS $URL/ | grep -q '\"app\":\"capstone\"'"
check "visits counter increases" bash -c \
    "a=\$(curl -fsS $URL/ | grep -o 'visits\":[0-9]*' | cut -d: -f2); b=\$(curl -fsS $URL/ | grep -o 'visits\":[0-9]*' | cut -d: -f2); [ \"\$b\" -gt \"\$a\" ]"
if curl -fsS "$URL/notes" | grep -q 'capstone-check'; then
    echo "INFO  note from previous run found (data persisted)"
else
    curl -fsS -X POST -H 'Content-Type: application/json' -d '{"body":"capstone-check"}' "$URL/notes" >/dev/null
    echo "INFO  created test note, run again after down/up to check persistence"
fi
check "note stored in MySQL" bash -c "curl -fsS $URL/notes | grep -q capstone-check"
check "health endpoint ok" bash -c "curl -fsS $URL/health | grep -qx ok"

# 10-13 สิ่งที่ไม่ควรเปิด
check "proxy hides nginx version" bash -c "curl -sI $URL/ | grep -i '^server:' | grep -vq '[0-9]'"
check "db and redis not published" bash -c \
    "for p in 'db 3306' 'redis 6379'; do case \"\$(docker compose port \$p 2>/dev/null)\" in ''|:0) ;; *) exit 1;; esac; done"
check "backend network is internal" bash -c \
    "[ \"\$(docker network inspect ${PROJECT}_backend --format '{{.Internal}}')\" = true ]"
check "portainer bound to 127.0.0.1 only" bash -c \
    "docker compose port portainer 9443 | grep -q '^127.0.0.1:'"

# 14-16 ขีดจำกัดและ log
check "memory limit on every service" bash -c \
    "for c in \$(docker compose ps -q); do [ \"\$(docker inspect -f '{{.HostConfig.Memory}}' \$c)\" -gt 0 ] || exit 1; done"
check "cpu limit on app" bash -c \
    "[ \"\$(docker inspect -f '{{.HostConfig.NanoCpus}}' \$(docker compose ps -q app))\" -gt 0 ]"
check "log rotation (max-size) on app" bash -c \
    "docker inspect -f '{{.HostConfig.LogConfig.Config}}' \$(docker compose ps -q app) | grep -q max-size"

# 17-18 ข้อมูลอยู่ใน volume
check "volume db_data exists" docker volume inspect "${PROJECT}_db_data"
check "redis appendonly enabled" bash -c \
    "docker compose exec -T redis redis-cli config get appendonly | grep -qx yes"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
