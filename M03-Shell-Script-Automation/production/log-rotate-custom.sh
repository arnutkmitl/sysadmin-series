#!/usr/bin/env bash
# log-rotate-custom.sh  บีบอัด log เก่าและลบ log ที่เกินกำหนด สำหรับแอปที่ไม่รองรับ logrotate
# ---- ตัวแปรที่ต้องแก้ ----
APP_LOG_DIR=/opt/myapp/logs                # โฟลเดอร์ log ของแอป
COMPRESS_AFTER=1                           # บีบอัดไฟล์ .log ที่ไม่ถูกแก้มากี่วัน
DELETE_AFTER=30                            # ลบไฟล์ .gz ที่เก่ากว่ากี่วัน
# shellcheck source=/usr/local/lib/sysadmin/lib.sh
source /usr/local/lib/sysadmin/lib.sh
need_root; lock

[[ -d $APP_LOG_DIR ]] || die "ไม่พบโฟลเดอร์ $APP_LOG_DIR"
compressed=0
while IFS= read -r -d '' f; do
  gzip "$f" && compressed=$((compressed + 1))
done < <(find "$APP_LOG_DIR" -name '*.log' -mmin +$((COMPRESS_AFTER * 1440)) -print0)
deleted=$(find "$APP_LOG_DIR" -name '*.log.gz' -mtime +"$DELETE_AFTER" -print -delete | wc -l)
ok "บีบอัด $compressed ไฟล์ ลบ $deleted ไฟล์ ใน $APP_LOG_DIR"
