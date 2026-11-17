#!/bin/bash
# /home/admin/monitoring/check-monitoring.sh
# ตรวจสุขภาพ Monitoring stack ของ M14 ทีละส่วน แสดง OK / WARN / FAIL
# exit 0 = ปกติ, 1 = มี WARN, 2 = มี FAIL (ใช้กับ cron หรือ CI ได้)
cd "$(dirname "$0")" || exit 2

PROM=http://localhost:9090
AM=http://localhost:9093
GRAFANA=http://localhost:3000
AUTH="admin:$(cat secrets/prometheus_password)"
WARN=0
FAIL=0

ok()   { printf '  [OK]   %s\n' "$1"; }
warn() { printf '  [WARN] %s\n' "$1"; WARN=$((WARN + 1)); }
fail() { printf '  [FAIL] %s\n' "$1"; FAIL=$((FAIL + 1)); }

# ถาม PromQL แล้วคืนค่าแถวแรก (ว่างถ้าไม่มีผล)
q() {
    curl -s -m 10 -u "$AUTH" "$PROM/api/v1/query" --data-urlencode "query=$1" |
        python3 -c 'import sys,json
r=json.load(sys.stdin)["data"]["result"]
print(r[0]["value"][1] if r else "")' 2>/dev/null
}

echo "== Containers"
for c in prometheus grafana alertmanager node-exporter cadvisor blackbox pushgateway; do
    s=$(docker inspect -f '{{.State.Status}}' "$c" 2>/dev/null)
    [ "$s" = running ] && ok "$c running" || fail "$c ${s:-ไม่มี container}"
done

echo "== Prometheus"
code=$(curl -s -m 5 -o /dev/null -w '%{http_code}' -u "$AUTH" "$PROM/-/ready")
[ "$code" = 200 ] && ok "ready" || fail "/-/ready ตอบ $code"
code=$(curl -s -m 5 -o /dev/null -w '%{http_code}' "$PROM/-/ready")
[ "$code" = 401 ] && ok "ไม่มีรหัสผ่านได้ 401" || warn "ไม่มีรหัสผ่านได้ $code (Basic Auth ปิดอยู่?)"
[ "$(q prometheus_config_last_reload_successful)" = 1 ] && ok "config ล่าสุดโหลดสำเร็จ" || fail "reload config ล่าสุดล้มเหลว"

down=$(curl -s -m 10 -u "$AUTH" "$PROM/api/v1/targets?state=active" | python3 -c 'import sys,json
t=json.load(sys.stdin)["data"]["activeTargets"]
bad=[x["labels"]["job"]+" "+x["labels"]["instance"] for x in t if x["health"]!="up"]
print(len(t)); print("\n".join(bad))')
total=$(echo "$down" | head -1)
bad=$(echo "$down" | tail -n +2 | sed '/^$/d')
if [ -z "$bad" ]; then
    ok "target ทั้งหมด $total ตัว UP"
else
    while read -r line; do fail "target DOWN: $line"; done <<< "$bad"
fi

ret=$(curl -s -m 5 -u "$AUTH" "$PROM/api/v1/status/flags" | python3 -c 'import sys,json
d=json.load(sys.stdin)["data"]
print(d["storage.tsdb.retention.time"], d["storage.tsdb.retention.size"])')
ok "retention: $ret"

series=$(q prometheus_tsdb_head_series)
ok "Time Series ใน head: ${series%.*}"

echo "== Alert"
firing=$(curl -s -m 10 -u "$AUTH" "$PROM/api/v1/alerts" | python3 -c 'import sys,json
a=[x for x in json.load(sys.stdin)["data"]["alerts"] if x["state"]=="firing"]
print("\n".join(x["labels"]["alertname"]+" ("+x["labels"].get("severity","-")+") "+x["labels"].get("instance","") for x in a))')
if [ -z "$firing" ]; then ok "ไม่มี Alert ที่ Firing"; else
    while read -r line; do warn "Firing: $line"; done <<< "$firing"; fi

echo "== Alertmanager"
code=$(curl -s -m 5 -o /dev/null -w '%{http_code}' "$AM/-/healthy")
[ "$code" = 200 ] && ok "healthy" || fail "/-/healthy ตอบ $code"
sil=$(curl -s -m 5 "$AM/api/v2/silences" | python3 -c 'import sys,json
print(sum(1 for s in json.load(sys.stdin) if s["status"]["state"]=="active"))')
[ "$sil" = 0 ] && ok "ไม่มี Silence ค้าง" || warn "มี Silence ที่ใช้งานอยู่ $sil รายการ"
nf=$(q 'sum(increase(alertmanager_notifications_failed_total[1h]))')
[ "${nf%.*}" = 0 ] && ok "ส่งข้อความไม่สำเร็จใน 1 ชั่วโมง: 0" || warn "ส่งข้อความไม่สำเร็จใน 1 ชั่วโมง: ${nf:-ไม่มีข้อมูล}"

echo "== Grafana"
h=$(curl -s -m 5 "$GRAFANA/api/health" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("database",""))' 2>/dev/null)
[ "$h" = ok ] && ok "database ok" || fail "api/health ตอบ ${h:-ไม่ได้}"

echo "== Backup และดิสก์"
age=$(q 'time() - backup_last_run_timestamp_seconds')
if [ -z "$age" ]; then warn "ไม่พบ backup_last_run_timestamp_seconds"
elif [ "${age%.*}" -gt 93600 ]; then fail "backup ล่าสุดเก่า $((${age%.*} / 3600)) ชั่วโมง"
else ok "backup ล่าสุดเมื่อ $((${age%.*} / 60)) นาทีก่อน"; fi
used=$(df --output=pcent / | tail -1 | tr -dc '0-9')
if [ "$used" -ge 90 ]; then fail "ดิสก์ / ใช้ $used%"
elif [ "$used" -ge 80 ]; then warn "ดิสก์ / ใช้ $used%"
else ok "ดิสก์ / ใช้ $used%"; fi

echo "== สรุป: FAIL $FAIL, WARN $WARN"
[ "$FAIL" -gt 0 ] && exit 2
[ "$WARN" -gt 0 ] && exit 1
exit 0
