#!/bin/bash
# setup-bkp.sh: เตรียมเครื่อง bkp (Rocky Linux 10) ให้รับ backup จาก prod
# ผู้ใช้ backup ไม่มีรหัสผ่าน ใช้ได้เฉพาะ SSH key ที่จำกัดคำสั่งไว้ใน authorized_keys
set -euo pipefail

dnf -y -q install epel-release
dnf -y -q install rsync borgbackup restic tar zstd

useradd --create-home --shell /bin/bash backup 2>/dev/null || true
passwd -l backup >/dev/null
# /srv/backup เป็นของ root ส่วนโฟลเดอร์ย่อยเป็นของผู้ใช้ที่เขียนลงไปเท่านั้น
install -d -m 755 /srv/backup
install -d -m 700 -o root -g root /srv/backup/rsync
install -d -m 700 -o backup -g backup /srv/backup/borg
install -d -m 700 -o backup -g backup /home/backup/.ssh
install -m 755 /usr/share/doc/rsync/support/rrsync /usr/local/bin/rrsync
echo "bkp ready: $(df -h /srv/backup | tail -1)"
