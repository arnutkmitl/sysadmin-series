#!/usr/bin/env bash
# check-services.sh ตรวจ service จาก argument (ค่าเริ่มต้น sshd crond chronyd)
GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
if [[ $# -gt 0 ]]; then
  SERVICES=("$@")
else
  SERVICES=(sshd crond chronyd)
fi

failed=0
for svc in "${SERVICES[@]}"; do
  if systemctl is-active --quiet "$svc"; then
    echo -e "${GREEN}[OK]${NC}   $svc"
  else
    echo -e "${RED}[FAIL]${NC} $svc"
    failed=$((failed + 1))
  fi
done
echo "ล้ม $failed จาก ${#SERVICES[@]} service"
[[ $failed -eq 0 ]]
