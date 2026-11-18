#!/bin/bash
# s3-undelete.sh: รันบน bkp ด้วยผู้ใช้ที่มี key ของ admin ลบ delete marker ทุกอันใน bucket
# object ที่ถูก "ลบ" โดยไม่ระบุ version จะกลับมาให้เห็นตามเดิม เพราะข้อมูลจริงยังอยู่ใน version ก่อนหน้า
# ใช้: s3-undelete.sh restic-prod
set -euo pipefail
BUCKET=${1:?ระบุชื่อ bucket}
E="--endpoint-url http://192.168.56.86:8333"

aws $E s3api list-object-versions --bucket "$BUCKET" \
    --query 'DeleteMarkers[].[Key,VersionId]' --output text |
while read -r key vid; do
  [ "$key" = "None" ] && continue
  aws $E s3api delete-object --bucket "$BUCKET" --key "$key" --version-id "$vid" >/dev/null
  echo "restored $key"
done
echo "objects now: $(aws $E s3 ls "s3://$BUCKET" --recursive | wc -l)"
