#!/usr/bin/env bash
# บทที่ 4 Docker และสำเนา offsite ที่ ransomware ลบไม่ได้
# SysAdmin Pocket Series M17 Backup & Disaster Recovery
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── WordPress บน prod ───────────────────────────────────────
# บนเครื่อง prod
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
sudo dnf -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl enable --now docker
docker --version; docker compose version
sudo install -d -m 750 /opt/wordpress && sudo install -m 644 compose.yaml /opt/wordpress/
sudo bash -c 'umask 077; echo DB_PASSWORD=$(head -c 18 /dev/urandom | base64 | tr -d /+=) > /opt/wordpress/.env'
sudo docker compose --project-directory /opt/wordpress up -d
sudo firewall-cmd --permanent --add-port=8080/tcp && sudo firewall-cmd --reload
sudo bash -c 'source /opt/wordpress/.env; W="docker run --rm --network wordpress_default --volumes-from wordpress-wordpress-1 -e WORDPRESS_DB_HOST=db -e WORDPRESS_DB_USER=wordpress -e WORDPRESS_DB_PASSWORD=$DB_PASSWORD -e WORDPRESS_DB_NAME=wordpress wordpress:cli"
$W wp core install --url=http://192.168.56.85:8080 --title="ร้านค้าตัวอย่าง M17" --admin_user=wpadmin --admin_password=รหัสผ่านของคุณ --admin_email=admin@lab.local --skip-email
$W wp post create --post_title="ประกาศวันหยุดสิ้นปี" --post_content="ร้านปิด 31 ธันวาคม เปิดตามปกติ 2 มกราคม" --post_status=publish'

# ── Lab 4.1 สำรอง ลบทิ้ง แล้วกู้กลับ ────────────────────────
# บนเครื่อง prod
sudo install -m 750 docker-backup.sh /usr/local/sbin/ && time sudo /usr/local/sbin/docker-backup.sh
# ⚠️ `docker compose down -v` ลบ volume ของ stack ทั้งหมดและกู้คืนไม่ได้นอกจากจาก backup ใช้เพื่อจำลองเหตุการณ์ใน Lab เท่านั้น
B=$(sudo ls -1d /var/backup/docker/wordpress-* | tail -1)
sudo docker compose --project-directory /opt/wordpress down -v
sudo rm -rf /opt/wordpress
curl -s -o /dev/null -w "site %{http_code}\n" localhost:8080/
time sudo /usr/local/sbin/docker-restore.sh $B
curl -s localhost:8080/ | grep -o "ประกาศวันหยุดสิ้นปี" | head -1
sudo /usr/local/sbin/docker-restore.sh $B; echo rc=$?

# ── ติดตั้งบน bkp ───────────────────────────────────────────
# บนเครื่อง bkp
curl -sSLO https://github.com/seaweedfs/seaweedfs/releases/download/4.54/linux_amd64.tar.gz
curl -sSL https://github.com/seaweedfs/seaweedfs/releases/download/4.54/linux_amd64.tar.gz.md5 -o s.md5
echo "$(cut -d' ' -f1 s.md5)  linux_amd64.tar.gz" | md5sum -c
tar xzf linux_amd64.tar.gz && sudo install -m 755 weed /usr/local/bin/weed
weed version | head -1
sudo useradd --system --home /srv/backup/seaweed --shell /sbin/nologin seaweed
sudo install -d -o seaweed -g seaweed -m 700 /srv/backup/seaweed
sudo install -d -m 750 -g seaweed /etc/seaweedfs && sudo install -m 640 -g seaweed s3.json /etc/seaweedfs/
sudo install -m 644 seaweedfs.service /etc/systemd/system/ && sudo systemctl daemon-reload
sudo systemctl enable --now seaweedfs
sudo firewall-cmd --permanent --add-rich-rule='rule family=ipv4 source address=192.168.56.85 port port=8333 protocol=tcp accept'
sudo firewall-cmd --reload
ss -ltn | grep -E ":(8333|8888|9333) "

# ── bucket ที่เปิด object lock ──────────────────────────────
# บนเครื่อง bkp
sudo dnf -y install awscli2
E="--endpoint-url http://192.168.56.86:8333"
aws $E s3api create-bucket --bucket restic-prod --object-lock-enabled-for-bucket
aws $E s3api put-object-lock-configuration --bucket restic-prod --object-lock-configuration '{"ObjectLockEnabled":"Enabled","Rule":{"DefaultRetention":{"Mode":"COMPLIANCE","Days":7}}}'
aws $E s3api get-bucket-versioning --bucket restic-prod

# ── 4.3 restic ไป S3 ────────────────────────────────────────
# บนเครื่อง prod
sudo bash -c 'umask 077; printf "%s\n%s\n" PROD... secret... > /root/.restic-s3-key'
sudo install -m 600 restic-s3-env /root/.config/restic/s3-env
sudo bash -c 'source /root/.config/restic/s3-env; restic init'
sudo bash -c 'source /root/.config/restic/s3-env; restic backup --tag offsite /srv/files /srv/www /etc /var/backup/db /var/backup/docker' | tail -2

# ── ผู้บุกรุกใช้ key ของ prod ลบ S3 ─────────────────────────
# บนเครื่อง prod
sudo dnf -y install awscli2
sudo bash -c 'source /root/.config/restic/s3-env; export AWS_DEFAULT_REGION=us-east-1; E="--endpoint-url http://192.168.56.86:8333"
aws $E s3 rm s3://restic-prod/prod/ --recursive | tail -1
echo "objects listed after rm: $(aws $E s3 ls s3://restic-prod/prod/ --recursive | wc -l)"
restic snapshots 2>&1 | tail -2'
aws $E s3api delete-object --bucket restic-prod --key prod/config --version-id 6717055f8320f93d5b4053d220ea99cc
aws $E s3api put-object-retention --bucket restic-prod --key prod/config --version-id 6717055f8320f93d5b4053d220ea99cc --retention '{"Mode":"COMPLIANCE","RetainUntilDate":"2026-11-19T00:00:00Z"}'
# บนเครื่อง bkp
aws $E s3api delete-object --bucket restic-prod --key prod/config --version-id 6717055f8320f93d5b4053d220ea99cc
aws $E s3api get-object-retention --bucket restic-prod --key prod/config --version-id 6717055f8320f93d5b4053d220ea99cc
./s3-undelete.sh restic-prod | tail -1
# บนเครื่อง prod
sudo bash -c 'source /root/.config/restic/s3-env; restic snapshots --compact | tail -1'
sudo bash -c 'source /root/.config/restic/s3-env; restic unlock --remove-all; restic check | tail -1'

# ── filer ของ SeaweedFS ข้าม object lock ได้ ────────────────
# บนเครื่อง Host
curl -s -X DELETE -w "%{http_code}\n" "http://192.168.56.86:8888/buckets/restic-prod/config.versions?recursive=true"
# บนเครื่อง prod
sudo bash -c 'source /root/.config/restic/s3-env; restic snapshots'

# ── ซ้อมเต็มรูปแบบ ──────────────────────────────────────────
# ⚠️ สคริปต์นี้เข้ารหัสไฟล์ใน /srv/files ด้วยกุญแจสุ่มที่ไม่ถูกเก็บไว้ ไฟล์เดิมกู้ได้จาก backup เท่านั้น รันบนเครื่อง Lab ที่ทดสอบ backup ผ่านแล้วเท่านั้น
# บนเครื่อง prod
sudo bash ransomware-drill.sh
sudo bash -c 'source /root/.config/restic/env; restic restore latest --target / --include /srv/files' | tail -1
sudo bash -c 'source /root/.config/restic/env; restic restore latest --no-lock --target / --include /srv/files' | tail -1

# ── ผู้ดูแลเก็บกวาดบน bkp ───────────────────────────────────
# บนเครื่อง bkp
sudo -u restic restic -r /srv/backup/restic/prod --password-file /etc/restic/prod.pass unlock --remove-all
sudo tail -4 /srv/backup/borg/prod/transactions
sudo -u backup bash -c 'cd /srv/backup/borg/prod; for n in $(ls data/0); do [ $n -gt 17 ] && rm data/0/$n; done; rm -f index.* hints.* integrity.*; borg check --repository-only /srv/backup/borg/prod'
./s3-undelete.sh restic-prod | tail -1
# บนเครื่อง prod
sudo bash -c 'id=$(ls /root/.config/borg/security/); rm -f /root/.config/borg/security/$id/manifest-timestamp; rm -rf /root/.cache/borg/$id; source /root/.config/borg-env; borg list --short'
