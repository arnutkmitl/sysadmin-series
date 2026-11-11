#!/usr/bin/env bash
# func-demo.sh ตัวอย่างฟังก์ชันสองแบบ
is_up() {                       # ส่ง exit code
  ping -c 1 -W 1 "$1" &>/dev/null
}
disk_use() {                    # ส่งค่าด้วย echo
  local mount=$1
  df --output=pcent "$mount" | tail -1 | tr -dc '0-9'
}

is_up 192.168.56.20 && echo "client ตอบสนอง"
echo "/boot ใช้ไป $(disk_use /boot)%"
