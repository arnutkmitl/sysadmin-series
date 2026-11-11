#!/usr/bin/env bash
# top-failed.sh แสดง IP ที่ล็อกอิน SSH ผิดมากที่สุด
TOP=${1:-10}
LOG=${2:-/var/log/secure}
printf "%-7s %s\n" "COUNT" "IP"
sudo grep 'sshd.*Failed password' "$LOG" \
  | grep -oE 'from [0-9.]+' | awk '{print $2}' \
  | sort | uniq -c | sort -rn | head -n "$TOP" \
  | awk '{printf "%-7s %s\n", $1, $2}'
