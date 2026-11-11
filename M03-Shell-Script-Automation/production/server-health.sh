#!/usr/bin/env bash
# server-health.sh  ตรวจ load, RAM, ดิสก์, service และพอร์ต แล้วสรุปผลลง log
# ---- ตัวแปรที่ต้องแก้ ----
DISK_LIMIT=85                              # % ดิสก์ที่ถือว่าผิดปกติ
RAM_MIN=10                                 # % RAM available ต่ำสุดที่ยอมรับ
SERVICES=(sshd crond chronyd firewalld)    # service ที่ต้อง active
PORTS=(2222)                               # พอร์ต TCP ที่ต้องเปิดรอ
# shellcheck source=/usr/local/lib/sysadmin/lib.sh
source /usr/local/lib/sysadmin/lib.sh
need_root; lock

problems=0
cores=$(nproc)
load=$(cut -d' ' -f1 /proc/loadavg)
if (( $(echo "$load > $cores" | bc) )); then
  warn "Load $load เกินจำนวน core ($cores)"; problems=$((problems + 1))
else ok "Load $load (core $cores)"; fi

ram=$(free | awk '/^Mem:/ {printf "%d", $7 * 100 / $2}')
if (( ram < RAM_MIN )); then warn "RAM available เหลือ $ram%"; problems=$((problems + 1))
else ok "RAM available $ram%"; fi

while read -r pct mnt; do
  pct=${pct%\%}
  if (( pct >= DISK_LIMIT )); then warn "ดิสก์ $mnt ใช้ $pct%"; problems=$((problems + 1))
  else ok "ดิสก์ $mnt ใช้ $pct%"; fi
done < <(df --output=pcent,target -x tmpfs -x devtmpfs -x efivarfs | tail -n +2)

for svc in "${SERVICES[@]}"; do
  if systemctl is-active --quiet "$svc"; then ok "service $svc active"
  else warn "service $svc ไม่ทำงาน"; problems=$((problems + 1)); fi
done
for port in "${PORTS[@]}"; do
  if ss -Htln "sport = :$port" | grep -q .; then ok "พอร์ต $port เปิดรอ"
  else warn "พอร์ต $port ไม่เปิด"; problems=$((problems + 1)); fi
done

if (( problems > 0 )); then notify "พบปัญหา $problems รายการ ดู $LOG_FILE"; exit 1; fi
ok "ปกติทุกรายการ"
