#!/usr/bin/env bash
# trap-demo.sh ไฟล์ชั่วคราวถูกลบเสมอ แม้กด Ctrl+C
set -euo pipefail
TMP=$(mktemp)
trap 'rm -f "$TMP"; echo "ลบ $TMP แล้ว"' EXIT
trap 'echo "ถูกยกเลิก"; exit 130' INT
echo "ทำงานกับ $TMP"
sleep 30
