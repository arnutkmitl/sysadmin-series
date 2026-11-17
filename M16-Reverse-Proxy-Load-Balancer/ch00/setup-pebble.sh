#!/usr/bin/env bash
# /home/admin/setup-pebble.sh
# เตรียม Pebble (ACME server สำหรับทดสอบของ Let's Encrypt) และ DNS ทดสอบบน lb1 สำหรับเล่ม M16
# ใช้: sudo ./setup-pebble.sh [IP ที่ทุกชื่อใน lab.test ชี้ไป]   ค่าเริ่มต้น 192.168.56.71 (lb1)
# pebble-challtestsrv ตอบทุกชื่อด้วย IP เดียว Pebble จึงตรวจ HTTP-01 ที่ proxy เครื่องนั้นได้โดยไม่ต้องมี BIND
# ใช้กับ Lab เท่านั้น server จริงที่มีโดเมนใช้ Let's Encrypt ตรงโดยไม่ต้องมี Pebble
set -euo pipefail
VER=v2.10.3
DIR=/opt/pebble
TARGET=${1:-192.168.56.71}
RAW=https://raw.githubusercontent.com/letsencrypt/pebble/$VER/test
REL=https://github.com/letsencrypt/pebble/releases/download/$VER

mkdir -p "$DIR/certs"
command -v tar > /dev/null || dnf install -y -q tar   # Rocky แบบ Minimal ไม่มี tar
if [[ ! -x $DIR/pebble ]]; then
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT
  for b in pebble pebble-challtestsrv; do
    curl -sfL "$REL/$b-linux-amd64.tar.gz" | tar xz -C "$tmp"
    install -m 755 "$tmp/$b-linux-amd64/linux/amd64/$b" "$DIR/"
  done
  for f in certs/pebble.minica.pem certs/localhost/cert.pem certs/localhost/key.pem config/pebble-config.json; do
    curl -sfL -o "$DIR/certs/$(basename "$f")" "$RAW/$f"
  done
  sed -i -e "s|test/certs/localhost/cert.pem|$DIR/certs/cert.pem|" \
         -e "s|test/certs/localhost/key.pem|$DIR/certs/key.pem|" \
         -e 's|"httpPort": 5002|"httpPort": 80|' -e 's|"tlsPort": 5001|"tlsPort": 443|' \
         -e 's|"validityPeriod": 518400|"validityPeriod": 7776000|' \
         -e 's|"managementListenAddress": "0.0.0.0:15000"|"managementListenAddress": "127.0.0.1:15000"|' \
         "$DIR/certs/pebble-config.json"   # อายุ 90 วันเท่า Let's Encrypt
fi

# DNS ทดสอบ: ทุกชื่อตอบ $TARGET ฟังที่ 127.0.0.1:8053 ปิดส่วนตอบ challenge ของตัวเองเพราะ proxy ตอบแทน
cat > /etc/systemd/system/pebble-dns.service <<EOF
[Unit]
Description=Pebble test DNS: every name -> $TARGET (lab only)
After=network-online.target

[Service]
ExecStart=$DIR/pebble-challtestsrv -defaultIPv4 $TARGET -defaultIPv6 "" -dnsserver 127.0.0.1:8053 -http01 "" -https01 "" -tlsalpn01 "" -doh "" -management 127.0.0.1:8055
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Pebble เก็บบัญชีและใบรับรองไว้ในหน่วยความจำ root เปลี่ยนทุกครั้งที่เริ่มใหม่
cat > /etc/systemd/system/pebble.service <<EOF
[Unit]
Description=Pebble ACME test server (lab only)
After=network-online.target pebble-dns.service
Requires=pebble-dns.service

[Service]
Environment=PEBBLE_VA_NOSLEEP=1 PEBBLE_WFE_NONCEREJECT=0
ExecStart=$DIR/pebble -config $DIR/certs/pebble-config.json -dnsserver 127.0.0.1:8053
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable pebble-dns pebble > /dev/null 2>&1
systemctl restart pebble-dns pebble
for i in $(seq 1 20); do
  curl -s --cacert "$DIR/certs/pebble.minica.pem" https://localhost:15000/roots/0 > "$DIR/certs/lab-root.pem" && break
  sleep 1
done

# ให้เครื่องนี้เชื่อถือใบรับรองที่ Pebble ออก
cp "$DIR/certs/lab-root.pem" /etc/pki/ca-trust/source/anchors/pebble-lab-root.pem
update-ca-trust
systemctl is-active pebble-dns pebble
# Pebble เริ่มใหม่ = บัญชี ACME เดิมหาย ลงทะเบียนใหม่และแก้ไฟล์ renewal ให้ชี้บัญชีใหม่ (ทำเมื่อมี certbot แล้วเท่านั้น)
ACC=/etc/letsencrypt/accounts/localhost:14000/dir
if [[ -d $ACC ]] && command -v certbot > /dev/null; then
  rm -rf "$ACC"
  REQUESTS_CA_BUNDLE=$DIR/certs/pebble.minica.pem certbot register --server https://localhost:14000/dir     --agree-tos -m admin@lab.test --no-eff-email --non-interactive > /dev/null
  new=$(ls "$ACC")
  grep -l 'localhost:14000' /etc/letsencrypt/renewal/*.conf 2>/dev/null | xargs -r sed -i "s/^account = .*/account = $new/"
  echo "ลงทะเบียนบัญชี ACME ใหม่แล้ว ต่ออายุใบเดิมด้วย certbot renew --force-renewal --no-random-sleep-on-renew"
fi
echo "ทุกชื่อใน DNS ทดสอบชี้ไป $TARGET"
echo "root ของ Lab: $DIR/certs/lab-root.pem (คัดลอกไปเครื่องที่ต้องเชื่อถือ และ Host PC)"
echo "ACME directory: https://localhost:14000/dir (CA ของ Pebble เอง: $DIR/certs/pebble.minica.pem)"
