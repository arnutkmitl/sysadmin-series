#!/usr/bin/env bash
# user-audit.sh  รายงานผู้ใช้ที่มีสิทธิ์ sudo ผู้ที่ไม่เคยล็อกอิน และรหัสผ่านใกล้หมดอายุ
# ---- ตัวแปรที่ต้องแก้ ----
SUDO_GROUP=wheel                           # Ubuntu ใช้ sudo
EXPIRE_WARN=14                             # เตือนเมื่อรหัสผ่านหมดอายุภายในกี่วัน
# shellcheck source=/usr/local/lib/sysadmin/lib.sh
source /usr/local/lib/sysadmin/lib.sh
need_root

log "ผู้ใช้ในกลุ่ม $SUDO_GROUP: $(getent group "$SUDO_GROUP" | cut -d: -f4)"
while read -r u; do warn "บัญชี $u ไม่มีรหัสผ่าน"; done < <(awk -F: '$2 == "" {print $1}' /etc/shadow)

today=$(date +%s)
while IFS=: read -r user _ uid _ _ _ shell; do
  (( uid >= 1000 && uid < 65534 )) || continue
  [[ $shell == */nologin || $shell == */false ]] && continue
  if ! last -n1 "$user" | grep -q "^$user "; then warn "$user ไม่มีประวัติล็อกอินใน wtmp"; fi
  exp=$(chage -l "$user" | awk -F': ' '/^Password expires/ {print $2}')
  if [[ $exp != never ]]; then
    days=$(( ($(date -d "$exp" +%s) - today) / 86400 ))
    if (( days <= EXPIRE_WARN )); then warn "รหัสผ่านของ $user หมดอายุในอีก $days วัน"; fi
  fi
done < /etc/passwd
ok "ตรวจผู้ใช้เสร็จ"
