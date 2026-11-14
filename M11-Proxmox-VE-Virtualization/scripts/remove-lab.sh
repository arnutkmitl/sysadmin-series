#!/usr/bin/env bash
# remove-lab.sh  ลบ Lab ที่สร้างด้วย build-lab.sh ทั้งชุด: เครื่องใน pool, ผู้ใช้, backup job และ pool
# ใช้: remove-lab.sh <pool>
# ⚠️ ลบเครื่องและงานของผู้เรียนทุกคนใน pool ทิ้งถาวร backup ใน local ยังอยู่
set -euo pipefail

POOL=${1:?ใช้: remove-lab.sh <pool>}

members=$(pvesh get "/pools/$POOL" --output-format json |
  python3 -c 'import sys, json
for m in json.load(sys.stdin)["members"]:
    if m["type"] in ("lxc", "qemu"):
        print(m["type"], m["vmid"])')

while read -r type id; do
  [ -n "$id" ] || continue
  cmd=qm; [ "$type" = lxc ] && cmd=pct
  [ "$($cmd status "$id" | awk '{print $2}')" = running ] && $cmd stop "$id"
  $cmd destroy "$id" --purge >/dev/null 2>&1
  echo "ลบ $type/$id"
done <<< "$members"

for user in $(pveum user list --output-format json |
    python3 -c "import sys, json
print(' '.join(u['userid'] for u in json.load(sys.stdin) if u['userid'].startswith('$POOL-')))"); do
  pveum user delete "$user" && echo "ลบผู้ใช้ $user"
done

pvesh delete "/cluster/backup/$POOL-daily" 2>/dev/null && echo "ลบ backup job $POOL-daily"
pvesh delete "/pools/$POOL" && echo "ลบ pool $POOL"
rm -f "/root/$POOL-accounts.csv"
