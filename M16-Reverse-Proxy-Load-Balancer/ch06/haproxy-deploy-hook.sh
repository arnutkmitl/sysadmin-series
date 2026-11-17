#!/bin/bash
# /etc/letsencrypt/renewal-hooks/deploy/haproxy.sh  (บน lb1, บทที่ 6)
# certbot เรียกหลังได้ใบรับรองใหม่: รวม fullchain + privkey ให้ HAProxy บน lb1 แล้วส่งสำเนาไป lb2
set -euo pipefail
dir=/etc/haproxy/certs
install -d -m 700 "$dir"
name=$(basename "$RENEWED_LINEAGE")
umask 077
cat "$RENEWED_LINEAGE/fullchain.pem" "$RENEWED_LINEAGE/privkey.pem" > "$dir/$name.pem.tmp"
mv "$dir/$name.pem.tmp" "$dir/$name.pem"
restorecon -q "$dir/$name.pem" || true
systemctl reload haproxy
ssh -i /root/.ssh/certsync -p 2222 -o BatchMode=yes certsync@192.168.56.72 "$name.pem" < "$dir/$name.pem"
