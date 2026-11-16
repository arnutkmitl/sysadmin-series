#!/usr/bin/env bash
# บทที่ 5 ตั้งค่า Firewall และ SELinux
# SysAdmin Pocket Series M01 Linux Server Quickstart ฉบับปรับปรุง (Rocky Linux 10.2)
#
# ไฟล์นี้รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# คำสั่งที่ไม่มีป้ายรันบน server ส่วนบรรทัดที่มีป้าย [Host PC] รันใน PowerShell บน Windows
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1
# [Host PC] VBoxManage list runningvms
# [Host PC] VBoxManage snapshot server take ch05-start --description "ก่อนเริ่มบทที่ 5"
# [Host PC] VBoxManage startvm server --type headless


# ── Zone ────────────────────────────────────────────────────────
sudo firewall-cmd --state
sudo firewall-cmd --get-default-zone
sudo firewall-cmd --get-active-zones

sudo firewall-cmd --get-active-zones
sudo firewall-cmd --get-zones


# ── Service และ Port ────────────────────────────────────────────
sudo firewall-cmd --get-services | wc -w
sudo firewall-cmd --info-service=http
sudo firewall-cmd --info-service=cockpit

grep -l 'port="5432"' /usr/lib/firewalld/services/*.xml
sudo firewall-cmd --info-service=postgresql | grep ports


# ── Runtime กับ Permanent ───────────────────────────────────────
sudo firewall-cmd --add-port=8080/tcp
sudo firewall-cmd --list-ports
sudo firewall-cmd --permanent --list-ports
sudo firewall-cmd --reload
sudo firewall-cmd --list-ports

sudo firewall-cmd --add-port=8443/tcp --timeout=30m
sudo firewall-cmd --list-ports


# ── 5.2 อ่านผล firewall-cmd --list-all ──────────────────────────
sudo firewall-cmd --list-all

sudo firewall-cmd --permanent --list-all | grep -E 'services|ports'

diff <(sudo firewall-cmd --list-all) <(sudo firewall-cmd --permanent --list-all)

sudo firewall-cmd --query-port=2222/tcp
sudo firewall-cmd --query-service=ssh
sudo firewall-cmd --query-service=ssh || echo "ssh(22) ปิดอยู่"


# ── เปิด ────────────────────────────────────────────────────────
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
sudo firewall-cmd --list-services

sudo firewall-cmd --permanent --add-port=8080/tcp --add-service=https
sudo firewall-cmd --reload
sudo firewall-cmd --list-ports

sudo firewall-cmd --permanent --add-port=2222/tcp


# ── ปิด ─────────────────────────────────────────────────────────
# ⚠️ คำสั่ง `--remove-service` และ `--remove-port` ตัดการเชื่อมต่อใหม่ไปยังพอร์ตนั้นทันทีหลัง reload ห้ามลบพอร์ตที่ SSH ใช้อยู่ (2222/tcp) และห้ามลบ ssh ก่อนยืนยันว่า 2222/tcp อยู่ในชุด permanent แล้ว เปิด Session เดิมค้างไว้จนทดสอบ Session ใหม่ผ่าน
sudo firewall-cmd --permanent --remove-port=8080/tcp
sudo firewall-cmd --reload
sudo firewall-cmd --permanent --remove-port=3306/tcp

sudo firewall-cmd --permanent --remove-service=postgresql
sudo firewall-cmd --reload
sudo firewall-cmd --query-service=postgresql; sudo firewall-cmd --permanent --query-service=postgresql


# ── ดูไฟล์ที่ firewalld เขียน ───────────────────────────────────
sudo cat /etc/firewalld/zones/public.xml


# ── ทำไมต้องลบ cockpit, dhcpv6-client และ ssh ───────────────────
sudo ss -tulnp

sudo firewall-cmd --permanent --remove-service=cockpit --remove-service=dhcpv6-client
sudo firewall-cmd --reload
sudo firewall-cmd --list-services

sudo firewall-cmd --list-ports
sudo ss -tlnH | awk '{print $4}' | grep -E ':(3000|5601)$'


# ── ตรวจ Mode ปัจจุบัน ──────────────────────────────────────────
getenforce
sestatus

for h in web01 web02 db01; do printf "%s: " $h; ssh $h getenforce; done


# ── เปลี่ยน Mode ชั่วคราว ───────────────────────────────────────
# ⚠️ `setenforce 0` ปิดการบังคับใช้ SELinux ทั้งเครื่องทันที ทุก service ที่เคยถูกจำกัดจะทำได้ทุกอย่างที่ Permission ปกติอนุญาต ใช้ได้ไม่กี่นาทีเพื่อยืนยันสาเหตุ แล้วต้องสั่ง `setenforce 1` กลับในหน้าต่างเดิมทันที
sudo setenforce 0
getenforce
sudo setenforce 1
getenforce

sudo semanage permissive -a httpd_t
sudo semanage permissive -l
sudo semanage permissive -d httpd_t


# ── เปลี่ยน Mode ถาวร ───────────────────────────────────────────
grep '^SELINUX=' /etc/selinux/config

sudo sed -i 's/^SELINUX=permissive/SELINUX=enforcing/' /etc/selinux/config
grep '^SELINUX=' /etc/selinux/config


# ── ดู Context ของไฟล์ด้วย ls -Z ────────────────────────────────
ls -Z ~/.ssh/authorized_keys /etc/ssh/ssh_host_ed25519_key /etc/shadow
ls -ldZ /home/admin /tmp

ls -Z /home/bob/.ssh/authorized_keys
sudo restorecon -v /home/bob/.ssh/authorized_keys


# ── ดู Context ของ Process ด้วย ps -Z และ id -Z ─────────────────
id -Z
ps -eZ | grep -E 'sshd|chronyd|auditd'

ps -eZ | grep -E 'nginx|myapp'


# ── ดูป้ายของพอร์ต ──────────────────────────────────────────────
sudo semanage port -l | grep -w ssh_port_t
sudo semanage port -l | grep -E '^http_(port|cache_port)_t'

sudo semanage port -l -C


# ── เพิ่ม แก้ และลบป้าย ─────────────────────────────────────────
sudo semanage port -l | grep -w 2223
sudo semanage port -a -t ssh_port_t -p tcp 2223
sudo semanage port -l | grep -w ssh_port_t
sudo semanage port -d -t ssh_port_t -p tcp 2223

sudo semanage port -a -t http_port_t -p tcp 8080
sudo semanage port -m -t http_port_t -p tcp 8080
sudo semanage port -l | grep -w 8080


# ── ดูค่า Boolean ───────────────────────────────────────────────
getsebool -a | wc -l
getsebool httpd_can_network_connect
sudo semanage boolean -l | grep httpd_can_network_connect

getsebool -a | grep ^ssh


# ── เปลี่ยนค่าด้วย setsebool ────────────────────────────────────
sudo setsebool httpd_can_network_connect on
sudo semanage boolean -l | grep 'httpd_can_network_connect '
sudo setsebool httpd_can_network_connect off
getsebool httpd_can_network_connect

sudo setsebool -P httpd_can_network_connect on
getsebool httpd_can_network_connect
sudo semanage boolean -l -C


# ── ausearch ────────────────────────────────────────────────────
sudo ausearch -m avc -ts recent

sudo ausearch -m avc -c nginx -ts today -i | grep denied


# ── audit2why ───────────────────────────────────────────────────
sudo ausearch -m avc -ts recent | audit2why


# ── sealert ─────────────────────────────────────────────────────
sudo dnf install -y setroubleshoot-server
sudo systemctl reboot

sudo journalctl -t setroubleshoot --since "10 min ago"
sudo sealert -l 523166d4-542f-4269-8f44-bdd39e732e6c


# ── restorecon และ matchpathcon ─────────────────────────────────
echo "lab selinux" > ~/selinux-demo.conf
sudo mv ~/selinux-demo.conf /etc/
ls -Z /etc/selinux-demo.conf
matchpathcon /etc/selinux-demo.conf
sudo restorecon -v /etc/selinux-demo.conf

sudo restorecon -Rnv /etc/ssh
sudo restorecon -Rv /etc/ssh


# ── semanage fcontext สำหรับ path ที่ไม่ใช่ค่ามาตรฐาน ───────────
sudo semanage fcontext -a -t httpd_sys_content_t "/data/web(/.*)?"
sudo restorecon -Rv /data/web
sudo semanage fcontext -l -C


# ── Test-NetConnection บน Windows ───────────────────────────────
# [Host PC] Test-NetConnection 192.168.56.10 -Port 2222

# [Host PC] Test-NetConnection 192.168.56.10 -Port 3306

# [Host PC] Test-NetConnection intranet.example.local -Port 443 -InformationLevel Quiet


# ── nc บน Linux และ macOS ───────────────────────────────────────
nc -zv -w 3 192.168.56.10 2222
nc -zv -w 3 192.168.56.10 3306

nc -zv -w 3 10.10.20.15 5432


# ── curl สำหรับพอร์ตของเว็บ ─────────────────────────────────────
# [Host PC] curl.exe -I http://192.168.56.10/

curl -I --connect-timeout 5 https://www.example.com/


# ── ขั้นที่ 1 ตรวจสถานะและสำรอง ─────────────────────────────────
sudo firewall-cmd --get-active-zones
sudo firewall-cmd --list-all | grep -E 'services|ports'
sudo cp -a /etc/firewalld /root/firewalld-before-ch05
sudo ls /root/firewalld-before-ch05/zones


# ── ขั้นที่ 2 ทดลองกฎแบบ runtime ────────────────────────────────
sudo firewall-cmd --add-port=8080/tcp
mkdir -p ~/fwtest && cd ~/fwtest && echo "server firewall test" > index.html
python3 -m http.server 8080

# [Host PC] Test-NetConnection 192.168.56.10 -Port 8080 -InformationLevel Quiet

sudo firewall-cmd --reload
sudo firewall-cmd --list-ports
python3 -m http.server 8080

# [Host PC] Test-NetConnection 192.168.56.10 -Port 8080 -InformationLevel Quiet


# ── ขั้นที่ 3 เปิด http และ https แบบ permanent ─────────────────
sudo firewall-cmd --permanent --add-service=http --add-service=https
sudo firewall-cmd --permanent --add-port=2222/tcp
sudo firewall-cmd --permanent --list-ports


# ── ขั้นที่ 4 ลบสิ่งที่ไม่จำเป็น ────────────────────────────────
# ⚠️ ขั้นนี้ลบ service ออกจาก Firewall รวมถึง ssh (พอร์ต 22) ถ้ายังค้างอยู่ ทำต่อเมื่อขั้นที่ 3 แสดง 2222/tcp ในชุด permanent แล้วเท่านั้น ถ้าเข้าเครื่องไม่ได้หลัง reload ให้แก้จากหน้าต่าง Console ของ VM หรือ Restore Snapshot ch05-start
sudo firewall-cmd --permanent --remove-service=cockpit --remove-service=dhcpv6-client
sudo firewall-cmd --permanent --query-service=ssh && sudo firewall-cmd --permanent --remove-service=ssh
sudo firewall-cmd --reload
sudo firewall-cmd --list-all | grep -E 'services|ports'


# ── ขั้นที่ 5 ทดสอบทุกพอร์ตจาก Host PC ──────────────────────────
cd ~/fwtest
sudo python3 -m http.server 80

# [Host PC] ssh server hostname
# [Host PC] curl.exe -I http://192.168.56.10/
# [Host PC] Test-NetConnection 192.168.56.10 -Port 443 -InformationLevel Quiet
# [Host PC] Test-NetConnection 192.168.56.10 -Port 3306 -InformationLevel Quiet
# [Host PC] Test-NetConnection 192.168.56.10 -Port 22 -InformationLevel Quiet

curl -sI http://192.168.56.10/ | head -1
nc -zv -w 3 192.168.56.10 443
nc -zv -w 3 192.168.56.10 3306
nc -zv -w 3 192.168.56.10 22


# ── ขั้นที่ 6 ปิดโปรแกรมทดสอบและตรวจสถานะสุดท้าย ────────────────
# ⚠️ `rm -rf` ลบโดยไม่ถามและกู้คืนไม่ได้ พิมพ์ path ให้ตรงกับโฟลเดอร์ทดสอบ ~/fwtest เท่านั้น
cd ~ && rm -rf ~/fwtest
sudo ss -tlnp | grep -E ':(80|8080) '
sudo firewall-cmd --list-all


# ── ขั้นที่ 1 ยืนยัน Mode ───────────────────────────────────────
getenforce
grep '^SELINUX=' /etc/selinux/config


# ── ขั้นที่ 2 ติดตั้งเครื่องมืออ่าน AVC ─────────────────────────
sudo dnf install -y setroubleshoot-server
rpm -q policycoreutils-python-utils setroubleshoot-server
sudo systemctl reboot


# ── ขั้นที่ 3 อ่าน Context ──────────────────────────────────────
ls -Z ~/.ssh/authorized_keys
ps -eZ | grep -w sshd
sudo semanage port -l | grep -w ssh_port_t


# ── ขั้นที่ 4 สร้าง AVC จริง ────────────────────────────────────
sudo systemd-run --unit=sshd-2223 /usr/sbin/sshd -D -p 2223 -o PidFile=none
systemctl is-active sshd-2223
sudo journalctl -u sshd-2223 --no-pager | tail -5

sudo ausearch -m avc -ts recent | grep denied
sudo journalctl -t setroubleshoot --since "5 min ago" | grep -o 'sealert -l [0-9a-f-]*'


# ── ขั้นที่ 5 แก้ด้วย Port Label แล้วเก็บกวาด ───────────────────
sudo semanage port -l | grep -w 2223
sudo semanage port -a -t ssh_port_t -p tcp 2223
sudo systemctl reset-failed sshd-2223
sudo systemd-run --unit=sshd-2223 /usr/sbin/sshd -D -p 2223 -o PidFile=none
systemctl is-active sshd-2223
sudo ss -tlnp | grep 2223

sudo systemctl stop sshd-2223
sudo semanage port -d -t ssh_port_t -p tcp 2223
sudo semanage port -l -C


# ── ขั้นที่ 6 restorecon และ boolean ────────────────────────────
# ⚠️ `rm -f` ลบไฟล์ทันทีโดยไม่ถาม พิมพ์ชื่อให้ตรงกับ /etc/selinux-demo.conf ห้ามใช้ wildcard ใน /etc
echo "lab selinux" > ~/selinux-demo.conf
sudo mv ~/selinux-demo.conf /etc/
ls -Z /etc/selinux-demo.conf
sudo restorecon -v /etc/selinux-demo.conf
sudo rm -f /etc/selinux-demo.conf

sudo setsebool httpd_can_network_connect on
getsebool httpd_can_network_connect
sudo setsebool httpd_can_network_connect off
sudo semanage boolean -l -C
getenforce

# [Host PC] VBoxManage controlvm server acpipowerbutton


# ── ufw แทน firewalld ───────────────────────────────────────────
# [Ubuntu]
sudo ufw status verbose
# [Ubuntu]
sudo ufw app list

# ⚠️ อย่ารัน `sudo ufw enable` ผ่าน SSH ก่อนอนุญาตพอร์ต 2222 เมื่อ enable แล้ว ufw ปฏิเสธ traffic ขาเข้าทั้งหมดทันที Session ที่ใช้อยู่จะหลุด ต้องแก้จาก Console
# [Ubuntu]
sudo ufw default deny incoming
# [Ubuntu]
sudo ufw default allow outgoing
# [Ubuntu]
sudo ufw allow 2222/tcp
# [Ubuntu]
sudo ufw allow http
# [Ubuntu]
sudo ufw allow https
# [Ubuntu]
sudo ufw enable
# [Ubuntu]
sudo ufw status verbose

# [Ubuntu]
sudo ufw status numbered
# [Ubuntu]
sudo ufw delete allow 8080/tcp

# [Ubuntu]
nc -zv -w 3 192.168.56.10 3306


# ── AppArmor แทน SELinux ────────────────────────────────────────
# [Ubuntu]
sudo aa-status

# [Ubuntu]
sudo journalctl -k --since today | grep 'apparmor="DENIED"'
