#!/usr/bin/env bash
# setup-pebble.sh เตรียม Pebble (ACME server สำหรับทดสอบ) บนเครื่อง sec1 สำหรับเล่ม M10
# ใช้: sudo ./setup-pebble.sh   แล้ว export REQUESTS_CA_BUNDLE=/opt/pebble/certs/pebble.minica.pem
# ต่างจาก M05: Pebble ถาม DNS จาก BIND บนเครื่องนี้ (127.0.0.1:53) จึงตรวจ DNS-01 ของ zone lab.test ได้จริง
# ใช้กับ Lab เท่านั้น server จริงที่มีโดเมนใช้ Let's Encrypt ตรงโดยไม่ต้องมี Pebble
set -euo pipefail
VER=v2.10.3
DIR=/opt/pebble
RAW=https://raw.githubusercontent.com/letsencrypt/pebble/$VER/test
REL=https://github.com/letsencrypt/pebble/releases/download/$VER

mkdir -p "$DIR/certs"
command -v tar > /dev/null || dnf install -y -q tar   # Rocky แบบ minimal ไม่มี tar
if [[ ! -x $DIR/pebble ]]; then
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT
  curl -sfL "$REL/pebble-linux-amd64.tar.gz" | tar xz -C "$tmp"
  install -m 755 "$tmp/pebble-linux-amd64/linux/amd64/pebble" "$DIR/"
  for f in certs/pebble.minica.pem certs/localhost/cert.pem certs/localhost/key.pem config/pebble-config.json; do
    curl -sfL -o "$DIR/certs/$(basename "$f")" "$RAW/$f"
  done
  sed -i -e "s|test/certs/localhost/cert.pem|$DIR/certs/cert.pem|" \
         -e "s|test/certs/localhost/key.pem|$DIR/certs/key.pem|" \
         -e 's|"httpPort": 5002|"httpPort": 80|' -e 's|"tlsPort": 5001|"tlsPort": 443|' \
         -e 's|"validityPeriod": 518400|"validityPeriod": 7776000|' \
         -e 's|"listenAddress": "0.0.0.0:14000"|"listenAddress": "127.0.0.1:14000"|' \
         -e 's|"managementListenAddress": "0.0.0.0:15000"|"managementListenAddress": "127.0.0.1:15000"|' \
         "$DIR/certs/pebble-config.json"   # ทุก profile อายุ 90 วันเท่า Let's Encrypt
fi

# Pebble เป็น service ถาวร เปิดเองหลังรีบูต แต่เก็บบัญชีและใบรับรองไว้ในหน่วยความจำ
cat > /etc/systemd/system/pebble.service <<EOF
[Unit]
Description=Pebble ACME test server (lab only)
After=network-online.target named.service

[Service]
Environment=PEBBLE_VA_NOSLEEP=1 PEBBLE_WFE_NONCEREJECT=0
ExecStart=$DIR/pebble -config $DIR/certs/pebble-config.json -dnsserver 127.0.0.1:53
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable pebble >/dev/null 2>&1
systemctl restart pebble
for i in $(seq 1 20); do
  curl -s --cacert "$DIR/certs/pebble.minica.pem" https://localhost:15000/roots/0 > "$DIR/certs/lab-root.pem" && break
  sleep 1
done

# ให้เครื่องนี้เชื่อถือใบรับรองที่ Pebble ออก (root เปลี่ยนทุกครั้งที่เริ่ม Pebble ใหม่)
cp "$DIR/certs/lab-root.pem" /etc/pki/ca-trust/source/anchors/pebble-lab-root.pem
update-ca-trust
systemctl is-active pebble

# บัญชีเดิมหายเมื่อ Pebble เริ่มใหม่ ลงทะเบียนใหม่และแก้ไฟล์ renewal ให้ชี้บัญชีใหม่
ACC=/etc/letsencrypt/accounts/localhost:14000/dir
if [[ -d $ACC ]] && command -v certbot > /dev/null; then
  rm -rf "$ACC"
  REQUESTS_CA_BUNDLE=$DIR/certs/pebble.minica.pem certbot register --server https://localhost:14000/dir \
    --agree-tos -m admin@lab.test --no-eff-email --non-interactive > /dev/null
  new=$(ls "$ACC")
  grep -l 'localhost:14000' /etc/letsencrypt/renewal/*.conf 2>/dev/null | xargs -r sed -i "s/^account = .*/account = $new/"
  echo "ลงทะเบียนบัญชีใหม่แล้ว ต่ออายุใบเดิมด้วย certbot renew --force-renewal"
fi
echo "root ของ Lab อยู่ที่ $DIR/certs/lab-root.pem คัดลอกไปเครื่อง attacker ด้วย"
echo "พร้อมใช้: certbot ... --server https://localhost:14000/dir"
