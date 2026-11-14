#!/usr/bin/env bash
# check-lab.sh  ตรวจ Lab ที่สร้างด้วย build-lab.sh ว่าพร้อมสอน
# ใช้: check-lab.sh <pool>
set -uo pipefail

POOL=${1:?ใช้: check-lab.sh <pool>}
pass=0 fail=0
ok()  { echo "  ผ่าน  $*"; pass=$((pass + 1)); }
bad() { echo "  ไม่ผ่าน $*"; fail=$((fail + 1)); }

members=$(pvesh get "/pools/$POOL" --output-format json 2>/dev/null |
  python3 -c 'import sys, json
for m in json.load(sys.stdin)["members"]:
    if m["type"] in ("qemu", "lxc"):
        print(m["type"], m["vmid"], m.get("name", ""))') || { echo "ไม่มี pool $POOL"; exit 1; }
acl=$(pveum acl list --output-format json)

echo "== pool $POOL"
while read -r type id name; do
  [ -n "$id" ] || continue
  cmd=qm; [ "$type" = lxc ] && cmd=pct
  if $cmd listsnapshot "$id" | grep -q lab-clean; then ok "$id $name มี snapshot lab-clean"
  else bad "$id $name ไม่มี snapshot lab-clean"; fi
  users=$(echo "$acl" | python3 -c "import sys, json
print(' '.join(a['ugid'] for a in json.load(sys.stdin) if a['path'] == '/vms/$id' and a['roleid'] == 'PVEVMUser'))")
  if [ -n "$users" ]; then ok "$id $name มีเจ้าของ $users"
  else bad "$id $name ไม่มีผู้ใช้ที่มีสิทธิ์ PVEVMUser"; fi
done <<< "$members"

if pvesh get "/cluster/backup/$POOL-daily" >/dev/null 2>&1; then ok "มี backup job $POOL-daily"
else bad "ไม่มี backup job $POOL-daily"; fi

used=$(lvs --noheadings -o data_percent pve/data | tr -d ' ')
if [ "${used%.*}" -lt 80 ]; then ok "thin pool ใช้ไป $used%"
else bad "thin pool ใช้ไป $used% เกิน 80%"; fi

echo "== ผ่าน $pass ไม่ผ่าน $fail"
[ "$fail" -eq 0 ]
