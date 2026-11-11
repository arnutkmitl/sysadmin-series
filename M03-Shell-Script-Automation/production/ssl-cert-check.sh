#!/usr/bin/env bash
# ssl-cert-check.sh  ตรวจวันหมดอายุของ certificate จากเว็บไซต์หรือไฟล์ แจ้งเตือนล่วงหน้า
# ---- ตัวแปรที่ต้องแก้ ----
TARGETS=(www.kmitl.ac.th:443 github.com:443 /etc/pki/tls/certs/localhost.crt)
WARN_DAYS=30
# shellcheck source=/usr/local/lib/sysadmin/lib.sh
source /usr/local/lib/sysadmin/lib.sh
need_cmd openssl

expiring=0
for t in "${TARGETS[@]}"; do
  if [[ $t == /* ]]; then
    [[ -r $t ]] || { warn "อ่านไฟล์ $t ไม่ได้"; continue; }
    end=$(openssl x509 -in "$t" -noout -enddate | cut -d= -f2)
  else
    end=$(echo | timeout 10 openssl s_client -servername "${t%:*}" -connect "$t" 2>/dev/null \
          | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2) || true
    [[ -n $end ]] || { warn "เชื่อมต่อ $t ไม่ได้"; continue; }
  fi
  days=$(( ($(date -d "$end" +%s) - $(date +%s)) / 86400 ))
  if (( days <= WARN_DAYS )); then
    warn "$t หมดอายุในอีก $days วัน ($end)"; notify "$t หมดอายุในอีก $days วัน"
    expiring=$((expiring + 1))
  else ok "$t เหลือ $days วัน"; fi
done
if (( expiring > 0 )); then exit 1; fi
