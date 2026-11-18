#!/bin/bash
# restic-backup.sh: รันบน prod ด้วย root ส่ง snapshot ใหม่ไป rest-server บน bkp
# rest-server เปิด --append-only ฝั่ง prod จึงสั่ง forget/prune ไม่ได้ การลบ snapshot เก่าทำบน bkp
set -euo pipefail
source /root/.config/restic/env

restic backup --tag daily --exclude '/srv/files/*/tmp' /srv/files /srv/www /etc /var/backup/db /var/backup/docker
