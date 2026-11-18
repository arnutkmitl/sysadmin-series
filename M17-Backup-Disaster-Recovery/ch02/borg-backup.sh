#!/bin/bash
# borg-backup.sh: รันบน prod ด้วย root สร้าง archive ใหม่ใน repo บน bkp
# repo เป็น append-only จากฝั่ง prod การลบ archive เก่า (prune) ทำบน bkp เท่านั้น
set -euo pipefail
source /root/.config/borg-env

borg create --stats --compression zstd,3 \
     --exclude '/srv/files/*/tmp' \
     ::'{hostname}-{now:%Y-%m-%d_%H%M%S}' \
     /srv/files /srv/www /etc /var/backup/db /var/backup/docker
