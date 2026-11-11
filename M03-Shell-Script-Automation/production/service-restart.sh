#!/usr/bin/env bash
# service-restart.sh  ตรวจ service ที่กำหนด ถ้าไม่ทำงานให้ restart แล้วตรวจซ้ำ
# ---- ตัวแปรที่ต้องแก้ ----
SERVICES=(crond chronyd)                   # เช่น (nginx mariadb php-fpm)
# shellcheck source=/usr/local/lib/sysadmin/lib.sh
source /usr/local/lib/sysadmin/lib.sh
need_root; lock

failed=0
for svc in "${SERVICES[@]}"; do
  systemctl is-active --quiet "$svc" && continue
  warn "$svc ไม่ทำงาน กำลัง restart"
  systemctl restart "$svc" || true
  sleep 3
  if systemctl is-active --quiet "$svc"; then
    ok "$svc กลับมาทำงานแล้ว"; notify "restart $svc สำเร็จ"
  else
    warn "$svc restart ไม่สำเร็จ"; notify "restart $svc ล้มเหลว ต้องตรวจด้วยมือ"
    failed=$((failed + 1))
  fi
done
if (( failed > 0 )); then exit 1; fi
log "ตรวจ ${#SERVICES[@]} service เสร็จ"
