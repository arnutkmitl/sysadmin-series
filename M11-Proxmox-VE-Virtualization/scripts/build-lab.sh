#!/usr/bin/env bash
# build-lab.sh  สร้าง Lab หนึ่งห้อง: pool, VM ของผู้เรียนจาก template, ผู้ใช้, สิทธิ์, snapshot และ backup ทุกคืน
# ใช้: build-lab.sh <pool> <template-id> <จำนวนผู้เรียน> <vmid แรก> <octet แรกของ IP>
# ตัวอย่าง: build-lab.sh linux101 9000 10 401 111   -> VM 401-410 ที่ 10.10.10.111-120
# รหัสผ่านของผู้เรียนเขียนลง /root/<pool>-accounts.csv (อ่านได้เฉพาะ root)
set -euo pipefail

POOL=$1 TPL=$2 N=$3 FIRST=$4 OCT=$5
CSV=/root/$POOL-accounts.csv

pvesh get "/pools/$POOL" >/dev/null 2>&1 || pvesh create /pools --poolid "$POOL" --comment "Lab $POOL"
umask 077
echo "user,vmid,ip,password" > "$CSV"

for i in $(seq 1 "$N"); do
  id=$((FIRST + i - 1))
  ip=10.10.10.$((OCT + i - 1))
  name=$(printf 'stu%02d' "$i")
  user=$POOL-$name@pve
  pass=$(openssl rand -base64 9)

  qm clone "$TPL" "$id" --name "$name" --pool "$POOL" >/dev/null
  qm set "$id" --ciuser student --cipassword "$pass" \
    --ipconfig0 "ip=$ip/24,gw=10.10.10.1" --nameserver 10.10.10.2 --searchdomain lab.test >/dev/null
  qm snapshot "$id" lab-clean --description "clean state for $POOL" >/dev/null 2>&1

  pveum user add "$user" --password "$pass" --comment "$POOL" 2>/dev/null ||
    pvesh set /access/password --userid "$user" --password "$pass"
  pveum acl modify "/vms/$id" --users "$user" --roles PVEVMUser

  echo "$user,$id,$ip,$pass" >> "$CSV"
  echo "$name  vm $id  $ip"
done

pvesh get "/cluster/backup/$POOL-daily" >/dev/null 2>&1 ||
  pvesh create /cluster/backup --id "$POOL-daily" --schedule 02:00 --pool "$POOL" \
    --storage local --mode snapshot --compress zstd --prune-backups keep-last=3

echo "บัญชีผู้เรียน: $CSV"
