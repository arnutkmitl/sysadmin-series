#!/usr/bin/env bash
# บทที่ 7 โปรเจกต์จบเล่ม: สร้าง Server พร้อมใช้งานใน 60 นาที
# SysAdmin Pocket Series M01 Linux Server Essentials (Rocky Linux 10.2)
#
# ไฟล์นี้รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# คำสั่งที่ไม่มีป้ายรันบน server ส่วนบรรทัดที่มีป้าย [Host PC] รันใน PowerShell บน Windows
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── อุปกรณ์และไฟล์ ──────────────────────────────────────────────
# ⚠️ Rocky Linux 10 ต้องใช้ CPU ระดับ x86-64-v3 ถ้า Windows เปิด Hyper-V, WSL2 หรือ Memory Integrity อยู่ VM จะขึ้น `Fatal glibc error: CPU does not support x86-64-v3` ทางแก้อยู่ในบทที่ 1 ตรวจก่อนเริ่มจับเวลา ไม่อย่างนั้นจะเสียเวลาไปกับปัญหานี้
# [Host PC] $env:Path += ";C:\Program Files\Oracle\VirtualBox"
# [Host PC] VBoxManage --version
# [Host PC] $start = Get-Date


# ── เลือกจุดเริ่มต้น ────────────────────────────────────────────
# [Host PC] VBoxManage list runningvms
# [Host PC] VBoxManage modifyvm server --name server-ch6
# [Host PC] VBoxManage list vms

# ⚠️ `VBoxManage snapshot ... restore` ทิ้งทุกอย่างที่ทำหลัง snapshot นั้นทันทีโดยไม่ถาม รวมถึงไฟล์ใน /backup ของบทที่ 6 ถ้าต้องการเก็บสถานะปัจจุบันไว้ ให้ถ่าย snapshot ชื่อ ch07-before ก่อน restore คำสั่ง `poweroff` ตัดไฟทันที ใช้เมื่อ VM ยังเปิดอยู่และกำลังจะ restore เท่านั้น
# [Host PC] VBoxManage controlvm server acpipowerbutton
# [Host PC] VBoxManage snapshot server take ch07-before
# [Host PC] VBoxManage snapshot server restore base-10.2


# ── สร้าง VM ────────────────────────────────────────────────────
# [Host PC] VBoxManage createvm --name server --ostype RedHat_64 --register
# [Host PC] VBoxManage modifyvm server --cpus 2 --memory 2048 --ioapic on --firmware efi --graphicscontroller vmsvga --vram 16 --nic1 nat --nic2 hostonly --hostonlyadapter2 "VirtualBox Host-Only Ethernet Adapter"
# [Host PC] VBoxManage createmedium disk --filename "$HOME\VirtualBox VMs\server\server.vdi" --size 20480
# [Host PC] VBoxManage storagectl server --name SATA --add sata --controller IntelAhci
# [Host PC] VBoxManage storageattach server --storagectl SATA --port 0 --device 0 --type hdd --medium "$HOME\VirtualBox VMs\server\server.vdi"
# [Host PC] VBoxManage storageattach server --storagectl SATA --port 1 --device 0 --type dvddrive --medium "$HOME\Downloads\Rocky-10.2-x86_64-minimal.iso"

# [Host PC] VBoxManage showvminfo server --machinereadable | findstr /B "vram= firmware= graphicscontroller= nic1= nic2= hostonlyadapter2="
# [Host PC] VBoxManage startvm server

# [Host PC] $vm = "web-test"
# [Host PC] VBoxManage createvm --name $vm --ostype RedHat_64 --register
# [Host PC] VBoxManage modifyvm $vm --cpus 2 --memory 4096 --ioapic on --firmware efi --graphicscontroller vmsvga --vram 16 --nic1 nat --nic2 hostonly --hostonlyadapter2 "VirtualBox Host-Only Ethernet Adapter"


# ── ตรวจหลังติดตั้ง ─────────────────────────────────────────────
cat /etc/rocky-release
hostname
ip -br addr
ip route
sudo whoami

# ⚠️ `nmcli con up` ตั้งค่าการ์ดใหม่ทันที ถ้าสั่งกับการ์ดที่กำลังใช้ SSH อยู่และค่าผิด session จะหลุด ให้สั่งจากหน้าจอ console ของ VirtualBox เสมอ
nmcli con show
sudo nmcli con mod enp0s8 ipv4.method manual ipv4.addresses 192.168.56.10/24 ipv4.gateway "" ipv4.dns "" ipv4.never-default yes
sudo nmcli con up enp0s8

sudo nmcli con mod backup-net ipv4.method manual ipv4.addresses 10.20.0.15/24 ipv4.never-default yes
sudo nmcli con up backup-net


# ── อัปเดต รีบูต และทดสอบจาก Host PC ────────────────────────────
sudo dnf update -y
sudo systemctl reboot

# ⚠️ `ssh-keygen -R` ลบบรรทัดของเครื่องนั้นออกจาก known_hosts ทำเฉพาะเมื่อรู้แน่ว่าเครื่องถูกสร้างใหม่ ในงานจริง ถ้าไม่ได้สร้างเครื่องใหม่แต่ขึ้นคำเตือนนี้ อาจมีคนดักกลางทาง ต้องสอบถามก่อนลบ
# [Host PC] ssh-keygen -R 192.168.56.10
# [Host PC] ssh-keygen -R "[192.168.56.10]:2222"
# [Host PC] ping -n 2 192.168.56.10
# [Host PC] ssh admin@192.168.56.10
exit


# ── ถ่าย snapshot base-10.2 ─────────────────────────────────────
# [Host PC] VBoxManage controlvm server acpipowerbutton
# [Host PC] while ((VBoxManage showvminfo server --machinereadable | findstr VMState=) -notmatch "poweroff") { Start-Sleep 2 }
# [Host PC] VBoxManage snapshot server take base-10.2 --description "Rocky 10.2 installed + dnf update"
# [Host PC] VBoxManage startvm server --type headless


# ── Phase 2 Package พื้นฐานและ Auto-update (5 นาที) ─────────────
sudo dnf install -y tar nano vim-enhanced bash-completion dnf-plugins-core policycoreutils-python-utils cronie
which tar nano semanage crontab

sudo dnf config-manager --set-enabled crb
sudo dnf install -y epel-release
sudo dnf install -y htop tree
sudo dnf update -y
dnf repolist


# ── ตั้ง dnf-automatic ──────────────────────────────────────────
sudo dnf install -y dnf-automatic
sudo sed -i 's/^apply_updates = no/apply_updates = yes/' /etc/dnf/automatic.conf
grep -E '^(upgrade_type|download_updates|apply_updates)' /etc/dnf/automatic.conf
sudo systemctl enable --now dnf-automatic-install.timer

systemctl list-timers dnf-automatic*


# ── Phase 3 User และ Group ของทีม (5 นาที) ──────────────────────
sudo groupadd webteam
sudo useradd -m -s /bin/bash -c "Web Developer" -G webteam webdev01
sudo passwd webdev01
sudo chage -d 0 webdev01
sudo usermod -aG webteam admin
id webdev01

sudo mkdir -p /srv/web
sudo chown root:webteam /srv/web
sudo chmod 2775 /srv/web
sudo -u webdev01 touch /srv/web/index.html
ls -ld /srv/web /srv/web/index.html

for u in webdev02 webdev03; do sudo useradd -m -s /bin/bash -G webteam "$u"; sudo chage -d 0 "$u"; done
getent group webteam


# ── ส่ง key จาก Host PC ─────────────────────────────────────────
# [Host PC] Test-Path $HOME\.ssh\id_ed25519, $HOME\.ssh\id_ed25519.pub

# [Host PC] type $HOME\.ssh\id_ed25519.pub | ssh admin@192.168.56.10 "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && restorecon -R ~/.ssh"
# [Host PC] ssh admin@192.168.56.10 "ls -la ~/.ssh"


# ── เขียนไฟล์ hardening ─────────────────────────────────────────
sudo cp -a /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%Y%m%d)
sudo ls /etc/ssh/sshd_config.d/
sudo tee /etc/ssh/sshd_config.d/10-hardening.conf > /dev/null << 'EOF'
Port 2222
PermitRootLogin no
PasswordAuthentication no
AllowUsers admin
MaxAuthTries 3
EOF


# ── เปิดพอร์ต 2222 ใน firewall และ SELinux ก่อน restart ─────────
sudo semanage port -a -t ssh_port_t -p tcp 2222
sudo semanage port -l | grep -w ssh_port_t
sudo firewall-cmd --permanent --add-port=2222/tcp
sudo firewall-cmd --reload


# ── ตรวจ syntax ตรวจค่าที่มีผลจริง แล้ว restart ─────────────────
sudo sshd -t
sudo sshd -T | grep -E '^(port|permitrootlogin|passwordauthentication|allowusers|maxauthtries) '
sudo systemctl restart sshd
sudo ss -tlnp | grep sshd


# ── ทดสอบจาก Host PC ก่อนไปต่อ ──────────────────────────────────
# [Host PC] ssh -p 2222 admin@192.168.56.10
exit
# [Host PC] ssh -p 2222 -o PubkeyAuthentication=no admin@192.168.56.10
# [Host PC] ssh -p 2222 root@192.168.56.10

# [Host PC] Get-Content $HOME\.ssh\config
# [Host PC] ssh server hostname


# ── Phase 5 Firewall และ SELinux (5 นาที) ───────────────────────
# ⚠️ `--remove-service=ssh` ปิดพอร์ต 22 ทันทีหลัง reload ทำต่อเมื่อ `ssh server` ใน Phase 4 เข้าได้แล้วเท่านั้น ถ้าพลาด ให้แก้จาก console ของ VirtualBox หรือ restore snapshot base-10.2 แล้วเริ่ม Phase 2 ใหม่
sudo firewall-cmd --permanent --remove-service=ssh --remove-service=cockpit --remove-service=dhcpv6-client
sudo firewall-cmd --permanent --add-service=http --add-service=https
sudo firewall-cmd --reload
sudo firewall-cmd --list-all

sudo firewall-cmd --permanent --list-services
sudo firewall-cmd --permanent --list-ports


# ── ตรวจ SELinux ────────────────────────────────────────────────
getenforce
grep '^SELINUX=' /etc/selinux/config
sudo ausearch -m avc -ts today


# ── Phase 6 Backup, cron และสำเนาที่ Host PC (5 นาที) ───────────
sudo tee /usr/local/bin/backup-configs.sh > /dev/null << 'EOF'
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
EOF
sudo chmod 700 /usr/local/bin/backup-configs.sh

# ⚠️ `rm -f` ในสคริปต์ลบเฉพาะไฟล์ที่สร้างไม่สำเร็จในรอบนั้น ส่วน `find ... -delete` ลบไฟล์ backup ที่เก่ากว่า KEEP_DAYS วันทิ้งถาวรโดยไม่ถาม ตรวจว่า BACKUP_DIR และรูปแบบชื่อไฟล์ถูกต้องก่อนตั้ง cron ถ้าแก้ BACKUP_DIR เป็น path ที่มีไฟล์อื่นชื่อคล้ายกัน ไฟล์เหล่านั้นจะถูกลบด้วย
sudo /usr/local/bin/backup-configs.sh
sudo ls -ld /backup /backup/server-config-20261113-1422.tar.gz
sudo tar tzf /backup/server-config-20261113-1422.tar.gz | grep sshd_config.d


# ── ตั้ง cron ทุกคืน 02:00 ──────────────────────────────────────
sudo tee /etc/cron.d/backup-configs > /dev/null << 'EOF'
# สำรอง Config ของ server ทุกวัน 02:00 (M01 บทที่ 6)
SHELL=/bin/bash
PATH=/usr/sbin:/usr/bin
0 2 * * * root /usr/local/bin/backup-configs.sh >> /var/log/backup.log 2>&1
EOF
grep -v '^#' /etc/cron.d/backup-configs
systemctl is-active crond
ls -lZ /etc/cron.d/backup-configs

sudo sed -i 's/^0 2 \* \* \* root/30 2 * * * root/' /etc/cron.d/backup-configs
grep backup-configs.sh /etc/cron.d/backup-configs


# ── ดึงสำเนาไปเก็บที่ Host PC ───────────────────────────────────
sudo install -m 600 -o admin -g admin /backup/server-config-20261113-1422.tar.gz /home/admin/
sha256sum /home/admin/server-config-20261113-1422.tar.gz

# [Host PC] New-Item -ItemType Directory -Force $HOME\server-backup | Out-Null
# [Host PC] scp server:server-config-20261113-1422.tar.gz $HOME\server-backup\
# [Host PC] server-config-20261113-1422.tar.gz            100%   13KB   3.2MB/s   00:00
# [Host PC] (Get-FileHash $HOME\server-backup\server-config-20261113-1422.tar.gz -Algorithm SHA256).Hash

# ⚠️ `rm` ลบไฟล์ถาวรโดยไม่มีถังขยะ ลบเฉพาะไฟล์ใน /home/admin หลังเทียบ hash ตรงแล้ว ห้ามพิมพ์ path เป็น /backup
rm /home/admin/server-config-20261113-1422.tar.gz

# [Host PC] scp -P 2222 admin@203.0.113.25:server-config-20261113-0200.tar.gz D:\offsite\web01\


# ── ติดตั้งสคริปต์ ──────────────────────────────────────────────
sudo tee /usr/local/bin/handover-check.sh > /dev/null << 'EOF'
#!/bin/bash
# handover-check.sh  ตรวจ server ตาม Series Baseline ของ M01 ก่อนส่งมอบ
# ใช้: sudo /usr/local/bin/handover-check.sh   (exit code = จำนวนข้อที่ FAIL)

if [ "$(id -u)" -ne 0 ]; then
    echo "ต้องรันด้วย sudo" >&2
    exit 255
fi

N=0
FAIL=0
SSHD=$(sshd -T 2>/dev/null)

# check "คำอธิบาย" 'คำสั่งตรวจ'  คำสั่งตรวจคืนค่า 0 = PASS
check() {
    N=$((N + 1))
    if eval "$2" > /dev/null 2>&1; then
        printf '[%02d] PASS  %s\n' "$N" "$1"
    else
        printf '[%02d] FAIL  %s\n' "$N" "$1"
        FAIL=$((FAIL + 1))
    fi
}

# sshd_is "port 2222"  ค่าที่ sshd ใช้จริงของคีย์นั้นต้องมีบรรทัดเดียวและตรงทุกตัวอักษร
sshd_is() { [ "$(printf '%s\n' "$SSHD" | grep "^${1%% *} ")" = "$1" ]; }

# sorted  เรียงคำในบรรทัด เพื่อเทียบรายการโดยไม่สนลำดับ
sorted() { tr ' ' '\n' | sed '/^$/d' | sort | xargs; }

echo "=== M01 Handover Check: $(hostname) $(date '+%F %T') ==="
echo "--- ระบบและเครือข่าย"
check "Rocky Linux 10.2"               'grep -q "release 10.2" /etc/rocky-release'
check "hostname server.lab.local"      '[ "$(hostname)" = "server.lab.local" ]'
check "enp0s8 = 192.168.56.10/24"      'ip -4 -o addr show enp0s8 | grep -q "inet 192.168.56.10/24"'
check "default route via enp0s3 only"  '[ "$(ip route show default | wc -l)" -eq 1 ] && ip route show default | grep -q "dev enp0s3"'
check "no pending updates"             'dnf -q check-update'
check "no reboot required"             'dnf needs-restarting -r'
echo "--- ผู้ใช้"
check "admin in wheel"                 'id -nG admin | grep -qw wheel'
check "root password locked"           'getent shadow root | cut -d: -f2 | grep -q "^[!*]"'
check "admin authorized_keys 600"      '[ -s /home/admin/.ssh/authorized_keys ] && [ "$(stat -c %a /home/admin/.ssh/authorized_keys)" = 600 ]'
echo "--- SSH"
check "sshd port 2222 only"            'sshd_is "port 2222"'
check "PasswordAuthentication no"      'sshd_is "passwordauthentication no"'
check "PermitRootLogin no"             'sshd_is "permitrootlogin no"'
check "AllowUsers admin"               'sshd_is "allowusers admin"'
check "MaxAuthTries 3"                 'sshd_is "maxauthtries 3"'
check "sshd listening on 2222"         'ss -Htln "sport = :2222" | grep -q LISTEN'
echo "--- Firewall และ SELinux"
check "firewalld active"               'systemctl is-active firewalld'
check "ports = 2222/tcp (runtime+perm)" '[ "$(firewall-cmd --list-ports)" = "2222/tcp" ] && [ "$(firewall-cmd --permanent --list-ports)" = "2222/tcp" ]'
check "services = http https"          '[ "$(firewall-cmd --list-services | sorted)" = "http https" ] && [ "$(firewall-cmd --permanent --list-services | sorted)" = "http https" ]'
check "SELinux Enforcing (now+boot)"   '[ "$(getenforce)" = "Enforcing" ] && grep -qx "SELINUX=enforcing" /etc/selinux/config'
check "ssh_port_t includes 2222"       'semanage port -l | grep "^ssh_port_t" | grep -qw 2222'
echo "--- Update และ Backup"
check "dnf-automatic-install.timer"    'systemctl is-enabled dnf-automatic-install.timer && systemctl is-active dnf-automatic-install.timer'
check "crond + backup job"             'systemctl is-active crond && { grep -qs "backup-configs.sh" /etc/cron.d/backup-configs || crontab -l | grep -q "backup-configs.sh"; }'
check "/backup mode 700"               '[ "$(stat -c %a /backup)" = 700 ]'
check "backup < 24h with sshd config"  'f=$(find /backup -maxdepth 1 -name "server-config-*.tar.gz" -mmin -1440 | sort | tail -1); [ -n "$f" ] && tar tzf "$f" | grep -q "etc/ssh/sshd_config.d/10-hardening.conf"'
echo "==="
if [ "$FAIL" -eq 0 ]; then
    echo "RESULT: PASS $N/$N พร้อมถ่าย snapshot m01-done"
else
    echo "RESULT: FAIL $FAIL จาก $N ข้อ แก้ข้อที่ FAIL แล้วรันใหม่"
fi
exit "$FAIL"
EOF
sudo chmod 755 /usr/local/bin/handover-check.sh
bash -n /usr/local/bin/handover-check.sh


# ── รันและอ่านผล ────────────────────────────────────────────────
sudo /usr/local/bin/handover-check.sh
echo $?

sudo /usr/local/bin/handover-check.sh | grep -E 'FAIL|RESULT'
sudo firewall-cmd --list-services
sudo dnf needs-restarting -r

sudo /usr/local/bin/handover-check.sh > /tmp/check.txt || grep FAIL /tmp/check.txt


# ── ทดสอบจาก Host PC ────────────────────────────────────────────
# [Host PC] ping -n 3 192.168.56.10
# [Host PC] ssh -o BatchMode=yes server hostname
# [Host PC] ssh -o PubkeyAuthentication=no server

# [Host PC] $tests = @(@(2222, $true), @(22, $false), @(3306, $false))
# [Host PC] foreach ($t in $tests) {
# [Host PC] $open = Test-NetConnection 192.168.56.10 -Port $t[0] -InformationLevel Quiet -WarningAction SilentlyContinue
# [Host PC] if ($open -eq $t[1]) { "PASS  port $($t[0]) open=$open" } else { "FAIL  port $($t[0]) open=$open" }
# [Host PC] }

# [Host PC] foreach ($p in 2222, 22, 443) { "{0,-5} {1}" -f $p, (Test-NetConnection 203.0.113.25 -Port $p -InformationLevel Quiet -WarningAction SilentlyContinue) }

# [Host PC] curl.exe -I http://192.168.56.10

# [Host PC] ssh -t server sudo /usr/local/bin/handover-check.sh


# ── ปิดเครื่องและถ่าย snapshot m01-done ─────────────────────────
# [Host PC] VBoxManage controlvm server acpipowerbutton
# [Host PC] while ((VBoxManage showvminfo server --machinereadable | findstr VMState=) -notmatch "poweroff") { Start-Sleep 2 }
# [Host PC] VBoxManage showvminfo server --machinereadable | findstr VMState=
# [Host PC] VBoxManage snapshot server take m01-done --description "M01 done: SSH 2222 key-only, firewalld, SELinux, dnf-automatic, backup"
# [Host PC] VBoxManage snapshot server list
# [Host PC] (Get-Date) - $start | Select-Object Hours, Minutes


# ── กล่อง Ubuntu ────────────────────────────────────────────────
# [Host PC] VBoxManage createvm --name ubuntu --ostype Ubuntu_64 --register
# [Host PC] VBoxManage modifyvm ubuntu --cpus 2 --memory 2048 --ioapic on --firmware efi --graphicscontroller vmsvga --vram 16 --nic1 nat --nic2 hostonly --hostonlyadapter2 "VirtualBox Host-Only Ethernet Adapter"

# [Ubuntu]
sudo useradd -m -g admin -G sudo -s /bin/bash admin
# [Ubuntu]
id admin
# [Ubuntu]
cat /etc/netplan/50-cloud-init.yaml

# [Ubuntu]
sudo apt update && sudo apt full-upgrade -y
# [Ubuntu]
sudo apt install -y unattended-upgrades bash-completion htop tree
# [Ubuntu]
cat /etc/apt/apt.conf.d/20auto-upgrades
# [Ubuntu]
systemctl is-active apt-daily-upgrade.timer

# [Ubuntu]
sudo sshd -t
# [Ubuntu]
sudo systemctl daemon-reload
# [Ubuntu]
sudo systemctl restart ssh.socket
# [Ubuntu]
sudo ss -tlnp | grep 2222

# ⚠️ ถ้าสั่ง `ufw enable` ผ่าน SSH ก่อน `ufw allow 2222/tcp` session จะหลุดและเข้าไม่ได้อีก ต้องแก้จาก console ของ VirtualBox
# [Ubuntu]
sudo ufw allow 2222/tcp
# [Ubuntu]
sudo ufw allow 80/tcp
# [Ubuntu]
sudo ufw allow 443/tcp
# [Ubuntu]
sudo ufw enable
# [Ubuntu]
sudo ufw status verbose
