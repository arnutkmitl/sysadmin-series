#!/bin/bash
# งานบำรุงรักษาประจำสัปดาห์ ทำเฉพาะ database ที่เปิดอยู่บนเครื่องนี้
# MariaDB: อัปเดตสถิติของทุกตาราง  PostgreSQL: VACUUM และ ANALYZE ทุก database
set -euo pipefail

LOG=/var/log/db-maintenance.log
log() { echo "$(date '+%F %T') $*" >> "$LOG"; }

if systemctl is-active --quiet mariadb; then
    if mariadb-check --all-databases --analyze --silent; then
        log "mariadb analyze OK"
    else
        log "mariadb analyze FAILED"
    fi
fi

if systemctl is-active --quiet postgresql; then
    # standby รับคำสั่ง VACUUM ไม่ได้ ให้ข้ามไป
    if [ "$(runuser -u postgres -- psql -Atc 'SELECT pg_is_in_recovery()')" = "t" ]; then
        log "postgresql standby, skipped"
    elif runuser -u postgres -- vacuumdb --all --analyze --quiet; then
        log "postgresql vacuum+analyze OK"
    else
        log "postgresql vacuum+analyze FAILED"
    fi
fi
