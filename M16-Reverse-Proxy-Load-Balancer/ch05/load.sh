#!/bin/bash
# /tmp/load.sh URL N  ยิง N คำขอขนาน 20 ไปที่ URL ผ่าน 127.0.0.1 แล้วนับรหัสผลลัพธ์
seq 1 "$2" | xargs -P 20 -I{} curl -sk -o /dev/null -w "%{http_code}\n" --resolve web.lab.test:443:127.0.0.1 "$1" | sort | uniq -c
