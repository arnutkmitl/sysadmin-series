#!/bin/bash
# /usr/local/bin/backup-configs.sh
# สำรอง Config สำคัญของ server ลง /backup และเก็บไว้ KEEP_DAYS วัน (M01 บทที่ 6)

umask 077                      # ไฟล์ที่สร้างใหม่ให้ root อ่านได้คนเดียว (มี /etc/shadow)

BACKUP_DIR="/backup"
KEEP_DAYS=30
DATE=$(date +%Y%m%d-%H%M)
BACKUP_FILE="${BACKUP_DIR}/server-config-${DATE}.tar.gz"

log() { echo "$(date '+%F %T') $*"; }

mkdir -p "${BACKUP_DIR}"
chmod 700 "${BACKUP_DIR}"

# -C / ทำให้ชื่อในชุดเป็น etc/... และไม่มีคำเตือน Removing leading '/'
if ! tar czf "${BACKUP_FILE}" -C / \
    etc/ssh/sshd_config \
    etc/ssh/sshd_config.d \
    etc/firewalld \
    etc/selinux/config \
    etc/sudoers \
    etc/sudoers.d \
    etc/dnf/automatic.conf \
    etc/NetworkManager/system-connections \
    etc/cron.d \
    etc/hostname \
    etc/hosts \
    etc/passwd \
    etc/group \
    etc/shadow \
    etc/gshadow \
    home/admin/.ssh/authorized_keys; then
    log "ERROR สร้าง ${BACKUP_FILE} ไม่สำเร็จ" >&2
    rm -f "${BACKUP_FILE}"
    exit 1
fi

log "OK ${BACKUP_FILE} ขนาด $(du -h "${BACKUP_FILE}" | cut -f1)"
log "SHA256 $(sha256sum "${BACKUP_FILE}" | cut -d' ' -f1)"

# Rotation: ลบชุดที่เก่ากว่า KEEP_DAYS วัน และพิมพ์ชื่อไฟล์ที่ลบลง Log
find "${BACKUP_DIR}" -name 'server-config-*.tar.gz' -mtime +"${KEEP_DAYS}" -print -delete
