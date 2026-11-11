#!/usr/bin/env bash
# check-sites.sh ตรวจรับโปรเจกต์ Multi-Site Web Server ทั้งสามเว็บ (รันบนเครื่อง web ด้วย sudo)
set -uo pipefail
SITES=(wp.lab.test static.lab.test app.lab.test)
WP=/var/www/wordpress
pass=0; fail=0

check() {                     # check "ชื่อข้อ" คำสั่ง...
  local name=$1; shift
  if "$@" > /dev/null 2>&1; then echo "PASS $name"; ((pass++)); else echo "FAIL $name"; ((fail++)); fi
}
code()   { curl -s -o /dev/null -w '%{http_code}' "$@"; }
header() { curl -sI "https://$1/" | grep -qi "^$2:"; }
cert_ok() {                   # ใบรับรองยังเหลือมากกว่า 7 วัน
  echo | openssl s_client -connect "$1:443" -servername "$1" 2>/dev/null \
    | openssl x509 -noout -checkend 604800
}

check "nginx -t ผ่าน" nginx -t
for s in "${SITES[@]}"; do
  check "$s HTTP ส่งต่อไป HTTPS (301)" test "$(code "http://$s/")" = 301
  check "$s HTTPS ตอบ 200"             test "$(code "https://$s/")" = 200
  check "$s มี Strict-Transport-Security" header "$s" strict-transport-security
  check "$s มี X-Content-Type-Options"  header "$s" x-content-type-options
  check "$s ใบรับรองเหลือเกิน 7 วัน"      cert_ok "$s"
done
check "static มี Content-Security-Policy" header static.lab.test content-security-policy
check "app ได้ X-Forwarded-Proto https" \
  bash -c 'curl -s https://app.lab.test/ | grep -q "\"proto\":\"https\""'
check "WordPress ล็อกอินได้ (302 ไป wp-admin)" bash -c \
  "curl -s -o /dev/null -w '%{redirect_url}' -b 'wordpress_test_cookie=WP%20Cookie%20check' \
   -d 'log=wpadmin&pwd=${WP_PASS:?ตั้ง WP_PASS ก่อนรัน}&testcookie=1' https://wp.lab.test/wp-login.php \
   | grep -q '/wp-admin/'"
slug="check-$(date +%s)"
check "WordPress สร้างโพสต์ได้" bash -c "cd $WP && sudo -u apache /usr/local/bin/wp post create \
   --post_title='$slug' --post_name='$slug' --post_status=publish"
check "โพสต์ใหม่เปิดได้" test "$(code "https://wp.lab.test/$slug/")" = 200
check "certbot-renew.timer ทำงาน" systemctl is-active certbot-renew.timer
check "ไม่เปิด TLS ต่ำกว่า 1.2" bash -c \
  '! nmap --script ssl-enum-ciphers -p 443 wp.lab.test | grep -qE "TLSv1\.[01]:"'

echo "ผ่าน $pass จาก $((pass + fail)) ข้อ"
[[ $fail -eq 0 ]]
