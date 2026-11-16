#!/usr/bin/env bash
# บทที่ 2 รู้จักระบบ คำสั่งพื้นฐานที่ต้องใช้ทุกวัน
# SysAdmin Pocket Series M01 Linux Server Quickstart ฉบับปรับปรุง (Rocky Linux 10.2)
#
# ไฟล์นี้รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# คำสั่งที่ไม่มีป้ายรันบน server ส่วนบรรทัดที่มีป้าย [Host PC] รันใน PowerShell บน Windows
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1
# [Host PC] $env:Path += ";C:\Program Files\Oracle\VirtualBox"
# [Host PC] VBoxManage controlvm server acpipowerbutton
# [Host PC] VBoxManage list runningvms
# [Host PC] VBoxManage snapshot server take ch02-start --description "ก่อนเริ่มบทที่ 2"
# [Host PC] VBoxManage startvm server --type headless

# [Host PC] ssh admin@192.168.56.10
sudo dnf install -y tar nano vim-enhanced bash-completion tree man-db man-pages
exit
# [Host PC] ssh admin@192.168.56.10


# ── โครงสร้าง Directory มาตรฐานของ Linux ────────────────────────
ls -ld /bin /sbin


# ── อ่าน prompt และรูปแบบคำสั่ง ─────────────────────────────────


ls -l /etc/hostname
ls -l -h /var/log/messages /var/log/secure


# ── คำสั่ง pwd และ cd ───────────────────────────────────────────
pwd
cd /var/log
pwd
cd ..
pwd
cd -
cd
pwd

cd /etc/NetworkManager/system-connections/
sudo ls -l /etc/NetworkManager/system-connections/


# ── Absolute path และ Relative path ─────────────────────────────
cd ~
mkdir -p projects/web/logs
cd projects/web
pwd
cd ../../../../etc/ssh
pwd
cd ~/projects/web/logs
pwd

cd /tmp
ls projects
ls ~/projects
ls /home/admin/projects


# ── คำสั่ง ls ดูรายการไฟล์ ──────────────────────────────────────
sudo ls -la /root

sudo ls -lt /var/log | head -6


# ── คำสั่ง tree ดูโครงสร้างเป็นต้นไม้ ───────────────────────────
tree ~/projects

sudo tree -L 2 /etc/ssh/


# ── Tab completion และ history ──────────────────────────────────
ls /etc/sysco[Tab]
ls /etc/sysconfig/
ls /etc/sysconfig/n[Tab][Tab]

systemctl res[Tab][Tab]
systemctl status Netw[Tab]
systemctl status NetworkManager
sudo dnf in[Tab][Tab]

history | tail -4
!23

# ⚠️ history บันทึกทุกอย่างที่พิมพ์ รวมถึงรหัสผ่านที่เผลอใส่ในบรรทัดคำสั่ง ถ้าเกิดขึ้นให้ลบรายการนั้นด้วย history -d ตามด้วยเลขลำดับ แล้วเปลี่ยนรหัสผ่านทันที
history -d 31


# ── หาคำตอบเองด้วย man และ --help ───────────────────────────────
ls --help | grep -- '-h,'
df --help | head -3

man ls

man 5 sshd_config
sudo mandb -q
man -k hostname


# ── สร้าง Directory และไฟล์ด้วย mkdir และ touch ─────────────────
mkdir ~/lab02
mkdir ~/lab02/a/b
mkdir -p ~/lab02/a/b
touch ~/lab02/note.txt
ls -l ~/lab02

mkdir -p ~/projects/web/{html,logs,backup}
ls ~/projects/web


# ── คัดลอกไฟล์และ Directory ด้วย cp ─────────────────────────────
cp /etc/hostname ~/lab02/hostname.bak
cp /etc/hostname /etc/os-release ~/lab02/
ls ~/lab02
cp ~/lab02/a ~/lab02/a-copy
cp -r ~/lab02/a ~/lab02/a-copy

sudo cp -a /etc/ssh/ ~/lab02/ssh-backup-$(date +%F)/
ls ~/lab02
cp -r /etc/ssh/ ~/lab02/ssh-nosudo/

# ⚠️ cp เขียนทับไฟล์ปลายทางที่ชื่อซ้ำโดยไม่ถาม ใส่ -i ให้ถามก่อนทับเมื่อไม่แน่ใจว่าปลายทางมีไฟล์อยู่แล้วหรือไม่
cp -i /etc/hostname ~/lab02/hostname.bak


# ── ย้ายและเปลี่ยนชื่อด้วย mv ───────────────────────────────────
mv ~/lab02/note.txt ~/lab02/a/
mv ~/lab02/a/note.txt ~/lab02/a/readme.txt
ls ~/lab02/a

mkdir ~/lab02/conf.d
touch ~/lab02/conf.d/10-site.conf
mv ~/lab02/conf.d/10-site.conf ~/lab02/conf.d/10-site.conf.disabled
ls ~/lab02/conf.d


# ── ลบไฟล์และ Directory ด้วย rm และ rmdir ───────────────────────
# ⚠️ rm ลบไฟล์ทันทีโดยไม่มีถังขยะและกู้คืนไม่ได้ rm -r ลบทุกอย่างใต้ Directory และ rm -rf ลบโดยไม่ถามแม้ไฟล์จะป้องกันการเขียนไว้ ก่อนกด Enter ให้อ่าน path ซ้ำทุกครั้ง ห้ามพิมพ์ rm -rf / หรือ rm -rf /* เพราะจะลบทั้งระบบ เมื่อใช้คู่กับ sudo ความเสียหายครอบคลุมทั้งเครื่อง
rm -i ~/lab02/hostname.bak
rmdir ~/lab02/a
rm -r ~/lab02/a-copy
rm -r ~/lab02/ssh-nosudo
sudo rm -r ~/lab02/ssh-backup-2026-11-02

ls -d ~/lab02/conf.d/*.disabled
rm ~/lab02/conf.d/*.disabled


# ── Wildcard เลือกหลายไฟล์ในคำสั่งเดียว ─────────────────────────
cd ~/lab02
touch app-2026-10-{30,31}.log app-2026-11-0{1,2}.log app.log error.txt
ls app-2026-11-*
ls app-2026-1?-3*
ls *.log
echo rm app-2026-10-*

ls /etc/yum.repos.d/*.repo
sudo ls /var/log/messages*


# ── อ่านเนื้อหาไฟล์ด้วย cat, less, head และ tail ────────────────
cat /etc/hostname
cat -n /etc/resolv.conf

sudo less /etc/ssh/sshd_config
sudo less +G /var/log/messages

head -n 3 /etc/os-release
sudo tail -n 3 /var/log/secure

sudo tail -f /var/log/secure


# ── Redirection และ pipe ────────────────────────────────────────
cd ~/lab02
ls /etc/hostname /nothing
ls /etc/hostname /nothing > out.txt
cat out.txt
ls /etc/hostname /nothing 2> err.txt
cat err.txt
ls /etc/hostname /nothing &> all.txt
wc -l all.txt

# ⚠️ ตัวดำเนินการ > ล้างไฟล์ปลายทางเป็นไฟล์เปล่าก่อนเขียน แม้คำสั่งด้านหน้าจะล้มเหลว พิมพ์ > แทน >> ผิดเพียงตัวเดียวกับไฟล์ Config ทำให้เนื้อหาเดิมหายทั้งไฟล์ ให้สำรองไฟล์ด้วย cp ก่อนเขียนเสมอ
echo "บรรทัดที่ 1" > notes.txt
echo "บรรทัดที่ 2" >> notes.txt
cat notes.txt
echo "ทับแล้ว" > notes.txt
cat notes.txt

sudo echo "# lab02" > /etc/motd.d/lab02
echo "ยินดีต้อนรับสู่ server ของ Lab M01" | sudo tee /etc/motd.d/lab02

ls /etc | wc -l
ps aux --sort=-%mem | head -6

sudo journalctl -u sshd --since today | grep 'Failed password' | grep -oE 'from [0-9.]+' | sort | uniq -c | sort -rn


# ── ค้นข้อความในไฟล์ด้วย grep ───────────────────────────────────
grep -n admin /etc/passwd
grep -c bash /etc/passwd
grep -i 'rocky' /etc/os-release

grep -Ev '^\s*(#|$)' /etc/chrony.conf
sudo grep -rn '^PasswordAuthentication' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/


# ── แก้ไขไฟล์ด้วย nano ──────────────────────────────────────────
nano ~/lab02/a/readme.txt

sudo cp -a /etc/hosts /etc/hosts.bak
sudo nano -l /etc/hosts

ping -c 1 server
getent ahostsv4 server.lab.local | head -1


# ── คำสั่ง uptime ดูเวลาเปิดเครื่องและ Load Average ─────────────
uptime
uptime -p
nproc


# ── คำสั่ง free -h ดู RAM ───────────────────────────────────────
free -h

free -m -s 5


# ── คำสั่ง df -h และ du ดูพื้นที่ Disk ──────────────────────────
df -hT

df -h /var

sudo du -sh /var/* 2>/dev/null | sort -h | tail -4


# ── คำสั่ง top และ htop ดู Process แบบ Real-time ────────────────
top

top -b -n 1 | head -12


# ── คำสั่ง ss -tlnp ดู Port ที่เปิดอยู่ ─────────────────────────
sudo ss -tlnp

sudo ss -tlnp | grep ':22 '
sudo ss -ulnp


# ── ดูสถานะเครือข่าย ────────────────────────────────────────────
ip -br addr

ip -br -4 addr show enp0s8
ip -br link

ip route

ip route get 1.1.1.1
ip route get 192.168.56.1

# ⚠️ อย่าใส่ Gateway หรือ DNS ที่การ์ด enp0s8 ถ้า ip route แสดงบรรทัด default สองบรรทัด แพ็กเก็ตออกอินเทอร์เน็ตอาจวิ่งไปทาง Host-only ที่ไม่มีทางออก dnf จะค้างหรือ Timeout ให้แก้ Profile ของ enp0s8 ตามบทที่ 1
ping -c 3 10.0.2.2

ping -c 3 one.one.one.one
ping -c 3 rockylinux.orgg

sudo ss -tnp state established '( sport = :22 )'

nmcli device status

nmcli device show enp0s8 | grep IP4
nmcli device show enp0s3 | grep -E 'IP4.(GATEWAY|DNS)'


# ── ทำความเข้าใจ systemd และ Unit ───────────────────────────────
systemctl cat sshd


# ── systemctl status อ่านสถานะ Service ──────────────────────────
systemctl status sshd

systemctl status NetworkManager --no-pager | head -3
systemctl is-active NetworkManager sshd


# ── start, stop, restart และ reload ─────────────────────────────
sudo systemctl stop chronyd
systemctl status chronyd --no-pager | head -3
sudo systemctl start chronyd
systemctl is-active chronyd
sudo systemctl restart chronyd

sudo sshd -t
sudo systemctl reload sshd

# ⚠️ ถ้า SSH อยู่แล้วรัน sudo systemctl stop sshd Session ปัจจุบันยังอยู่ แต่จะเปิด Session ใหม่ไม่ได้ ให้รัน sudo systemctl start sshd ใน Session ที่ยังเปิดอยู่ทันที ถ้า Session หลุดไปแล้วให้เข้าทาง Console ของ VirtualBox บทนี้ไม่ต้องหยุด sshd จริง
sudo systemctl stop sshd
sudo systemctl start sshd


# ── enable กับ start ต่างกันอย่างไร ─────────────────────────────
sudo systemctl disable chronyd
systemctl is-active chronyd; systemctl is-enabled chronyd
sudo systemctl enable chronyd
systemctl is-active chronyd; systemctl is-enabled chronyd

sudo systemctl enable --now chronyd
systemctl is-enabled sshd chronyd firewalld


# ── ดูรายการ Service ทั้งหมด ────────────────────────────────────
systemctl list-units --type=service --state=running
systemctl list-unit-files --type=service --state=enabled --no-legend | wc -l

systemctl --failed


# ── ทำความเข้าใจ Log ใน Linux ───────────────────────────────────
ls -d /var/log/journal
sudo journalctl --disk-usage

sudo mkdir -p /var/log/journal
sudo systemctl restart systemd-journald
sudo journalctl --flush
ls -d /var/log/journal


# ── อ่าน Log ของ Service เดียวด้วย -u ───────────────────────────
sudo journalctl -u sshd -n 4 --no-pager

sudo journalctl -u NetworkManager --since today --no-pager | grep -i 'enp0s3' | tail -3
sudo journalctl -u sshd -u firewalld --since "30 min ago"


# ── ติดตาม Log แบบ Real-time ด้วย -f ────────────────────────────
sudo journalctl -u sshd -f

sudo journalctl -f -n 0


# ── กรองตามเวลาด้วย --since และ --until และตาม Boot ด้วย -b ─────
sudo journalctl --since "2026-11-02 13:00" --until "2026-11-02 13:15" --no-pager | wc -l
sudo journalctl -u chronyd --since "1 hour ago" --no-pager

sudo journalctl --list-boots
sudo journalctl -b -1 -e


# ── กรองตามระดับความรุนแรงด้วย -p ───────────────────────────────
sudo journalctl -p err -b --no-pager

sudo journalctl -p err --since today
sudo journalctl -p warning..err -u firewalld --since yesterday


# ── ค้นด้วยคำและเลือกรูปแบบการแสดงผล ────────────────────────────
sudo journalctl -t sudo -n 3 --no-pager
sudo journalctl -k -g 'enp0s(3|8)' --no-pager

sudo journalctl -u sshd -g 'Failed password|Invalid user' --since yesterday -o short-iso --no-pager
sudo journalctl -u sshd -n 2 -o cat


# ── อ่านไฟล์ Log แบบดั้งเดิมด้วย less และ grep ──────────────────
rpm -q rsyslog
sudo ls -l /var/log/{messages,secure,cron,dnf.log}

sudo less +G /var/log/secure

sudo grep -A 2 'Failed password' /var/log/secure
sudo grep -c 'Failed password' /var/log/secure
sudo grep -i -A 2 'error' /var/log/messages | less


# ── dnf ออกอินเทอร์เน็ตทางไหน ───────────────────────────────────
ip route get 1.1.1.1
grep nameserver /etc/resolv.conf

sudo dnf makecache


# ── ตรวจและติดตั้งอัปเดต ────────────────────────────────────────
dnf check-update

sudo dnf update -y
sudo dnf needs-restarting -r


# ── ค้นหา Package ด้วย search, info และ provides ────────────────
dnf search htop
dnf info bind-utils

dig rockylinux.org
dnf provides '*/bin/dig'


# ── ติดตั้ง Package และตรวจด้วย rpm ─────────────────────────────
sudo dnf install bind-utils
dig +short rockylinux.org

rpm -q openssh-server bind-utils htop
command -v ss
rpm -qf /usr/sbin/ss
rpm -ql bind-utils | grep bin/


# ── ดูรายการ Package ที่ติดตั้ง ─────────────────────────────────
dnf list --installed | wc -l
dnf list --installed 'openssh*'

dnf repoquery --userinstalled --qf '%{name}' > ~/lab02/packages-$(date +%F).txt
grep -E 'bind-utils|nano|tree' ~/lab02/packages-2026-11-16.txt


# ── ลบ Package ด้วย remove และ autoremove ───────────────────────
# ⚠️ dnf remove ลบ Package อื่นที่พึ่งพา Package นั้นไปด้วย การใส่ -y ทำให้ไม่มีโอกาสอ่านรายการก่อนลบ บน server งานจริงให้รันโดยไม่ใส่ -y ก่อน อ่านส่วน Removing dependent packages ให้ครบ แล้วจึงตอบ y ห้ามลบ Package หลักของระบบอย่าง systemd, openssh-server หรือ NetworkManager ผ่าน SSH เพราะเครื่องจะเข้าไม่ได้ทันที
sudo dnf remove bind-utils

sudo dnf remove --assumeno openssh-server


# ── ดูประวัติและย้อนการติดตั้งด้วย dnf history ──────────────────
sudo dnf history list

sudo dnf history info 4

# ⚠️ dnf history undo ลบหรือ Downgrade Package ตามที่ Transaction นั้นเปลี่ยนไว้ ถ้าย้อน Transaction ของการอัปเดต อาจได้ Package รุ่นเก่าที่มีช่องโหว่กลับมา ให้รันโดยไม่ใส่ -y และอ่านรายการก่อนตอบ y เสมอ
sudo dnf history undo 4
rpm -q bind-utils


# ── เพิ่ม Repository CRB และ EPEL ───────────────────────────────
sudo dnf config-manager --set-enabled crb
sudo dnf install -y epel-release
dnf repolist

sudo dnf install -y htop
dnf info htop | grep -E '^(Version|Repository|From repo)'
htop


# ── ขั้นที่ 1 ตรวจจุดเริ่มต้น ───────────────────────────────────
# [Host PC] VBoxManage snapshot server list
# [Host PC] ssh admin@192.168.56.10
rpm -q nano tar tree bash-completion


# ── ขั้นที่ 2 สำรวจข้อมูลพื้นฐาน ────────────────────────────────
hostname
cat /etc/rocky-release
uname -r
uptime
nproc
free -h
df -h /


# ── ขั้นที่ 3 ฝึก path, wildcard, redirection และ pipe ──────────
mkdir -p ~/lab02/logs
cd ~/lab02/logs
touch app-2026-10-{30,31}.log app-2026-11-0{1,2}.log
ls app-2026-11-*
ls ../../projects
ls /etc/hostname /nothing > out.txt 2> err.txt
cat out.txt err.txt
ls /etc | wc -l > etc-count.txt
cat etc-count.txt
sudo grep -Ev '^\s*(#|$)' /etc/ssh/sshd_config | tee sshd-effective.txt
cd ~


# ── ขั้นที่ 4 ตรวจเครือข่ายของ VM ───────────────────────────────
ip -br link
ip -br addr
ip route
ping -c 3 10.0.2.2
ping -c 3 1.1.1.1
ping -c 3 one.one.one.one
sudo ss -tlnp
nmcli device status

# [Host PC] ping 192.168.56.10
# [Host PC] Test-NetConnection 192.168.56.10 -Port 22


# ── ขั้นที่ 5 ฝึกจัดการ Service ─────────────────────────────────
systemctl status sshd --no-pager | head -3
sudo systemctl stop chronyd
systemctl is-active chronyd; systemctl is-enabled chronyd
sudo systemctl disable --now chronyd
systemctl is-active chronyd; systemctl is-enabled chronyd
sudo systemctl enable --now chronyd
systemctl is-active chronyd; systemctl is-enabled chronyd
systemctl --failed


# ── ขั้นที่ 6 สร้างเหตุการณ์แล้วหาใน Log ────────────────────────
sudo journalctl -u sshd -f

# [Host PC] ssh admin@192.168.56.10
exit

sudo journalctl -u sshd --since today -g 'Failed password' --no-pager | wc -l
sudo journalctl -u sshd --since today | grep 'Failed password' | grep -oE 'from [0-9.]+' | sort | uniq -c | sort -rn
sudo journalctl -p err -b --no-pager


# ── ขั้นที่ 7 ใช้ dnf ───────────────────────────────────────────
sudo dnf config-manager --set-enabled crb
sudo dnf install -y epel-release
dnf repolist
sudo dnf install -y htop
rpm -qf $(command -v htop)
sudo dnf history list | head -6
htop


# ── ตรวจสอบผลลัพธ์ ──────────────────────────────────────────────
# [Host PC] VBoxManage controlvm server acpipowerbutton
# [Host PC] VBoxManage list runningvms


# ── เครื่องมือที่มีมาให้ ────────────────────────────────────────
# [Ubuntu]
command -v nano htop tree
# [Ubuntu]
sudo apt install -y tree


# ── apt แทน dnf ─────────────────────────────────────────────────
# [Ubuntu]
sudo apt update
# [Ubuntu]
apt list --upgradable 2>/dev/null | head -3
# [Ubuntu]
dpkg -S /usr/bin/ss
# [Ubuntu]
grep -A3 'Start-Date' /var/log/apt/history.log | tail -4


# ── ชื่อ Service และ systemctl ──────────────────────────────────
# [Ubuntu]
systemctl is-active ssh.socket ssh chrony
# [Ubuntu]
sudo journalctl -u ssh -n 2 -o cat


# ── ดูสถานะเครือข่ายบน Ubuntu ───────────────────────────────────
# [Ubuntu]
networkctl
# [Ubuntu]
resolvectl dns enp0s3

# [Ubuntu]
sudo ls /etc/netplan/


# ── Log Files ที่ต่างกัน ────────────────────────────────────────
# [Ubuntu]
grep -c 'Failed password' /var/log/auth.log
# [Ubuntu]
sudo journalctl -u ssh --since today -g 'Failed password' --no-pager | wc -l
