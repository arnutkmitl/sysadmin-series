#!/usr/bin/env bash
# add-mailuser.sh เพิ่มผู้ใช้อีเมลแบบ virtual (Postfix + Dovecot) หรือเปลี่ยนรหัสผ่านของผู้ใช้เดิม
# รุ่นบทที่ 5: เขียนบรรทัดแบบ passwd ครบ 8 ช่องให้ userdb passwd-file และเก็บ quota เฉพาะคนไว้เมื่อเปลี่ยนรหัสผ่าน
# ใช้: sudo ./add-mailuser.sh somchai@example.com   แล้วพิมพ์รหัสผ่านสองครั้ง
set -euo pipefail
addr=${1,,}
[[ $addr =~ ^[a-z0-9._-]+@([a-z0-9.-]+)$ ]] || { echo "ใช้: $0 user@domain" >&2; exit 1; }
domain=${BASH_REMATCH[1]}
user=${addr%@*}
grep -qw "$domain" <(postconf -h virtual_mailbox_domains) || { echo "$domain ไม่อยู่ใน virtual_mailbox_domains" >&2; exit 1; }

read -rsp "รหัสผ่านของ $addr: " pw1; echo
read -rsp "พิมพ์อีกครั้ง: " pw2; echo
[[ $pw1 == "$pw2" ]] || { echo "รหัสผ่านไม่ตรงกัน" >&2; exit 1; }
(( ${#pw1} >= 10 )) || { echo "รหัสผ่านต้องยาวอย่างน้อย 10 ตัวอักษร" >&2; exit 1; }
hash=$(doveadm pw -s BLF-CRYPT -p "$pw1")

# Dovecot: แทนบรรทัดเดิมถ้ามี (เก็บช่องที่ 8 เช่น userdb_quota_rule ไว้) ไม่อย่างนั้นเพิ่มใหม่
touch /etc/dovecot/users
chown root:dovecot /etc/dovecot/users
chmod 640 /etc/dovecot/users
extra=$(grep "^$addr:" /etc/dovecot/users | cut -d: -f8- || true)
sed -i "/^${addr//./\.}:/d" /etc/dovecot/users
echo "$addr:$hash::::::$extra" >> /etc/dovecot/users

# Postfix: กล่องอีเมล และสิทธิ์ใช้ที่อยู่นี้เป็นผู้ส่ง
grep -q "^$addr[[:space:]]" /etc/postfix/vmailbox || printf '%-22s%s\n' "$addr" "$domain/$user/" >> /etc/postfix/vmailbox
touch /etc/postfix/sender_login
grep -q "^$addr[[:space:]]" /etc/postfix/sender_login || printf '%-22s%s\n' "$addr" "$addr" >> /etc/postfix/sender_login
postmap lmdb:/etc/postfix/vmailbox
postmap lmdb:/etc/postfix/sender_login
echo "พร้อมใช้: $addr"
