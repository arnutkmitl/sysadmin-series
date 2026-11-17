#!/bin/bash
# /etc/letsencrypt/renewal-hooks/deploy/haproxy.sh
# certbot เรียกหลังได้ใบรับรองใหม่ทุกครั้ง: รวม fullchain + privkey เป็นไฟล์เดียวที่ HAProxy อ่านได้ แล้ว reload
set -euo pipefail
dir=/etc/haproxy/certs
install -d -m 700 "$dir"
name=$(basename "$RENEWED_LINEAGE")
umask 077
cat "$RENEWED_LINEAGE/fullchain.pem" "$RENEWED_LINEAGE/privkey.pem" > "$dir/$name.pem.tmp"
mv "$dir/$name.pem.tmp" "$dir/$name.pem"
restorecon -q "$dir/$name.pem" || true
systemctl reload haproxy
