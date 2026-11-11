#!/usr/bin/env bash
# disk-check.sh ตัดสินระดับการใช้ดิสก์ของ /
USE=$(df --output=pcent / | tail -1 | tr -dc '0-9')
if [[ $USE -ge 90 ]]; then
  echo "CRITICAL: / ใช้ไป $USE%"
elif [[ $USE -ge 80 ]]; then
  echo "WARNING: / ใช้ไป $USE%"
else
  echo "OK: / ใช้ไป $USE%"
fi
