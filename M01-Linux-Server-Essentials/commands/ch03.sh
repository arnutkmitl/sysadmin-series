#!/usr/bin/env bash
# บทที่ 3 จัดการ Users และ Permissions
# SysAdmin Pocket Series M01 Linux Server Essentials (Rocky Linux 10.2)
#
# ไฟล์นี้รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# คำสั่งที่ไม่มีป้ายรันบน server ส่วนบรรทัดที่มีป้าย [Host PC] รันใน PowerShell บน Windows
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1
# [Host PC] VBoxManage controlvm server acpipowerbutton
# [Host PC] VBoxManage snapshot server take ch03-start --description "ก่อนเริ่มบทที่ 3"
# [Host PC] VBoxManage snapshot server list


# ── ไฟล์ /etc/passwd ────────────────────────────────────────────
getent passwd admin
awk -F: '$3 >= 1000 && $3 < 65534 {print $1, $3, $7}' /etc/passwd

grep nologin /etc/passwd | head -3


# ── ไฟล์ /etc/shadow ────────────────────────────────────────────
ls -l /etc/passwd /etc/shadow
cat /etc/shadow

sudo getent shadow admin

sudo awk -F: '$2 ~ /^!/ || $2 == "" {print $1, substr($2,1,2)}' /etc/shadow | grep -v -E '^(bin|daemon|adm|lp|sync|shutdown|halt|mail|operator|games|ftp|nobody)'


# ── ไฟล์ /etc/group และ /etc/gshadow ────────────────────────────
getent group wheel admin

id
id admin

# ⚠️ อย่าแก้ `/etc/passwd`, `/etc/shadow` หรือ `/etc/group` ด้วย nano โดยตรง ถ้าพิมพ์เครื่องหมาย `:` ขาดไปตัวเดียว บัญชีนั้นอาจ Login ไม่ได้ทันที ถ้าเป็นบรรทัดของ admin คุณจะเสียทั้งการ Login และ sudo ให้ใช้ useradd, usermod, groupmod หรือ chage ถ้าจำเป็นต้องแก้มือจริง ๆ ให้ใช้ `sudo vipw` และ `sudo vigr` ซึ่งล็อกไฟล์ระหว่างแก้
sudo pwck -r
sudo grpck -r
echo $?


# ── ดูค่าเริ่มต้นก่อนสร้าง ──────────────────────────────────────
sudo useradd -D

grep -E '^(CREATE_HOME|UID_MIN|UMASK|USERGROUPS_ENAB|PASS_MAX_DAYS|PASS_MIN_DAYS|PASS_WARN_AGE|ENCRYPT_METHOD)' /etc/login.defs


# ── สร้าง User ด้วย useradd ─────────────────────────────────────
sudo useradd -m -s /bin/bash -c "Web Master" webmaster
ls -la /home/webmaster


# ── ตั้ง Password ให้ User ──────────────────────────────────────
sudo passwd webmaster

echo 'webmaster:Temp-2026-Nov!' | sudo chpasswd


# ── ตรวจข้อมูล User ─────────────────────────────────────────────
id webmaster
getent passwd webmaster

getent passwd admin webmaster alice
echo $?
getent passwd webmaster || sudo useradd -m -s /bin/bash -c "Web Master" webmaster


# ── เพิ่ม User เข้า Group wheel เพื่อให้ใช้ sudo ได้ ────────────
sudo usermod -aG wheel webmaster
id webmaster


# ── แก้ไขและลบ User ─────────────────────────────────────────────
sudo useradd -m -s /bin/bash -c "Temp Test" tempuser
sudo dnf install -y zsh
grep zsh /etc/shells
sudo usermod -s /bin/zsh -c "Temp Test (zsh)" tempuser
getent passwd tempuser

sudo usermod -s /sbin/nologin tempuser
sudo su - tempuser

# ⚠️ `userdel -r` ลบ Home Directory และไฟล์ทั้งหมดของ User ทันทีโดยไม่ถามยืนยัน และกู้คืนไม่ได้ ตรวจชื่อ User ให้ถูกก่อนกด Enter และสำรอง Home ไว้ก่อนเสมอ ไฟล์ของ User ที่อยู่นอก Home เช่นใน `/projects` จะไม่ถูกลบ แต่จะเหลือเป็นเลข UID แทนชื่อ
sudo tar czf /root/tempuser-home-$(date +%F).tar.gz -C /home tempuser
sudo userdel -r tempuser
getent passwd tempuser
sudo ls /root

sudo find / -xdev -user webmaster -not -path '/home/webmaster/*' 2>/dev/null
sudo find / -xdev -nouser 2>/dev/null


# ── ดูอายุรหัสผ่านด้วย chage -l ─────────────────────────────────
chage -l admin


# ── กำหนดอายุรหัสผ่าน ───────────────────────────────────────────
sudo chage -M 90 -m 1 -W 7 webmaster
sudo chage -l webmaster

sudo chage -d 0 webmaster
sudo chage -l webmaster | head -2

sudo chage -E $(date -d '+90 days' +%F) webmaster
sudo chage -l webmaster | grep 'Account expires'

sudo chage -E -1 webmaster
sudo passwd webmaster


# ── กำหนดความแข็งแรงของรหัสผ่าน ─────────────────────────────────
printf 'minlen = 12\nminclass = 3\n' | sudo tee /etc/security/pwquality.conf.d/50-lab.conf

sudo chage -m 0 webmaster
sudo -u webmaster passwd


# ── ล็อกและปลดล็อกบัญชี ─────────────────────────────────────────
sudo passwd -l webmaster
sudo passwd -S webmaster
sudo getent shadow webmaster | cut -c1-15
sudo passwd -u webmaster
sudo passwd -S webmaster

sudo usermod -L -e 1 webmaster
sudo chage -l webmaster | grep 'Account expires'
sudo usermod -U -e '' webmaster
sudo chage -l webmaster | grep 'Account expires'


# ── สร้าง Group และเพิ่มสมาชิก ──────────────────────────────────
sudo groupadd webadmin
sudo groupadd devteam
sudo groupadd webadmin
getent group webadmin devteam

sudo usermod -aG webadmin,devteam webmaster
sudo gpasswd -a webmaster webadmin
id webmaster
groups webmaster


# ── ตรวจสอบ Group ───────────────────────────────────────────────
awk -F: '$3 >= 1000 && $3 < 65534' /etc/group
getent group wheel


# ── เอาสมาชิกออกและลบ Group ─────────────────────────────────────
sudo gpasswd -d webmaster devteam
sudo groupdel devteam
getent group devteam


# ── Scenario ทีมดูแลเว็บใช้ Directory ร่วมกัน ───────────────────
getent group webadmin || sudo groupadd webadmin
sudo usermod -aG webadmin admin
sudo mkdir -p /srv/web
sudo chown root:webadmin /srv/web
sudo chmod 2775 /srv/web
ls -ld /srv/web

touch /srv/web/test.html
sudo -u admin touch /srv/web/test.html
ls -l /srv/web/test.html


# ── ใช้ chmod เปลี่ยน Permission ────────────────────────────────
cd ~
mkdir -p bin && touch bin/backup.sh script.sh config.conf readme.txt secret.txt myfile.txt
ls -l script.sh secret.txt

chmod 755 ~/bin/backup.sh
chmod 600 ~/secret.txt
ls -l ~/bin/backup.sh ~/secret.txt

sudo find /srv/site -type d -exec chmod 755 {} +
sudo find /srv/site -type f -exec chmod 644 {} +

chmod u+x script.sh
chmod g-w config.conf
chmod o= readme.txt
chmod u=rw,g=r,o= secret.txt
ls -l script.sh config.conf readme.txt secret.txt


# ── ใช้ chown เปลี่ยนเจ้าของไฟล์ ────────────────────────────────
sudo chown webmaster myfile.txt
sudo chown webmaster:webadmin myfile.txt
sudo chown :webadmin config.conf
ls -l myfile.txt config.conf

sudo chown -R webmaster:webadmin /srv/web/
stat /srv/web/


# ── umask กำหนดสิทธิ์ของไฟล์ที่สร้างใหม่ ────────────────────────
umask
umask -S
sudo touch /tmp/by-root.txt && ls -l /tmp/by-root.txt

mkdir ~/umask-test && cd ~/umask-test
umask 077
touch private.txt && mkdir private-dir
ls -l
umask 022
cd ~


# ── Set-UID, Set-GID และ Sticky Bit ─────────────────────────────
ls -l /usr/bin/passwd
sudo find / -xdev -perm /6000 -type f 2>/dev/null | sudo tee /root/suid-baseline-$(date +%F).txt

# ⚠️ อย่าตั้ง Set-UID ให้สคริปต์หรือโปรแกรมที่เขียนเอง ถ้าโปรแกรมนั้นมีช่องโหว่ ผู้ใช้ทุกคนจะได้สิทธิ์ของเจ้าของไฟล์ ถ้าเจ้าของเป็น root ก็เท่ากับยกเครื่องให้ ถ้าต้องการให้ผู้ใช้รันคำสั่งบางอย่างด้วยสิทธิ์ root ให้ใช้ sudo แบบจำกัดคำสั่งตามหัวข้อ 3.6
sudo mkdir -p /srv/lab3/share
sudo chown root:webadmin /srv/lab3/share
sudo chmod 775 /srv/lab3/share
sudo chmod g+s /srv/lab3/share
ls -ld /srv/lab3/share

stat -c '%A %a %U:%G %n' /tmp

sudo mkdir /srv/lab3/dropbox
sudo chmod 1777 /srv/lab3/dropbox
touch /srv/lab3/dropbox/admin-note.txt
sudo -u webmaster rm -f /srv/lab3/dropbox/admin-note.txt
sudo -u webmaster touch /srv/lab3/dropbox/wm-note.txt
sudo -u webmaster rm -f /srv/lab3/dropbox/wm-note.txt


# ── ทำไมต้องรู้ ─────────────────────────────────────────────────
rpm -q acl || sudo dnf install -y acl


# ── ดูและตั้ง ACL ───────────────────────────────────────────────
sudo mkdir -p /srv/lab3/reports
sudo chown admin:admin /srv/lab3/reports
echo "Q4 budget draft" > /srv/lab3/reports/q4.txt
chmod 640 /srv/lab3/reports/q4.txt
sudo -u webmaster cat /srv/lab3/reports/q4.txt

setfacl -m u:webmaster:r /srv/lab3/reports/q4.txt
ls -l /srv/lab3/reports/q4.txt
getfacl /srv/lab3/reports/q4.txt
sudo -u webmaster cat /srv/lab3/reports/q4.txt


# ── mask ตัวจำกัดสิทธิ์สูงสุดของ ACL ────────────────────────────
setfacl -m u:webmaster:rw /srv/lab3/reports/q4.txt
chmod 640 /srv/lab3/reports/q4.txt
getfacl --omit-header /srv/lab3/reports/q4.txt


# ── Default ACL สำหรับไฟล์ที่จะสร้างในอนาคต ─────────────────────
setfacl -m u:webmaster:rx /srv/lab3/reports
setfacl -d -m u:webmaster:r /srv/lab3/reports
echo "Q1 plan" > /srv/lab3/reports/q1.txt
getfacl --omit-header /srv/lab3/reports/q1.txt

getfacl --omit-header /srv/lab3/reports


# ── ลบ ACL ──────────────────────────────────────────────────────
setfacl -k /srv/lab3/reports
setfacl -x u:webmaster /srv/lab3/reports
setfacl -b /srv/lab3/reports/q4.txt /srv/lab3/reports/q1.txt
getfacl -R --omit-header /srv/lab3/reports 2>/dev/null | grep -c webmaster
ls -l /srv/lab3/reports


# ── ไฟล์ /etc/sudoers และ visudo ────────────────────────────────
sudo grep -E '^%wheel|includedir' /etc/sudoers

sudo visudo
sudo EDITOR=nano visudo


# ── สร้างไฟล์ใน /etc/sudoers.d/ (วิธีที่แนะนำ) ──────────────────
echo 'webmaster ALL=(ALL) ALL' > /tmp/webmaster.sudo
sudo visudo -cf /tmp/webmaster.sudo
sudo install -m 0440 -o root -g root /tmp/webmaster.sudo /etc/sudoers.d/webmaster
ls -l /etc/sudoers.d/

echo 'webmaster ALL=(ALL) /usr/bin/systemctl restart nginx,' > /tmp/bad.sudo
sudo visudo -cf /tmp/bad.sudo
echo $?

sudo visudo -c


# ── ให้สิทธิ์เฉพาะคำสั่งที่จำเป็น (Least Privilege) ─────────────
command -v systemctl
echo 'webmaster ALL=(ALL) /usr/bin/systemctl restart nginx, /usr/bin/systemctl reload nginx, /usr/bin/systemctl status nginx' > /tmp/webmaster.sudo
sudo visudo -cf /tmp/webmaster.sudo
sudo install -m 0440 -o root -g root /tmp/webmaster.sudo /etc/sudoers.d/webmaster

sudo gpasswd -d webmaster wheel
sudo -l -U webmaster


# ── sudo แบบ Group และแบบไม่ต้องใส่รหัสผ่าน ─────────────────────
echo '%webadmin ALL=(ALL) /usr/bin/systemctl restart nginx, /usr/bin/systemctl reload nginx' > /tmp/webadmin.sudo
sudo visudo -cf /tmp/webadmin.sudo && sudo install -m 0440 -o root -g root /tmp/webadmin.sudo /etc/sudoers.d/webadmin-group

echo 'deploy ALL=(root) NOPASSWD: /usr/bin/systemctl restart myapp' > /tmp/deploy.sudo
sudo visudo -cf /tmp/deploy.sudo


# ── ทดสอบสิทธิ์จริง ─────────────────────────────────────────────
su - webmaster
sudo systemctl status nginx
sudo dnf install -y httpd
exit


# ── Defaults ที่ควรรู้ ──────────────────────────────────────────
printf 'Defaults timestamp_timeout=2\nDefaults log_output\n' > /tmp/defaults.sudo
sudo visudo -cf /tmp/defaults.sudo


# ── อ่าน Log ด้วย journalctl ────────────────────────────────────
sudo journalctl -t sudo -n 6 --no-pager

sudo journalctl -t sudo --since "2026-11-02 08:00" --until "2026-11-02 18:00" -g 'not allowed|NOT in sudoers|incorrect password'


# ── อ่านจากไฟล์ /var/log/secure ─────────────────────────────────
rpm -q rsyslog
sudo grep 'sudo\[' /var/log/secure | grep COMMAND | tail -3


# ── ขั้นที่ 1 ล้างบัญชีและไฟล์ตัวอย่างจากหัวข้อก่อน ─────────────
getent passwd webmaster tempuser alice bob charlie
getent group webadmin devteam webdev webdesign
ls /etc/sudoers.d/

# ⚠️ คำสั่งชุดนี้ลบบัญชี webmaster พร้อม Home Directory ลบไฟล์สิทธิ์ sudo และลบโฟลเดอร์ `/srv/web` กับ `/srv/lab3` ทั้งโฟลเดอร์อย่างถาวร ตรวจชื่อให้ตรงก่อนกด Enter อย่าลบไฟล์อื่นใน `/etc/sudoers.d/` ที่คุณไม่ได้สร้างเอง ถ้าไม่แน่ใจ ให้ย้อน Snapshot ch03-start แทน
sudo rm -f /etc/sudoers.d/webmaster /etc/sudoers.d/webadmin-group /etc/sudoers.d/deploy
sudo userdel -r webmaster
getent passwd tempuser && sudo userdel -r tempuser
getent group devteam && sudo groupdel devteam
getent group webadmin && sudo groupdel webadmin
rm -f ~/myfile.txt ~/script.sh ~/config.conf ~/readme.txt ~/secret.txt ~/bin/backup.sh /tmp/*.sudo
rmdir ~/bin
rm -rf ~/umask-test
sudo rm -rf /srv/lab3
sudo rm -rf /srv/web
sudo rm -f /tmp/by-root.txt
sudo visudo -c
id admin


# ── ขั้นที่ 2 สร้าง Users สามคนและตั้งรหัสผ่าน ──────────────────
sudo useradd -m -s /bin/bash -c "Alice Lead Developer" alice
sudo useradd -m -s /bin/bash -c "Bob Developer" bob
sudo useradd -m -s /bin/bash -c "Charlie Designer" charlie
sudo passwd alice
sudo passwd bob
sudo passwd charlie


# ── ขั้นที่ 3 ตั้งนโยบายรหัสผ่านของทีม ──────────────────────────
for u in alice bob charlie; do sudo chage -M 90 -m 1 -W 7 "$u"; done
sudo chage -E $(date -d '+90 days' +%F) charlie
sudo chage -d 0 charlie
sudo chage -l charlie


# ── ขั้นที่ 4 สร้าง Groups และเพิ่มสมาชิก ───────────────────────
sudo groupadd webdev
sudo groupadd webdesign
for u in alice bob charlie; do sudo gpasswd -a "$u" webdev; done
sudo gpasswd -a charlie webdesign


# ── ขั้นที่ 5 ให้ alice ใช้ sudo เฉพาะคำสั่งของ nginx ───────────
echo 'alice ALL=(ALL) /usr/bin/systemctl restart nginx, /usr/bin/systemctl reload nginx, /usr/bin/systemctl status nginx' > /tmp/alice-nginx.sudo
sudo visudo -cf /tmp/alice-nginx.sudo && sudo install -m 0440 -o root -g root /tmp/alice-nginx.sudo /etc/sudoers.d/alice-nginx
sudo visudo -c
rm /tmp/alice-nginx.sudo


# ── ขั้นที่ 6 สร้าง Shared Directory พร้อม Set-GID ──────────────
sudo mkdir -p /projects/webapp/assets
sudo chown root:webdev /projects/webapp
sudo chmod 2775 /projects/webapp
sudo chown root:webdesign /projects/webapp/assets
sudo chmod 2775 /projects/webapp/assets
sudo setfacl -d -m g::rwx /projects/webapp
ls -ld /projects/webapp /projects/webapp/assets
getfacl --omit-header /projects/webapp


# ── ขั้นที่ 7 ให้ bob เขียนใน assets ได้ด้วย ACL ────────────────
sudo setfacl -m u:bob:rwx /projects/webapp/assets
sudo setfacl -d -m u:bob:rwx /projects/webapp/assets
getfacl /projects/webapp/assets


# ── ขั้นที่ 8 ทดสอบสิทธิ์และตรวจผลลัพธ์ ─────────────────────────
su - alice
touch /projects/webapp/test-alice.txt
ls -l /projects/webapp/test-alice.txt
sudo systemctl status nginx
exit

su - bob
touch /projects/webapp/assets/bob-logo.svg
ls -l /projects/webapp/assets/
exit

sudo -u charlie touch /projects/webapp/assets/style.css
sudo -u bob sh -c 'echo "/* bob edit */" >> /projects/webapp/assets/style.css'
ls -l /projects/webapp/assets/style.css

sudo useradd -m -s /bin/bash outsider
sudo -u outsider ls /projects/webapp
sudo -u outsider touch /projects/webapp/test-outsider.txt

# ⚠️ ลบ User ทดสอบทันทีหลังใช้เสร็จ `userdel -r` ลบ Home ของ outsider ด้วย ตรวจชื่อให้ตรงก่อนกด Enter
sudo userdel -r outsider

id alice; id bob; id charlie
sudo -l -U alice | tail -2


# ── ขั้นที่ 1 ตรวจเครือข่าย Host-Only และ sshd ฝั่ง server ──────
ip -br addr show
sudo ss -tlnp | grep sshd


# ── ขั้นที่ 2 ทดสอบเส้นทางจาก Host PC ───────────────────────────
# [Host PC] ping -n 2 192.168.56.10
# [Host PC] Test-NetConnection 192.168.56.10 -Port 22


# ── ขั้นที่ 3 SSH เข้าในนาม alice แล้วทดสอบสิทธิ์ ───────────────
# [Host PC] ssh alice@192.168.56.10


touch /projects/webapp/from-hostpc.txt
ls -l /projects/webapp/from-hostpc.txt
sudo dnf install -y zsh
touch /projects/webapp/assets/alice.css
exit


# ── ขั้นที่ 4 SSH เข้าในนาม charlie ซึ่งถูกบังคับเปลี่ยนรหัสผ่าน ────
# [Host PC] ssh charlie@192.168.56.10

# [Host PC] ssh charlie@192.168.56.10
touch /projects/webapp/assets/banner.png
ls -l /projects/webapp/assets/banner.png
sudo -l
exit


# ── ขั้นที่ 5 ตรวจว่าใครเข้ามาจากที่ไหน และใช้ sudo ทำอะไร ──────
who
sudo journalctl -u sshd --since today -g 'Accepted|password for'

sudo journalctl -t sudo --since today -g 'alice :|charlie :' --no-pager


# ── สร้าง User admin บน Ubuntu ──────────────────────────────────
# [Ubuntu]
sudo useradd -m -g admin -G sudo -s /bin/bash admin
# [Ubuntu]
sudo passwd admin
# [Ubuntu]
id admin


# ── adduser ของ Ubuntu ──────────────────────────────────────────
# [Ubuntu]
sudo adduser alice
# [Ubuntu]
sudo adduser --disabled-password --comment "Bob Developer" bob
# [Ubuntu]
sudo adduser bob webdev
# [Ubuntu]
id bob


# ── /etc/shadow และนโยบายรหัสผ่าน ───────────────────────────────
# [Ubuntu]
ls -l /etc/shadow
# [Ubuntu]
sudo passwd -S alice

# [Ubuntu]
sudo apt install -y libpam-pwquality acl
# [Ubuntu]
printf 'minlen = 12\nminclass = 3\n' | sudo tee /etc/security/pwquality.conf.d/50-lab.conf


# ── sudo-rs บน Ubuntu 26.04 ─────────────────────────────────────
# [Ubuntu]
sudo --version
# [Ubuntu]
echo 'alice ALL=(ALL) /usr/bin/systemctl restart nginx, /usr/bin/systemctl reload nginx, /usr/bin/systemctl status nginx' > /tmp/alice-nginx.sudo
# [Ubuntu]
sudo visudo -cf /tmp/alice-nginx.sudo && sudo install -m 0440 -o root -g root /tmp/alice-nginx.sudo /etc/sudoers.d/alice-nginx
# [Ubuntu]
sudo visudo -c


# ── Log บน Ubuntu ───────────────────────────────────────────────
# [Ubuntu]
sudo grep -E 'sudo.*COMMAND' /var/log/auth.log | tail -5
# [Ubuntu]
sudo journalctl -u ssh --since today -g Accepted
