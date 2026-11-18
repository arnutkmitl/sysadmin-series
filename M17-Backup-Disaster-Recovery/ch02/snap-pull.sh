#!/bin/bash
# snap-pull.sh: รันบน bkp ด้วย root ดึง /srv ของ prod มาเป็น snapshot ใหม่ทุกครั้งที่รัน
# ไฟล์ที่ไม่เปลี่ยนจาก snapshot ก่อนหน้าเป็น hard link จึงไม่กินพื้นที่ซ้ำ
# เก็บ snapshot ล่าสุดไว้ KEEP ชุด ชุดที่เก่ากว่านั้นถูกลบ
set -euo pipefail

SRC_HOST=192.168.56.85
DEST=/srv/backup/rsync/prod
KEEP=14
SSH="ssh -p 2222 -i /root/.ssh/id_pull"

now=$(date +%Y-%m-%d_%H%M)
mkdir -p "$DEST"
link=()
[ -d "$DEST/latest" ] && link=(--link-dest="$DEST/latest")

# rrsync บน prod ผูก root ไว้ที่ /srv แบบอ่านอย่างเดียว ปลายทางจึงอ้างเป็น path ใต้ /srv
rsync -aHAX --numeric-ids --delete "${link[@]}" -e "$SSH" \
      "root@$SRC_HOST:" "$DEST/$now.partial/"
mv "$DEST/$now.partial" "$DEST/$now"
ln -sfn "$now" "$DEST/latest"

# เก็บ KEEP ชุดล่าสุด
ls -1d "$DEST"/20* | head -n -"$KEEP" | xargs -r rm -rf
echo "snapshot $now done"
