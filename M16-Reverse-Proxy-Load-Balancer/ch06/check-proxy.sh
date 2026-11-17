#!/bin/bash
# /home/admin/check-proxy.sh  ตรวจระบบ Reverse Proxy ของบทที่ 6 ทั้งชุด รันบน lb1 หรือเครื่องใดก็ได้ในวง Lab
# ผล: บรรทัดละการตรวจ PASS/WARN/FAIL และสรุปท้ายรายงาน ออกด้วยรหัส 1 เมื่อมี FAIL
VIP=192.168.56.75
LBS="192.168.56.71 192.168.56.72"
DOMAINS="web.lab.test api.lab.test app.lab.test"
CA=${CA:-/opt/pebble/certs/lab-root.pem}
WARN_DAYS=${WARN_DAYS:-20}
pass=0; warn=0; fail=0
ok()   { echo "PASS  $*"; pass=$((pass+1)); }
wn()   { echo "WARN  $*"; warn=$((warn+1)); }
bad()  { echo "FAIL  $*"; fail=$((fail+1)); }

# 1) VIP ตอบ และรู้ว่าเครื่องไหนถือ VIP อยู่
holder=$(curl -s -m 3 --cacert "$CA" --resolve web.lab.test:443:$VIP -o /dev/null -D - https://web.lab.test/health | awk -F': ' 'tolower($1)=="x-lb"{print $2}' | tr -d '\r')
[[ -n $holder ]] && ok "VIP $VIP ตอบจาก $holder" || bad "VIP $VIP ไม่ตอบ"

# 2) ทุกโดเมนผ่าน VIP ได้ 200 ด้วยใบรับรองที่ตรวจได้ และเหลืออายุพอ
for d in $DOMAINS; do
  code=$(curl -s -m 5 --cacert "$CA" --resolve $d:443:$VIP -o /dev/null -w '%{http_code}' https://$d/)
  [[ $code == 200 ]] && ok "https://$d -> 200" || bad "https://$d -> $code"
  days=$(python3 - "$d" "$CA" <<'PY'
import socket, ssl, sys, time
d, ca = sys.argv[1], sys.argv[2]
ctx = ssl.create_default_context(cafile=ca)
with socket.create_connection(("192.168.56.75", 443), timeout=5) as s, ctx.wrap_socket(s, server_hostname=d) as t:
    print(int((ssl.cert_time_to_seconds(t.getpeercert()["notAfter"]) - time.time()) // 86400))
PY
)
  if [[ -z $days ]]; then bad "$d อ่านอายุใบรับรองไม่ได้"
  elif (( days < WARN_DAYS )); then wn "$d ใบรับรองเหลือ $days วัน"
  else ok "$d ใบรับรองเหลือ $days วัน"; fi
done

# 3) proxy ทั้งสองเครื่องทำงาน และเห็นหลังบ้านครบ (อ่านจาก /metrics ที่ไม่ต้องใช้รหัสผ่าน)
for lb in $LBS; do
  m=$(curl -s -m 3 http://$lb:8404/metrics) || true
  if [[ -z $m ]]; then bad "HAProxy บน $lb ไม่ตอบ /metrics"; continue; fi
  down=$(echo "$m" | awk '/^haproxy_server_status\{/ && /state="DOWN"/ && $2==1' | sed -E 's/.*proxy="([^"]+)",server="([^"]+)".*/\1\/\2/' | grep -v acme_back | tr '\n' ' ')
  [[ -z $down ]] && ok "HAProxy บน $lb เห็นหลังบ้านครบ" || wn "HAProxy บน $lb: DOWN $down"
done

echo "สรุป: PASS $pass  WARN $warn  FAIL $fail"
(( fail == 0 ))
