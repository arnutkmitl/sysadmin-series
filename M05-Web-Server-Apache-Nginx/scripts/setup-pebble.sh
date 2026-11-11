#!/usr/bin/env bash
# setup-pebble.sh เตรียม Pebble (ACME server สำหรับทดสอบ) บนเครื่อง web สำหรับ Lab บทที่ 3
# ใช้: sudo ./setup-pebble.sh   แล้ว export REQUESTS_CA_BUNDLE=/opt/pebble/certs/pebble.minica.pem
# ใช้กับ Lab เท่านั้น server จริงที่มีโดเมนใช้ Let's Encrypt ตรงโดยไม่ต้องมี Pebble
set -euo pipefail
VER=v2.10.3
IP=${IP:-192.168.56.20}          # IP ที่ชื่อ *.lab.test ทุกชื่อชี้ไป
DIR=/opt/pebble
RAW=https://raw.githubusercontent.com/letsencrypt/pebble/$VER/test
REL=https://github.com/letsencrypt/pebble/releases/download/$VER

mkdir -p "$DIR/certs"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
for f in pebble pebble-challtestsrv; do
  curl -sfL "$REL/$f-linux-amd64.tar.gz" | tar xz -C "$tmp"
  install -m 755 "$tmp/$f-linux-amd64/linux/amd64/$f" "$DIR/"
done
for f in certs/pebble.minica.pem certs/localhost/cert.pem certs/localhost/key.pem config/pebble-config.json; do
  curl -sfL -o "$DIR/certs/$(basename "$f")" "$RAW/$f"
done
sed -i -e "s|test/certs/localhost/cert.pem|$DIR/certs/cert.pem|" \
       -e "s|test/certs/localhost/key.pem|$DIR/certs/key.pem|" \
       -e 's|"httpPort": 5002|"httpPort": 80|' -e 's|"tlsPort": 5001|"tlsPort": 443|' \
       -e 's|"validityPeriod": 518400|"validityPeriod": 7776000|' \
       "$DIR/certs/pebble-config.json"   # ทุก profile อายุ 90 วันเท่า Let's Encrypt

# DNS ทดสอบ ตอบทุกชื่อเป็น $IP และ Pebble ที่ใช้ DNS ตัวนี้ (หยุดเมื่อรีบูต)
systemctl reset-failed pebble-dns pebble 2>/dev/null || true
systemd-run --unit=pebble-dns "$DIR/pebble-challtestsrv" -defaultIPv4 "$IP" -defaultIPv6 "" \
  -http01 "" -https01 "" -tlsalpn01 "" -doh "" -dnsserver 127.0.0.1:8053 -management 127.0.0.1:8055
systemd-run --unit=pebble -E PEBBLE_VA_NOSLEEP=1 -E PEBBLE_WFE_NONCEREJECT=0 \
  "$DIR/pebble" -config "$DIR/certs/pebble-config.json" -dnsserver 127.0.0.1:8053
sleep 3

# ให้เครื่องนี้เชื่อถือใบรับรองที่ Pebble ออก (root เปลี่ยนทุกครั้งที่เริ่ม Pebble ใหม่)
curl -s --cacert "$DIR/certs/pebble.minica.pem" https://localhost:15000/roots/0 > "$DIR/certs/lab-root.pem"
cp "$DIR/certs/lab-root.pem" /etc/pki/ca-trust/source/anchors/pebble-lab-root.pem
update-ca-trust
systemctl is-active pebble pebble-dns

# Pebble เก็บบัญชีไว้ในหน่วยความจำ เริ่มใหม่หรือรีบูตแล้วบัญชีเดิมหาย
# ถ้าเคยขอใบรับรองไว้ ลงทะเบียนบัญชีใหม่และแก้ไฟล์ renewal ให้ชี้บัญชีใหม่
ACC=/etc/letsencrypt/accounts/localhost:14000/dir
if [[ -d $ACC ]] && command -v certbot > /dev/null; then
  rm -rf "$ACC"
  REQUESTS_CA_BUNDLE=$DIR/certs/pebble.minica.pem certbot register --server https://localhost:14000/dir \
    --agree-tos -m admin@lab.test --no-eff-email --non-interactive > /dev/null
  new=$(ls "$ACC")
  grep -l 'localhost:14000' /etc/letsencrypt/renewal/*.conf | xargs -r sed -i "s/^account = .*/account = $new/"
  echo "ลงทะเบียนบัญชีใหม่แล้ว ต่ออายุใบเดิมด้วย certbot renew --force-renewal"
fi
echo "พร้อมใช้: certbot ... --server https://localhost:14000/dir"
