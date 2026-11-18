#!/bin/bash
# prune-on-bkp.sh: รันบน bkp ด้วย root ลบ archive/snapshot เก่าตามนโยบายเก็บของเล่ม
# prod ลบเองไม่ได้ เพราะ Borg และ rest-server เปิด append-only ไว้
set -euo pipefail
KEEP=(--keep-daily 7 --keep-weekly 4 --keep-monthly 6)

sudo -u backup env BORG_PASSCOMMAND="cat /home/backup/.borg-pass-prod" \
     borg prune --list "${KEEP[@]}" /srv/backup/borg/prod
sudo -u backup env BORG_PASSCOMMAND="cat /home/backup/.borg-pass-prod" \
     borg compact /srv/backup/borg/prod

sudo -u restic restic -r /srv/backup/restic/prod --password-file /etc/restic/prod.pass \
     forget "${KEEP[@]}" --prune
