#!/usr/bin/env bash
# backup-config.sh  สำรองโฟลเดอร์ config เป็น tar.gz และลบชุดที่เก่ากว่า KEEP_DAYS วัน
# ---- ตัวแปรที่ต้องแก้ ----
SOURCES=(/etc /usr/local/bin /usr/local/lib/sysadmin)   # โฟลเดอร์ที่สำรอง
DEST=/backup/config                        # ปลายทาง
KEEP_DAYS=14                               # เก็บย้อนหลังกี่วัน
# shellcheck source=/usr/local/lib/sysadmin/lib.sh
source /usr/local/lib/sysadmin/lib.sh
need_root; lock; need_cmd tar

mkdir -p "$DEST"
file="config-$(hostname -s)-$(date +%Y%m%d-%H%M).tar.gz"
rc=0
tar czf "$TMP_DIR/$file" -C / "${SOURCES[@]#/}" 2>"$TMP_DIR/tar.err" || rc=$?
(( rc <= 1 )) || die "tar ล้ม exit code $rc: $(head -1 "$TMP_DIR/tar.err")"
tar tzf "$TMP_DIR/$file" > /dev/null || die "ไฟล์ backup เสีย"
mv "$TMP_DIR/$file" "$DEST/"
ok "สร้าง $DEST/$file ขนาด $(du -h "$DEST/$file" | cut -f1)"

deleted=$(find "$DEST" -name 'config-*.tar.gz' -mtime +"$KEEP_DAYS" -print -delete | wc -l)
log "ลบ backup ที่เก่ากว่า $KEEP_DAYS วัน $deleted ไฟล์"
