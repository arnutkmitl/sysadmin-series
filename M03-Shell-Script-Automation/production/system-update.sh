#!/usr/bin/env bash
# system-update.sh  อัปเดตแพ็กเกจ บันทึกรายการ และ reboot ถ้าจำเป็น (เมื่อ REBOOT=yes)
# ---- ตัวแปรที่ต้องแก้ ----
REBOOT=no                                  # yes = reboot อัตโนมัติเมื่อ kernel หรือ glibc ถูกอัปเดต
# shellcheck source=/usr/local/lib/sysadmin/lib.sh
source /usr/local/lib/sysadmin/lib.sh
need_root; lock; need_cmd dnf

log "เริ่ม dnf upgrade"
dnf -y upgrade --refresh >> "$LOG_FILE" 2>&1 || die "dnf upgrade ล้ม"
ok "อัปเดตเสร็จ ดูรายการได้ด้วย dnf history info last"

if dnf needs-restarting -r > /dev/null 2>&1; then
  ok "ไม่ต้อง reboot"
elif [[ $REBOOT == yes ]]; then
  warn "ต้อง reboot จะ reboot ใน 5 นาที"; notify "$(hostname) reboot หลังอัปเดต"
  shutdown -r +5 "system-update.sh: reboot หลังอัปเดตแพ็กเกจ"
else
  warn "ต้อง reboot แต่ REBOOT=no กรุณา reboot ด้วยมือ"; notify "$(hostname) รอ reboot"
fi
