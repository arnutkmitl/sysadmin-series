#!/usr/bin/env bash
# reset-lab.sh  คืนทุกเครื่องใน pool กลับ snapshot เดียวกัน แล้วเปิดเครื่องที่เคยเปิดอยู่
# ใช้: reset-lab.sh <pool> [snapshot]   ตัวอย่าง: reset-lab.sh class101 lab-clean
# ⚠️ งานที่ผู้เรียนทำหลัง snapshot จะหายทั้งหมด
set -euo pipefail

POOL=${1:?ใช้: reset-lab.sh <pool> [snapshot]}
SNAP=${2:-lab-clean}

# สมาชิกของ pool ในรูป "lxc 301" หรือ "qemu 101" หนึ่งบรรทัดต่อเครื่อง
members=$(pvesh get "/pools/$POOL" --output-format json |
  python3 -c 'import sys, json
for m in json.load(sys.stdin)["members"]:
    if m["type"] in ("lxc", "qemu"):
        print(m["type"], m["vmid"])')

[ -n "$members" ] || { echo "pool $POOL ไม่มีเครื่อง"; exit 1; }

while read -r type id; do
  if [ "$type" = lxc ]; then cmd=pct; else cmd=qm; fi
  was=$($cmd status "$id" | awk '{print $2}')
  echo "== $type/$id ($was)"
  [ "$was" = running ] && $cmd stop "$id"
  $cmd rollback "$id" "$SNAP"
  # rollback ของ VM ที่ snapshot ไม่มี RAM จะทิ้งเครื่องไว้ในสถานะ stopped
  if [ "$was" = running ] && [ "$($cmd status "$id" | awk '{print $2}')" != running ]; then
    $cmd start "$id"
  fi
  echo "   -> $($cmd status "$id" | awk '{print $2}')"
done <<< "$members"
