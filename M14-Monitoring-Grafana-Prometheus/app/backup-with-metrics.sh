#!/bin/bash
# /usr/local/bin/backup-with-metrics.sh
# สำรองฐานข้อมูล แล้วส่งผลไป Pushgateway ให้ Prometheus รู้ว่างานล่าสุดสำเร็จเมื่อไร
set -o pipefail
PUSH=http://192.168.56.55:9091/metrics/job/backup/instance/$(hostname -s)
OUT=/var/backup/db-$(date +%F).sql.gz
START=$(date +%s)

mkdir -p /var/backup
if mariadb-dump --all-databases --single-transaction | gzip > "$OUT"; then
    STATUS=1
else
    STATUS=0
fi
END=$(date +%s)

cat <<METRICS | curl -s --netrc-file /etc/backup/pushgateway.netrc --data-binary @- "$PUSH"
# TYPE backup_last_run_timestamp_seconds gauge
backup_last_run_timestamp_seconds $END
# TYPE backup_success gauge
backup_success $STATUS
# TYPE backup_duration_seconds gauge
backup_duration_seconds $((END - START))
# TYPE backup_size_bytes gauge
backup_size_bytes $(stat -c %s "$OUT" 2>/dev/null || echo 0)
METRICS
