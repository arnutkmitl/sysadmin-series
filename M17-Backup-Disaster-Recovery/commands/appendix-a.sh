#!/usr/bin/env bash
# ภาคผนวก ก เครื่องมือ backup และคำสั่งกู้คืน
# SysAdmin Pocket Series M17 Backup & Disaster Recovery
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── rsync snapshot บน bkp ───────────────────────────────────
# บนเครื่อง bkp
sudo ls /srv/backup/rsync/prod/
sudo cp -a /srv/backup/rsync/prod/2026-11-18_0623/files/hr/doc-050.txt /tmp/
scp -P 2222 /tmp/doc-050.txt admin@192.168.56.85:/tmp/
# บนเครื่อง prod
sudo install -o root -g root -m 644 /tmp/doc-050.txt /srv/files/hr/

# ── BorgBackup ──────────────────────────────────────────────
# บนเครื่อง prod
sudo bash -c 'source /root/.config/borg-env; borg list --short'
sudo bash -c 'source /root/.config/borg-env; cd / && borg extract ::prod-2026-11-18_0628 srv/files/hr/doc-050.txt'
sudo bash -c 'source /root/.config/borg-env; borg mount :: /mnt/borg'
sudo bash -c 'source /root/.config/borg-env; borg umount /mnt/borg'

# ── restic ──────────────────────────────────────────────────
# บนเครื่อง prod
sudo bash -c 'source /root/.config/restic/env; restic snapshots --compact'
sudo bash -c 'source /root/.config/restic/env; restic restore latest --target /tmp/r --include /srv/files/hr/doc-050.txt'
sudo bash -c 'source /root/.config/restic/env; restic restore latest --no-lock --target / --include /srv/files'
sudo bash -c 'source /root/.config/restic/s3-env; restic restore latest --target /tmp/r'

# ── MariaDB ─────────────────────────────────────────────────
# บนเครื่อง prod
sudo bash -c 'zstdcat /var/backup/db/shop-2026-11-18_0639.sql.zst | mariadb --init-command="SET sql_log_bin=0"'
sudo mariadb-binlog --database=shop --start-position=481 --stop-position=59653 /var/lib/mysql/binlog.000001 | sudo mariadb --init-command="SET sql_log_bin=0"

# ── PostgreSQL ──────────────────────────────────────────────
# บนเครื่อง prod
sudo -u postgres createdb ledger_test
sudo bash -c 'sudo -u postgres pg_restore -d ledger_test < /var/backup/db/ledger-2026-11-18_0639.dump'

# ── Docker stack ────────────────────────────────────────────
# บนเครื่อง prod
sudo /usr/local/sbin/docker-restore.sh /var/backup/docker/wordpress-2026-11-18_0648

# ── S3 ที่ถูกลบด้วย delete marker ───────────────────────────
# บนเครื่อง bkp
./s3-undelete.sh restic-prod
# บนเครื่อง prod
sudo bash -c 'source /root/.config/restic/s3-env; restic unlock --remove-all; restic check'
