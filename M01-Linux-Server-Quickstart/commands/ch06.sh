#!/usr/bin/env bash
# บทที่ 6 อัปเดตและ Backup ก่อนเปิดให้โลกเข้าถึง
# SysAdmin Pocket Series M01 Linux Server Quickstart ฉบับปรับปรุง (Rocky Linux 10.2)
#
# ไฟล์นี้รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# คำสั่งที่ไม่มีป้ายรันบน server ส่วนบรรทัดที่มีป้าย [Host PC] รันใน PowerShell บน Windows
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── เส้นทางที่ dnf ใช้ออกไปหา Mirror ────────────────────────────
ip route get 1.1.1.1
sudo dnf makecache

ip route get 1.1.1.1
dnf repolist


# ── ดูว่ามีอะไรรออัปเดตด้วย dnf check-update ────────────────────
dnf check-update

dnf -q check-update > /dev/null; echo $?

dnf -q check-update > /dev/null; [ $? -eq 100 ] && echo "$(hostname -s): มี Update รอติดตั้ง"


# ── แยก Security Update ด้วย dnf updateinfo ─────────────────────
dnf updateinfo summary
dnf updateinfo list --security
dnf updateinfo list --security --installed | grep openssl-libs

dnf updateinfo info --installed RLSA-2026:76918

sudo dnf upgrade --security -y
sudo dnf upgrade --sec-severity=Critical --sec-severity=Important -y
sudo dnf upgrade --advisory=RLSA-2026:76918 -y


# ── อัปเดตแบบ Manual และดูประวัติด้วย dnf history ───────────────
sudo dnf update -y

sudo dnf history list --reverse | tail -3
sudo dnf history info 2 | head -13

# ⚠️ `dnf history undo` ถอด Package ที่ Transaction นั้นติดตั้งและ Downgrade Package ที่อัปเกรดกลับทั้งชุด รวมถึง Security Patch ที่อยู่ในชุดเดียวกัน ให้ดูรายการด้วย `dnf history info` และถ่าย Snapshot ก่อน ใช้เป็นทางแก้ชั่วคราวระหว่างหาสาเหตุเท่านั้น
sudo dnf history undo 2


# ── ตรวจว่าต้อง Reboot ด้วย needs-restarting ────────────────────
sudo dnf install -y dnf-plugins-core
sudo dnf needs-restarting -r
echo $?

sudo dnf needs-restarting -s
sudo systemctl restart firewalld NetworkManager


# ── Reboot แล้วทดสอบว่า Server กลับมา ───────────────────────────
sudo systemctl reboot

# [Host PC] Test-NetConnection 192.168.56.10 -Port 2222

nc -zv -w 3 192.168.56.10 2222

uname -r
sudo dnf needs-restarting -r
systemctl --failed


# ── Kernel หลายรุ่นและการบูตกลับรุ่นเดิม ────────────────────────
grep installonly_limit /etc/dnf/dnf.conf
rpm -q kernel
uname -r
sudo grubby --default-kernel

sudo grubby --info=ALL | grep -E '^(index|title)'

sudo grub2-editenv - unset menu_auto_hide

sudo grubby --set-default /boot/vmlinuz-6.12.0-211.16.1.el10_2.0.1.x86_64

# ⚠️ คำสั่งนี้ลบ Kernel เก่าทิ้งจนเหลือตามจำนวนที่ระบุ ทางหนีไฟไปรุ่นก่อนจะหายไปด้วย ใช้หลังบูต Kernel ใหม่และใช้งานได้ปกติอย่างน้อยหนึ่งสัปดาห์แล้วเท่านั้น
sudo dnf remove --oldinstallonly --setopt installonly_limit=2 kernel


# ── ตั้ง Auto-update ด้วย dnf-automatic ─────────────────────────
sudo dnf install -y dnf-automatic


# ── ตั้งค่า /etc/dnf/automatic.conf ─────────────────────────────
sudo nano /etc/dnf/automatic.conf


# ── เปิดใช้งาน Timer ────────────────────────────────────────────
sudo systemctl enable --now dnf-automatic-install.timer
systemctl status dnf-automatic-install.timer

systemctl list-timers 'dnf-automatic*'

sudo systemctl edit dnf-automatic-install.timer

sudo systemctl daemon-reload
systemctl list-timers dnf-automatic-install.timer


# ── ทดสอบรันทันทีและอ่าน Log ────────────────────────────────────
sudo systemctl start dnf-automatic-install.service
sudo journalctl -u dnf-automatic-install.service --since today --no-pager

sudo grep -E 'Upgraded|Installed' /var/log/dnf.log | tail -5


# ── ชั้นที่ 1 สำเนาข้างไฟล์ก่อนแก้ไข ────────────────────────────
sudo cp -a /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%Y%m%d)
ls -l /etc/ssh/sshd_config*

sudo cp -a /etc/ssh/sshd_config.d/10-hardening.conf /etc/ssh/sshd_config.d/10-hardening.conf.bak.$(date +%Y%m%d)
sudo nano /etc/ssh/sshd_config.d/10-hardening.conf
sudo sshd -t
sudo cp -a /etc/ssh/sshd_config.d/10-hardening.conf.bak.20261113 /etc/ssh/sshd_config.d/10-hardening.conf
sudo sshd -t && sudo systemctl restart sshd

echo 'bak() { sudo cp -a "$1" "$1.bak.$(date +%Y%m%d%H%M)" && ls -l "$1.bak."*; }' >> ~/.bashrc
source ~/.bashrc
type bak

bak /etc/hosts
bak /etc/firewalld/zones/public.xml


# ── ชั้นที่ 2 สำรอง /etc ทั้งไดเรกทอรีด้วย tar ──────────────────
sudo mkdir -p /backup
sudo chmod 700 /backup
sudo tar czf /backup/etc-backup-$(date +%Y%m%d).tar.gz -C / etc
sudo chmod 600 /backup/etc-backup-$(date +%Y%m%d).tar.gz

sudo tar czf /backup/etc-pre-update-$(date +%Y%m%d-%H%M).tar.gz --selinux --xattrs --acls -C / etc


# ── ตรวจไฟล์ Backup ─────────────────────────────────────────────
sudo ls -lh /backup/
sudo tar tzf /backup/etc-backup-20261113.tar.gz | head -5
sudo tar tzf /backup/etc-backup-20261113.tar.gz | grep -c .


# ── สคริปต์ backup-configs.sh ───────────────────────────────────
sudo nano /usr/local/bin/backup-configs.sh

# ⚠️ สคริปต์นี้มีสองจุดที่ลบไฟล์ถาวร `rm -f` ลบเฉพาะไฟล์ที่สร้างไม่สำเร็จในรอบนั้น ส่วน `find ... -delete` ลบ Backup ที่เก่ากว่า 30 วันทุกครั้งที่รัน ถ้านโยบายขององค์กรกำหนดให้เก็บนานกว่านี้ ให้แก้ KEEP_DAYS ก่อนตั้ง cron และอย่าแก้ค่า BACKUP_DIR ให้ชี้ไปที่ไดเรกทอรีที่มีไฟล์อื่นปนอยู่
sudo chmod 700 /usr/local/bin/backup-configs.sh
sudo /usr/local/bin/backup-configs.sh
sudo ls -l /backup/


# ── Rotation: เก็บกี่ชุดและเก็บนานเท่าไร ────────────────────────
sudo find /backup -name 'server-config-*.tar.gz' -mtime +30 -print
sudo find /backup -name 'server-config-*.tar.gz' -mtime -1 -print

sudo sh -c 'ls -1t /backup/server-config-*.tar.gz | tail -n +15'

# ⚠️ คำสั่งด้านล่างลบ Backup ทุกชุดที่เกิน 14 ชุดล่าสุดทันที ตรวจผลของบรรทัดก่อนหน้าให้แน่ใจก่อน และใช้แทน find ในสคริปต์ ไม่ใช่ใช้คู่กัน
sudo sh -c 'ls -1t /backup/server-config-*.tar.gz | tail -n +15 | xargs -r rm --'

sudo tee /etc/logrotate.d/backup-configs > /dev/null << 'EOF'
/var/log/backup.log {
    monthly
    rotate 6
    compress
    missingok
    notifempty
}
EOF
sudo logrotate -d /etc/logrotate.d/backup-configs 2>&1 | tail -3


# ── ตั้งเวลาด้วย cron ───────────────────────────────────────────
sudo tee /etc/cron.d/backup-configs > /dev/null << 'EOF'
# สำรอง Config ของ server ทุกวัน 02:00 (M01 บทที่ 6)
SHELL=/bin/bash
PATH=/usr/sbin:/usr/bin
0 2 * * * root /usr/local/bin/backup-configs.sh >> /var/log/backup.log 2>&1
EOF
cat /etc/cron.d/backup-configs
ls -l /etc/cron.d/backup-configs

sudo EDITOR=nano crontab -e
sudo crontab -l

sudo env -i /bin/bash -c '/usr/local/bin/backup-configs.sh >> /var/log/backup.log 2>&1'
sudo tail -2 /var/log/backup.log

sudo grep backup-configs /var/log/cron | tail -2
sudo journalctl -u crond --since yesterday | grep backup-configs


# ── ดึงสำเนา Backup ออกไปเก็บที่ Host PC ────────────────────────
sudo ls -t /backup | grep '^server-config' | head -1
sudo install -m 600 -o admin -g admin /backup/server-config-20261113-1447.tar.gz ~/
sha256sum ~/server-config-20261113-1447.tar.gz

# [Host PC] New-Item -ItemType Directory -Force $HOME\server-backup | Out-Null
# [Host PC] scp -P 2222 admin@192.168.56.10:server-config-20261113-1447.tar.gz $HOME\server-backup\
# [Host PC] server-config-20261113-1447.tar.gz            100%   13KB   2.1MB/s   00:00
# [Host PC] Get-FileHash $HOME\server-backup\server-config-20261113-1447.tar.gz -Algorithm SHA256 | Format-List

# [Host PC] $h = (Get-FileHash $HOME\server-backup\server-config-20261113-1447.tar.gz).Hash
# [Host PC] $h -eq '9c2e71a04f3b8d65e1c0a7f9b3d2e4c6a8f0b1d3e5c7a9f1b2d4c6e8a0f2b4d6'

mkdir -p ~/server-backup
scp server:server-config-20261113-1447.tar.gz ~/server-backup/
cd ~/server-backup && echo "9c2e71a04f3b8d65e1c0a7f9b3d2e4c6a8f0b1d3e5c7a9f1b2d4c6e8a0f2b4d6  server-config-20261113-1447.tar.gz" | sha256sum -c

# ⚠️ rm ลบไฟล์ถาวรโดยไม่มีถังขยะ ตรวจค่า SHA256 ที่ Host PC ให้ตรงก่อน แล้วจึงลบ พิมพ์ Path ให้ขึ้นต้นด้วย ~/ ห้ามพิมพ์เป็น /backup
rm ~/server-config-20261113-1447.tar.gz

scp -P 2222 admin@203.0.113.25:server-config-20261113-0200.tar.gz /srv/offsite/web01/


# ── กู้ไฟล์เดียวจากชุด tar ──────────────────────────────────────
sudo mkdir -p /tmp/restore
sudo tar xzf /backup/server-config-20261113-1447.tar.gz -C /tmp/restore etc/hosts
sudo diff /tmp/restore/etc/hosts /etc/hosts

# ⚠️ คำสั่งด้านล่างเขียนทับ /etc/hosts ปัจจุบันทันที ค่าที่แก้หลังเวลาที่สำรองจะหายไป ถ้ายังอยากเก็บไฟล์ปัจจุบันไว้ ให้รัน `bak /etc/hosts` ก่อน
sudo tar xzf /backup/server-config-20261113-1447.tar.gz -C / etc/hosts
sudo restorecon -v /etc/hosts

# ⚠️ คำสั่งชุดนี้เขียนทับ Config ของ SSH และ authorized_keys ปัจจุบัน ให้เปิด Console ของ VM ค้างไว้ระหว่างทำ เผื่อ sshd เปิดไม่ขึ้น
sudo tar xzf /backup/server-config-20261114-0200.tar.gz -C / etc/ssh/sshd_config.d/10-hardening.conf home/admin/.ssh/authorized_keys
sudo restorecon -v /etc/ssh/sshd_config.d/10-hardening.conf /home/admin/.ssh/authorized_keys
sudo sshd -t && sudo systemctl restart sshd


# ── กู้ /etc ทั้งไดเรกทอรี ──────────────────────────────────────
# ⚠️ คำสั่งด้านล่างแตก Backup ทับ /etc ทั้งไดเรกทอรี ทุกไฟล์ที่แก้หลังวันที่สำรองจะถูกเขียนทับ รวมถึง /etc/shadow และค่า IP ของการ์ดเครือข่าย ไฟล์ที่สร้างใหม่หลังวันสำรองจะยังค้างอยู่เพราะ tar ไม่ลบไฟล์ ใช้เฉพาะเมื่อระบบเสียหนัก ถ่าย Snapshot ก่อน และเปิด Console ของ VirtualBox ค้างไว้เพราะ SSH อาจหลุด
sudo tar xzf /backup/etc-backup-20261113.tar.gz -C /
sudo restorecon -Rv /etc
sudo systemctl reboot


# ── กู้จากสำเนาบน Host PC ───────────────────────────────────────
# [Host PC] scp $HOME\server-backup\server-config-20261113-1447.tar.gz server:

sha256sum ~/server-config-20261113-1447.tar.gz
mkdir -p ~/restore
tar xzf ~/server-config-20261113-1447.tar.gz -C ~/restore etc/hosts
diff ~/restore/etc/hosts /etc/hosts

# ⚠️ install เขียนทับ /etc/hosts ปัจจุบันทันที ส่วน rm -r ลบไดเรกทอรีชั่วคราวทั้งหมดถาวร ตรวจว่า Path ขึ้นต้นด้วย ~/ ก่อนกด Enter
sudo install -m 644 -o root -g root ~/restore/etc/hosts /etc/hosts
sudo restorecon -v /etc/hosts
rm -r ~/restore ~/server-config-20261113-1447.tar.gz


# ── ถ่าย Snapshot ผ่าน Command Line ─────────────────────────────
# [Host PC] VBoxManage controlvm server acpipowerbutton
# [Host PC] VBoxManage showvminfo server --machinereadable | findstr "VMState="

# [Host PC] do { Start-Sleep 3; $s = VBoxManage showvminfo server --machinereadable | Select-String '^VMState=' } until ($s -match 'poweroff'); $s

# [Host PC] VBoxManage snapshot server take "ch06-start" --description "ก่อนเริ่มบทที่ 6 อัปเดตและ Backup"
# [Host PC] VBoxManage snapshot server list

# [Host PC] VBoxManage startvm server --type headless

VBoxManage controlvm server acpipowerbutton
VBoxManage showvminfo server --machinereadable | grep '^VMState='
VBoxManage snapshot server take "pre-update-20261113" --description "ก่อนอัปเดต kernel 211.16.1"
VBoxManage startvm server --type headless


# ── Restore Snapshot ────────────────────────────────────────────
# ⚠️ การ Restore Snapshot ทิ้งทุกอย่างที่ทำหลังจุดนั้น ทั้งไฟล์ใน /backup Config ที่แก้ และ Package ที่ติดตั้ง ดึงสำเนาที่ต้องการออกมาที่ Host PC ก่อน ถ้ายังอยากเก็บสถานะปัจจุบันไว้ ให้ถ่าย Snapshot ใหม่ก่อน Restore
# [Host PC] VBoxManage controlvm server acpipowerbutton
# [Host PC] VBoxManage showvminfo server --machinereadable | findstr "VMState="
# [Host PC] VBoxManage snapshot server restore "ch06-start"
# [Host PC] VBoxManage startvm server --type headless

# ⚠️ `controlvm server poweroff` ตัดไฟทันทีเหมือนดึงปลั๊ก ข้อมูลที่ยังไม่ถูกเขียนลงดิสก์จะหาย ใช้เมื่อ VM ค้างจนปิดแบบปกติไม่ได้เท่านั้น
# [Host PC] VBoxManage controlvm server poweroff


# ── Linked Clone สำหรับเล่มอื่น ─────────────────────────────────
# [Host PC] VBoxManage clonevm server --snapshot base-10.2 --options link --name client --register
# [Host PC] VBoxManage list vms

# [Host PC] VBoxManage clonevm server --snapshot ch06-start --options link --name update-test --register

# ⚠️ `unregistervm --delete` ลบ VM และดิสก์ส่วนต่างของมันถาวร พิมพ์ชื่อ update-test ให้ถูก ห้ามพิมพ์ server
# [Host PC] VBoxManage unregistervm update-test --delete


# ── เมื่อไหร่ควรถ่าย และเมื่อไหร่ควรลบ ──────────────────────────
# ⚠️ ทุก Snapshot ที่ถ่ายเพิ่มไฟล์ส่วนต่างหนึ่งชั้น ยิ่งเปลี่ยนแปลงมากยิ่งใช้พื้นที่มาก ควรลบ Snapshot ชั่วคราวเมื่อระบบทำงานปกติแล้ว แต่ห้ามลบ base-10.2 และ m01-done เพราะเล่มถัดไปใช้ต่อ และ base-10.2 เป็นดิสก์ฐานของ Linked Clone การลบ Snapshot ไม่ทำให้สถานะปัจจุบันหาย แต่จุดย้อนกลับนั้นจะหายถาวร
# [Host PC] VBoxManage snapshot server delete "lab6-test"
# [Host PC] VBoxManage snapshot server delete "pre-update-20261113"


# ── Lab 6.1 ทดสอบกู้คืนครบสามชั้น ───────────────────────────────
bak /etc/hosts
echo '192.168.56.99 wrong.lab.local' | sudo tee -a /etc/hosts
getent hosts wrong.lab.local
ls -t /etc/hosts.bak.* | head -1

# ⚠️ cp -a เขียนทับ /etc/hosts ด้วยไฟล์ .bak ใช้ชื่อไฟล์ที่ได้จาก ls -t ในเครื่องของคุณ ซึ่งจะต่างจากตัวอย่าง
sudo cp -a /etc/hosts.bak.202611131510 /etc/hosts
getent hosts wrong.lab.local; echo $?

sudo /usr/local/bin/backup-configs.sh | sudo tee -a /var/log/backup.log
sudo install -m 600 -o admin -g admin /backup/server-config-20261113-1515.tar.gz ~/

# [Host PC] scp server:server-config-20261113-1515.tar.gz $HOME\server-backup\
# [Host PC] PS> (Get-FileHash $HOME\server-backup\server-config-20261113-1515.tar.gz).Hash -eq 'e1d4a7c03b9f62581c0e3a7d9f2b4c6e8a1d3f5b7c9e2a4d6f8b0c2e4a6d8f0b'

# ⚠️ ลบเฉพาะสำเนาใน Home หลังได้ True แล้วเท่านั้น
rm ~/server-config-20261113-1515.tar.gz

echo '192.168.56.99 wrong.lab.local' | sudo tee -a /etc/hosts

# [Host PC] scp $HOME\server-backup\server-config-20261113-1515.tar.gz server:

mkdir -p ~/restore
tar xzf ~/server-config-20261113-1515.tar.gz -C ~/restore etc/hosts
diff ~/restore/etc/hosts /etc/hosts

# ⚠️ install เขียนทับ /etc/hosts และ rm -r ลบไดเรกทอรีชั่วคราวถาวร
sudo install -m 644 -o root -g root ~/restore/etc/hosts /etc/hosts
sudo restorecon -v /etc/hosts
getent hosts wrong.lab.local; echo $?
rm -r ~/restore ~/server-config-20261113-1515.tar.gz

# [Host PC] VBoxManage controlvm server acpipowerbutton
# [Host PC] VBoxManage showvminfo server --machinereadable | findstr "VMState="
# [Host PC] VBoxManage snapshot server take "lab6-test" --description "Lab 6.1 ชั้นที่ 3"
# [Host PC] VBoxManage startvm server --type headless
# [Host PC] do { Start-Sleep 5 } until (Test-NetConnection 192.168.56.10 -Port 2222 -InformationLevel Quiet -WarningAction SilentlyContinue)
# [Host PC] ssh -t server "sudo touch /root/after-snapshot"

# [Host PC] VBoxManage controlvm server acpipowerbutton
# [Host PC] VBoxManage showvminfo server --machinereadable | findstr "VMState="
# [Host PC] VBoxManage snapshot server restore "lab6-test"
# [Host PC] VBoxManage startvm server --type headless
# [Host PC] do { Start-Sleep 5 } until (Test-NetConnection 192.168.56.10 -Port 2222 -InformationLevel Quiet -WarningAction SilentlyContinue); 'port 2222 open'

sudo ls /root/after-snapshot

# ⚠️ `snapshot delete` ลบจุดย้อนกลับถาวร พิมพ์ชื่อ lab6-test ให้ถูก ห้ามพิมพ์ ch06-start หรือ base-10.2
# [Host PC] Get-ChildItem $HOME\server-backup -Name
# [Host PC] VBoxManage snapshot server delete "lab6-test"
# [Host PC] VBoxManage snapshot server list


# ── ดูรายการ Update และแยก Security ─────────────────────────────
# [Ubuntu]
sudo apt update
# [Ubuntu]
apt list --upgradable 2>/dev/null | grep -- -security | head -3
# [Ubuntu]
sudo apt upgrade -y


# ── unattended-upgrades แทน dnf-automatic ───────────────────────
# [Ubuntu]
sudo apt install -y unattended-upgrades
# [Ubuntu]
sudo dpkg-reconfigure -plow unattended-upgrades
# [Ubuntu]
cat /etc/apt/apt.conf.d/20auto-upgrades

# [Ubuntu]
sudo unattended-upgrade --dry-run --debug 2>&1 | tail -2
# [Ubuntu]
systemctl list-timers 'apt-daily*'
# [Ubuntu]
sudo tail -5 /var/log/unattended-upgrades/unattended-upgrades.log


# ── ตรวจว่าต้อง Reboot ──────────────────────────────────────────
# [Ubuntu]
cat /var/run/reboot-required /var/run/reboot-required.pkgs 2>/dev/null || echo "No reboot needed"
# [Ubuntu]
sudo needrestart -r l


# ── Kernel หลายรุ่น ─────────────────────────────────────────────
# [Ubuntu]
dpkg -l 'linux-image-[0-9]*' | grep ^ii
# [Ubuntu]
uname -r

# ⚠️ `apt autoremove --purge` ลบ Kernel เก่าและ Package ที่ไม่มีใครใช้แล้วทั้งหมด อ่านรายการที่ apt แสดงก่อนตอบ Y และทำหลังบูต Kernel ใหม่ได้ปกติแล้วเท่านั้น
# [Ubuntu]
sudo apt autoremove --purge


# ── Backup Script และ cron บน Ubuntu ────────────────────────────
# [Ubuntu]
sudo sshd -t && sudo systemctl restart ssh
