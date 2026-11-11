#!/usr/bin/env bash
# ============================================================
# template.sh  ต้นแบบ Script ระดับ Production
# ผู้เขียน: admin  แก้ล่าสุด: 2026-11-11
# ใช้: sudo ./template.sh
# ============================================================
# shellcheck disable=SC2317,SC2329  # ฟังก์ชันที่ trap เรียก ShellCheck มองไม่เห็น
set -euo pipefail

# ---- Config ----
LOG_DIR=${LOG_DIR:-/var/log/scripts}

# ==== ส่วนกลาง: เหมือนกันทุก Script ====
SCRIPT_NAME=$(basename "$0" .sh)
LOG_FILE="$LOG_DIR/$SCRIPT_NAME.log"
_log() {
  local level=$1; shift
  local line
  line="[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*"
  { echo "$line" >> "$LOG_FILE"; } 2>/dev/null || true
  [[ -t 1 ]] || return 0          # cron ไม่มีจอ ไม่ต้องพิมพ์ซ้ำ
  case $level in
    OK)    echo -e "\033[0;32m$line\033[0m" ;;
    WARN)  echo -e "\033[0;33m$line\033[0m" ;;
    ERROR) echo -e "\033[0;31m$line\033[0m" >&2 ;;
    *)     echo "$line" ;;
  esac
}
log()  { _log INFO "$@"; }
ok()   { _log OK "$@"; }
warn() { _log WARN "$@"; }
die()  { _log ERROR "$@"; exit 1; }
need_root() { [[ $EUID -eq 0 ]] || die "ต้องรันด้วย sudo"; }
need_cmd()  { local c; for c in "$@"; do command -v "$c" &>/dev/null || die "ไม่พบคำสั่ง $c"; done; }
lock() {
  exec 9>"/run/$SCRIPT_NAME.lock"
  flock -n 9 || die "$SCRIPT_NAME กำลังรันอยู่แล้ว"
}
TMP_DIR=$(mktemp -d)
cleanup() {
  local rc=$?
  rm -rf "$TMP_DIR"
  [[ $rc -eq 0 ]] || _log INFO "จบด้วย exit code $rc"
  exit "$rc"
}
trap cleanup EXIT
trap 'warn "ถูกยกเลิก"; exit 130' INT TERM
# ==== จบส่วนกลาง ====

# ---- Logic หลัก ----
need_root
mkdir -p "$LOG_DIR"
lock
need_cmd df awk
log "เริ่มทำงาน"
df -h / | tee "$TMP_DIR/df.txt" > /dev/null
ok "อ่านดิสก์แล้ว $(wc -l < "$TMP_DIR/df.txt") บรรทัด"
exit 0
