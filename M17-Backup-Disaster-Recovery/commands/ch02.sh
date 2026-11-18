#!/usr/bin/env bash
# บทที่ 2 Backup ไฟล์ด้วย rsync, tar, BorgBackup และ restic
# SysAdmin Pocket Series M17 Backup & Disaster Recovery
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── ใครเป็นฝ่ายเชื่อมต่อ ────────────────────────────────────
# บนเครื่อง bkp
sudo ssh-keygen -q -t ed25519 -N "" -C "bkp-pull" -f /root/.ssh/id_pull
sudo cat /root/.ssh/id_pull.pub
# บนเครื่อง prod
sudo install -m 755 /usr/share/doc/rsync/support/rrsync /usr/local/bin/rrsync
sudo install -d -m 700 /root/.ssh
echo 'from="192.168.56.86",command="/usr/local/bin/rrsync -ro /srv",restrict ssh-ed25519 AAAAC3...UZG6 bkp-pull' | sudo tee /root/.ssh/authorized_keys
sudo chmod 600 /root/.ssh/authorized_keys
printf 'Match Address 192.168.56.86\n    PermitRootLogin forced-commands-only\n' | sudo tee /etc/ssh/sshd_config.d/50-backup-pull.conf
sudo sshd -t && sudo systemctl reload sshd
for a in 192.168.56.86 192.168.56.1; do printf '%s ' $a; sudo sshd -T -C user=root,addr=$a,host=x | grep -i permitrootlogin; done
# บนเครื่อง bkp
S="ssh -p 2222 -i /root/.ssh/id_pull"
sudo rsync -an --stats -e "$S" root@192.168.56.85:files/ /tmp/t/ | grep -E "Number of files:|Total file size"
sudo $S root@192.168.56.85 id
sudo rsync -a -e "$S" /tmp/x root@192.168.56.85:files/x

# ── Lab 2.1 snapshot ด้วย --link-dest ───────────────────────
# บนเครื่อง bkp
sudo install -m 750 snap-pull.sh /usr/local/sbin/snap-pull.sh
sudo snap-pull.sh
sudo /usr/local/sbin/snap-pull.sh
# บนเครื่อง prod
echo "แก้ไขรอบสอง" | sudo tee -a /srv/files/sales/doc-001.txt /srv/files/hr/doc-002.txt
echo "ไฟล์ใหม่" | sudo tee /srv/files/sales/new-report.txt
sudo rm /srv/files/hr/doc-050.txt
# บนเครื่อง bkp
sudo /usr/local/sbin/snap-pull.sh
sudo bash -c 'cd /srv/backup/rsync/prod; du -sh 20*; du -sh --count-links 20*'
sudo bash -c 'cd /srv/backup/rsync/prod; diff -rq 2026-11-18_0623 2026-11-18_0624'
sudo cp -a /srv/backup/rsync/prod/2026-11-18_0623/files/hr/doc-050.txt /tmp/ && sudo chown admin /tmp/doc-050.txt
scp -P 2222 /tmp/doc-050.txt admin@192.168.56.85:/tmp/
# บนเครื่อง prod
sudo install -o root -g root -m 644 /tmp/doc-050.txt /srv/files/hr/
head -1 /srv/files/hr/doc-050.txt

# ── --delete กับ source ที่ว่าง ─────────────────────────────
# บนเครื่อง prod
sudo mkdir -p /tmp/mirror /tmp/emptysrc && sudo rsync -a /srv/files/ /tmp/mirror/
sudo rsync -an --delete --itemize-changes /tmp/emptysrc/ /tmp/mirror/ | grep -c "^\*deleting"
# ⚠️ ใช้ `--delete` เมื่อตรวจแล้วว่า source มีข้อมูลจริงเท่านั้น สคริปต์ควรหยุดเมื่อ source ว่างหรือมีไฟล์น้อยผิดปกติ snap-pull.sh ในบทนี้ปลอดภัยกว่า mirror เพราะ --delete ทำงานกับ snapshot ใหม่ ชุดเก่ายังอยู่ครบ
sudo rsync -an --delete --itemize-changes /srv/files /tmp/mirror/ | head -2

# ── 2.2 tar กับการบีบอัด ────────────────────────────────────
# บนเครื่อง prod
TIMEFORMAT="%R"; for c in "gzip" "xz -T0" "zstd -T0" "zstd -T0 -19"; do t=$( { time $c -c all.tar > out.bin; } 2>&1 ); printf "%-13s %10d bytes %ss\n" "$c" $(stat -c %s out.bin) "$t"; done
sudo tar -cf - -C /srv files | zstd -T0 -q -o /tmp/files.tar.zst
zstd -dc /tmp/files.tar.zst | tar -tf - | head -2

# ── Lab 2.2 repository บน bkp ───────────────────────────────
# บนเครื่อง prod
sudo dnf -y install epel-release && sudo dnf -y install borgbackup
sudo ssh-keygen -q -t ed25519 -N "" -C "prod-borg" -f /root/.ssh/id_borg
# บนเครื่อง bkp
echo 'command="borg serve --append-only --restrict-to-path /srv/backup/borg/prod",from="192.168.56.85",restrict ssh-ed25519 AAAAC3...vabZ prod-borg' | sudo tee /home/backup/.ssh/authorized_keys
sudo chown backup:backup /home/backup/.ssh/authorized_keys && sudo chmod 600 /home/backup/.ssh/authorized_keys
# บนเครื่อง prod
sudo install -d -m 700 /root/.config && sudo install -m 600 borg-env /root/.config/borg-env
sudo install -d -m 700 /var/backup /var/backup/db /var/backup/docker
sudo bash -c 'umask 077; head -c 24 /dev/urandom | base64 > /root/.borg-pass'
sudo ssh-keyscan -p 2222 192.168.56.86 | sudo tee -a /root/.ssh/known_hosts >/dev/null
sudo bash -c 'source /root/.config/borg-env; borg init --encryption repokey-blake2'
sudo bash -c 'source /root/.config/borg-env; borg key export :: /root/borg-key-prod.txt'
sudo install -m 750 borg-backup.sh /usr/local/sbin/
sudo /usr/local/sbin/borg-backup.sh
echo "รายงานเดือนพฤศจิกายน" | sudo tee /srv/files/sales/nov.txt
sudo /usr/local/sbin/borg-backup.sh | grep "This archive"
sudo bash -c 'source /root/.config/borg-env; cd /tmp/r && borg extract ::prod-2026-11-18_0628 srv/files/hr/doc-050.txt'
sudo bash -c 'source /root/.config/borg-env; borg mount :: /mnt/borg; ls /mnt/borg; borg umount /mnt/borg'

# ── ผู้บุกรุกลบ archive ได้หรือไม่ ──────────────────────────
# บนเครื่อง prod
sudo bash -c 'source /root/.config/borg-env; borg delete --force ::prod-2026-11-18_0628; borg list; borg compact'
# บนเครื่อง bkp
sudo tail -4 /srv/backup/borg/prod/transactions
sudo du -sh /srv/backup/borg/prod
# ⚠️ คำสั่งชุดนี้ลบข้อมูลใน repository ตรวจเลข transaction จากเวลาใน transactions ให้แน่ใจก่อน และคัดลอก repository เก็บไว้ทั้งโฟลเดอร์ก่อนลงมือ
sudo -u backup bash -c 'cd /srv/backup/borg/prod && cp -a . /tmp/borg-before-revert'
sudo -u backup bash -c 'cd /srv/backup/borg/prod; for n in $(ls data/0); do [ $n -gt 9 ] && rm data/0/$n; done; rm -f index.* hints.* integrity.*'
sudo -u backup borg check --repository-only -v /srv/backup/borg/prod
# บนเครื่อง prod
sudo bash -c 'source /root/.config/borg-env; borg list'
sudo bash -c 'id=$(ls /root/.config/borg/security/); rm /root/.config/borg/security/$id/manifest-timestamp; rm -rf /root/.cache/borg/$id'
sudo bash -c 'source /root/.config/borg-env; borg list --short'

# ── ลบ archive เก่าบน bkp ───────────────────────────────────
# บนเครื่อง prod
sudo cat /root/.borg-pass | ssh -p 2222 admin@192.168.56.86 'sudo -u backup bash -c "umask 077; cat > /home/backup/.borg-pass-prod"'
# บนเครื่อง bkp
sudo -u backup env BORG_PASSCOMMAND="cat /home/backup/.borg-pass-prod" borg prune --dry-run --list --keep-daily 7 --keep-weekly 4 --keep-monthly 6 /srv/backup/borg/prod

# ── Lab 2.3 rest-server บน bkp ──────────────────────────────
# บนเครื่อง bkp
V=0.14.0
curl -sSLO https://github.com/restic/rest-server/releases/download/v$V/rest-server_${V}_linux_amd64.tar.gz
curl -sSLO https://github.com/restic/rest-server/releases/download/v$V/SHA256SUMS
grep linux_amd64.tar.gz SHA256SUMS | sha256sum -c
tar xzf rest-server_${V}_linux_amd64.tar.gz && sudo install -m 755 rest-server_${V}_linux_amd64/rest-server /usr/local/bin/
sudo useradd --system --home /srv/backup/restic --shell /sbin/nologin restic
sudo install -d -o restic -g restic -m 700 /srv/backup/restic
sudo dnf -y install httpd-tools openssl
sudo install -d -m 755 /etc/rest-server
sudo openssl req -x509 -newkey ed25519 -nodes -days 3650 -subj "/CN=bkp.lab.local" -addext "subjectAltName=IP:192.168.56.86,DNS:bkp.lab.local" -keyout /etc/rest-server/tls.key -out /etc/rest-server/tls.crt
sudo chown restic /etc/rest-server/tls.key && sudo chmod 600 /etc/rest-server/tls.key
sudo htpasswd -B -c /etc/rest-server/.htpasswd prod
sudo chown restic /etc/rest-server/.htpasswd && sudo chmod 600 /etc/rest-server/.htpasswd
sudo install -m 644 rest-server.service /etc/systemd/system/ && sudo systemctl daemon-reload
sudo firewall-cmd --permanent --add-rich-rule='rule family=ipv4 source address=192.168.56.85 port port=8000 protocol=tcp accept'
sudo firewall-cmd --reload && sudo systemctl enable --now rest-server
sudo journalctl -u rest-server -o cat | tail -4

# ── ฝั่ง prod ───────────────────────────────────────────────
# บนเครื่อง prod
sudo install -d -m 700 /root/.config/restic
sudo install -m 644 bkp-tls.crt /root/.config/restic/bkp-tls.crt
sudo bash -c 'umask 077; head -c 24 /dev/urandom | base64 > /root/.restic-pass'
sudo install -m 600 restic-env /root/.config/restic/env
sudo bash -c 'source /root/.config/restic/env; restic init'
sudo install -m 750 restic-backup.sh /usr/local/sbin/ && sudo /usr/local/sbin/restic-backup.sh
sudo bash -c 'source /root/.config/restic/env; restic forget 8341f73a'
sudo bash -c 'source /root/.config/restic/env; restic restore latest --target /tmp/r --include /srv/files/hr/doc-050.txt'
# บนเครื่อง bkp
sudo install -m 750 prune-on-bkp.sh /usr/local/sbin/ && sudo /usr/local/sbin/prune-on-bkp.sh | tail -2
