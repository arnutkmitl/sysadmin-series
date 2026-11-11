#!/usr/bin/env bash
# ping-list.sh ping ทุก IP ในไฟล์ แล้วสรุปผล
LIST=${1:-ip-list.txt}
[[ -r $LIST ]] || { echo "อ่านไฟล์ $LIST ไม่ได้"; exit 2; }

up=0; down=0
while read -r ip name; do
  [[ -z $ip || $ip == \#* ]] && continue
  if ping -c 1 -W 1 "$ip" &>/dev/null; then
    echo "UP   $ip ${name:-}"; up=$((up + 1))
  else
    echo "DOWN $ip ${name:-}"; down=$((down + 1))
  fi
done < "$LIST"
echo "สรุป: UP $up / DOWN $down"
