#!/usr/bin/env bash
# backup-mail.sh สำรองกล่องอีเมลและไฟล์ตั้งค่าทั้งหมดของ mail server ลงไฟล์เดียวต่อวัน
# ใช้: sudo ./backup-mail.sh [โฟลเดอร์ปลายทาง]   ค่าเริ่มต้น /var/backups/mail  เก็บ 14 วัน
set -euo pipefail
DEST=${1:-/var/backups/mail}
KEEP_DAYS=14
STAMP=$(date +%Y%m%d-%H%M)
install -d -m 700 "$DEST"

# ไฟล์ที่ต้องมีเพื่อสร้าง server ใหม่ได้ทั้งเครื่อง (ข้ามรายการที่ไม่มีในเครื่องนี้)
PATHS=(/var/mail/vhosts /etc/postfix /etc/dovecot /etc/opendkim /etc/opendkim.conf
       /etc/opendmarc.conf /etc/opendmarc /etc/mail/spamassassin/local.cf /etc/sysconfig/spamass-milter
       /etc/letsencrypt /etc/roundcubemail /var/lib/roundcubemail /etc/nginx/conf.d /var/www/autoconfig)
EXIST=()
for p in "${PATHS[@]}"; do [[ -e $p ]] && EXIST+=("$p"); done

# ฐานข้อมูล SQLite ของ Roundcube ต้องคัดลอกด้วย .backup ไม่ใช่ cp ขณะใช้งาน
if [[ -f /var/lib/roundcubemail/roundcube.db ]] && command -v sqlite3 > /dev/null; then
  sqlite3 /var/lib/roundcubemail/roundcube.db ".backup '$DEST/roundcube-$STAMP.db'"
  chmod 600 "$DEST/roundcube-$STAMP.db"
fi

tar --selinux --acls --xattrs -czf "$DEST/mail-$STAMP.tar.gz" "${EXIST[@]}" 2> >(grep -v "Removing leading" >&2)
chmod 600 "$DEST/mail-$STAMP.tar.gz"
find "$DEST" -name 'mail-*.tar.gz' -mtime +$KEEP_DAYS -delete
find "$DEST" -name 'roundcube-*.db' -mtime +$KEEP_DAYS -delete
ls -lh "$DEST/mail-$STAMP.tar.gz"
