#!/usr/bin/env bash
# port-check.sh ตรวจว่าพอร์ตของเครื่องปลายทางเปิดอยู่หรือไม่
[[ $# -lt 2 ]] && { echo "Usage: $0 <host> <port>"; exit 2; }
HOST=$1
PORT=$2
if timeout 3 bash -c "echo > /dev/tcp/$HOST/$PORT" 2>/dev/null; then
  echo "$HOST:$PORT เปิด"
else
  echo "$HOST:$PORT ปิดหรือติดต่อไม่ได้"
  exit 1
fi
