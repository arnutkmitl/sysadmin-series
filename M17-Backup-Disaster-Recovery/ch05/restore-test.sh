#!/bin/bash
# restore-test.sh: รันบน prod ด้วย root จาก restore-test.timer ทุกสัปดาห์
# พิสูจน์ว่า backup กู้ได้จริง: กู้ฐานข้อมูลลงฐานชั่วคราว อ่านข้อมูลจริงบางส่วนของ restic
# และกู้ไฟล์สุ่ม 20 ไฟล์มาเทียบ checksum กับไฟล์บนเครื่อง
set -uo pipefail
PROM=/var/lib/node_exporter/textfile/restore_test.prom
LINE_API=${LINE_API:-https://api.line.me/v2/bot/message/push}
fail=0

/usr/local/sbin/db-verify.sh || fail=1

source /root/.config/restic/env
restic check --read-data-subset=10% || fail=1

# กู้ไฟล์สุ่มจาก snapshot ล่าสุดไปที่โฟลเดอร์ชั่วคราว แล้วเทียบกับไฟล์จริงที่ยังไม่ถูกแก้หลังเวลา snapshot
tmp=$(mktemp -d)
snap_time=$(restic snapshots latest --json | python3 -c "import sys,json;print(json.load(sys.stdin)[0]['time'][:19])")
mapfile -t files < <(find /srv/files -type f ! -newermt "$snap_time" | shuf -n 20)
restic restore latest --target "$tmp" $(printf -- '--include %s ' "${files[@]}") >/dev/null || fail=1
for f in "${files[@]}"; do
  cmp -s "$f" "$tmp$f" || { echo "[FAIL] ไฟล์ไม่ตรง $f"; fail=1; }
done
rm -rf "$tmp"
echo "restored and compared ${#files[@]} files"

{
  echo "# TYPE restore_test_last_status gauge"
  echo "restore_test_last_status $fail"
  echo "# TYPE restore_test_last_run_timestamp_seconds gauge"
  echo "restore_test_last_run_timestamp_seconds $(date +%s)"
} > "$PROM.tmp" && mv "$PROM.tmp" "$PROM"

if [ "$fail" != 0 ]; then
  curl -s -m 10 -o /dev/null -X POST "$LINE_API" \
       -H "Authorization: Bearer $(cat /root/.line-token)" -H "Content-Type: application/json" \
       -d "$(printf '{"to":"%s","messages":[{"type":"text","text":"[FAIL] ทดสอบกู้คืนของ %s ไม่ผ่าน ดู journalctl -u restore-test"}]}' "$(cat /root/.line-target)" "$(hostname -s)")"
fi
exit $fail
