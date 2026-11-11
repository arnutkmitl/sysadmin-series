#!/usr/bin/env bash
# disk-alert.sh  แจ้งเตือนเมื่อ filesystem ใดใช้เกิน THRESHOLD
# ---- ตัวแปรที่ต้องแก้ ----
THRESHOLD=80                               # % ที่เริ่มเตือน
MAIL_TO=""                                 # อีเมลผู้รับ ว่าง = เขียน log อย่างเดียว
# shellcheck source=/usr/local/lib/sysadmin/lib.sh
source /usr/local/lib/sysadmin/lib.sh
need_root; lock

over=0
while read -r pct mnt; do
  pct=${pct%\%}
  if (( pct >= THRESHOLD )); then
    warn "$mnt ใช้ไป $pct% (เกณฑ์ $THRESHOLD%)"
    notify "$mnt ใช้ไป $pct% บน $(hostname)"
    over=$((over + 1))
  fi
done < <(df --output=pcent,target -x tmpfs -x devtmpfs -x efivarfs | tail -n +2)

if (( over > 0 )); then exit 1; fi
ok "ทุก filesystem ต่ำกว่า $THRESHOLD%"
