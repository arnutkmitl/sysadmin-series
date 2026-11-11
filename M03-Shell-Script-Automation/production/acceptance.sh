#!/usr/bin/env bash
# acceptance.sh ตรวจรับ Server Automation Suite (รันด้วย sudo)
SCRIPTS=(server-health disk-alert backup-config backup-database log-rotate-custom service-restart)
check() { if eval "$2" &>/dev/null; then echo "PASS $1"; else echo "FAIL $1"; fi; }

for s in "${SCRIPTS[@]}"; do
  f=/usr/local/bin/$s.sh
  check "$s shellcheck"    "shellcheck -x $f"
  check "$s รันด้วยมือ"     "$f"
  check "$s มี log"         "test -s /var/log/scripts/$s.log"
  check "$s อยู่ใน cron"    "grep -q ' $s.sh' /etc/cron.d/server-scripts"
done
check "lib.sh มี set -euo pipefail" "grep -q '^set -euo pipefail' /usr/local/lib/sysadmin/lib.sh"
check "lib.sh มี flock"             "grep -q 'flock -n' /usr/local/lib/sysadmin/lib.sh"
check "logrotate ผ่าน"              "logrotate -d /etc/logrotate.d/scripts"
check "มี README.md"                "test -s /usr/local/bin/README.md"
