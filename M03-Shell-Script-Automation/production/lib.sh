# lib.sh  ส่วนกลางของ Script ทุกตัวในบทที่ 6 ติดตั้งที่ /usr/local/lib/sysadmin/lib.sh
# ใช้: source /usr/local/lib/sysadmin/lib.sh ต่อจากส่วน Config ของแต่ละ Script
# shellcheck shell=bash disable=SC2317,SC2329
set -euo pipefail
LOG_DIR=${LOG_DIR:-/var/log/scripts}
MAIL_TO=${MAIL_TO:-}                       # ว่าง = ไม่ส่งอีเมล
SCRIPT_NAME=$(basename "$0" .sh)
LOG_FILE="$LOG_DIR/$SCRIPT_NAME.log"

_log() {
  local level=$1; shift
  local line
  line="[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*"
  { echo "$line" >> "$LOG_FILE"; } 2>/dev/null || true
  [[ -t 1 ]] || return 0
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
die()  { _log ERROR "$@"; notify "ERROR: $*"; exit 1; }
notify() {
  [[ -n $MAIL_TO ]] || return 0
  echo "$*" | mailx -s "[$(hostname)] $SCRIPT_NAME" "$MAIL_TO" || _log WARN "ส่งอีเมลไม่สำเร็จ"
}
need_root() { [[ $EUID -eq 0 ]] || die "ต้องรันด้วย sudo"; mkdir -p "$LOG_DIR"; }
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
