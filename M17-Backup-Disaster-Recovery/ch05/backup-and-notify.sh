#!/bin/bash
# backup-and-notify.sh: รันบน prod ด้วย root จาก backup.timer ทุกคืน
# ทำทุกงาน backup ตามลำดับ บันทึกผลเป็น metric ให้ node_exporter และแจ้ง LINE เมื่อมีงานล้มเหลว
set -uo pipefail
LOG=/var/log/backup/backup-$(date +%F).log
PROM=/var/lib/node_exporter/textfile/backup.prom
LINE_API=${LINE_API:-https://api.line.me/v2/bot/message/push}
LINE_TO=$(sed -n 1p /root/.line-target)
LINE_TOKEN=$(sed -n 1p /root/.line-token)
mkdir -p /var/log/backup "$(dirname "$PROM")"

declare -A status
run() {  # run <ชื่องาน> <คำสั่ง...>: ล้มเหลวงานเดียวไม่หยุดงานที่เหลือ
  local job=$1; shift
  echo "=== $(date '+%F %T') $job" >> "$LOG"
  # งานที่ค้างนานเกิน 1 ชั่วโมงนับว่าล้มเหลว restic ที่ต่อ server ไม่ได้จะลองซ้ำเองนานราว 15 นาที
  if timeout --kill-after=1m 1h "$@" >> "$LOG" 2>&1; then status[$job]=0; else status[$job]=1; fi
  echo "=== $job exit ${status[$job]}" >> "$LOG"
}

run db_dump       /usr/local/sbin/db-dump.sh
run docker        /usr/local/sbin/docker-backup.sh
run restic_rest   /usr/local/sbin/restic-backup.sh
run restic_s3     bash -c 'source /root/.config/restic/s3-env && restic backup --tag offsite /srv/files /srv/www /etc /var/backup/db /var/backup/docker'
run borg          /usr/local/sbin/borg-backup.sh

# metric: เขียนไฟล์ชั่วคราวแล้ว mv เพื่อไม่ให้ node_exporter อ่านไฟล์ที่เขียนไม่เสร็จ
now=$(date +%s)
{
  echo "# HELP backup_last_status 0 = สำเร็จ, 1 = ล้มเหลว ในรอบล่าสุด"
  echo "# TYPE backup_last_status gauge"
  for j in "${!status[@]}"; do echo "backup_last_status{task=\"$j\"} ${status[$j]}"; done
  echo "# HELP backup_last_success_timestamp_seconds เวลาที่งานสำเร็จครั้งล่าสุด"
  echo "# TYPE backup_last_success_timestamp_seconds gauge"
  for j in "${!status[@]}"; do
    old=$(grep -s "backup_last_success_timestamp_seconds{task=\"$j\"}" "$PROM" | awk '{print $2}')
    if [ "${status[$j]}" = 0 ]; then t=$now; else t=${old:-0}; fi
    echo "backup_last_success_timestamp_seconds{task=\"$j\"} $t"
  done
} > "$PROM.tmp" && mv "$PROM.tmp" "$PROM"

failed=$(for j in "${!status[@]}"; do [ "${status[$j]}" != 0 ] && echo "$j"; done | sort | tr '\n' ' ')
if [ -n "$failed" ]; then
  msg="[FAIL] backup ของ $(hostname -s) ล้มเหลว: ${failed}ดู $LOG"
else
  msg="[OK] backup ของ $(hostname -s) สำเร็จครบ ${#status[@]} งาน $(date '+%F %H:%M')"
fi
curl -s -m 10 -o /dev/null -X POST "$LINE_API" \
     -H "Authorization: Bearer $LINE_TOKEN" -H "Content-Type: application/json" \
     -d "$(printf '{"to":"%s","messages":[{"type":"text","text":"%s"}]}' "$LINE_TO" "$msg")"
echo "$msg" >> "$LOG"
[ -z "$failed" ]
