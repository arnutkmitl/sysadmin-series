#!/usr/bin/env bash
# getopts-demo.sh รับ -v และ -f แล้วตามด้วยชื่อ service
VERBOSE=0; FORCE=0
while getopts "vf" opt; do
  case $opt in
    v) VERBOSE=1 ;;
    f) FORCE=1 ;;
    *) echo "Usage: $0 [-v] [-f] <service>"; exit 2 ;;
  esac
done
shift $((OPTIND - 1))
echo "service=${1:-ไม่ระบุ} verbose=$VERBOSE force=$FORCE"
