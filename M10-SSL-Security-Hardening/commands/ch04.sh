#!/usr/bin/env bash
# System Hardening และ Audit: ปิดจุดที่เหลือให้ครบ 30 ข้อ
# SysAdmin Pocket Series M10 SSL & Security Hardening
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ──  ────────────────────────────────────────────────────────
sudo ./security-audit.sh | grep FAIL

# ── บัญชีที่ไม่ได้ใช้แล้ว ───────────────────────────────────
sudo useradd -m -G sshusers intern
sudo install -d -m 700 -o intern -g intern /home/intern/.ssh
sudo cp ~/.ssh/authorized_keys /home/intern/.ssh/
sudo chown intern:intern /home/intern/.ssh/authorized_keys
sudo restorecon -R /home/intern/.ssh
sudo useradd -m ops
awk -F: '$7 !~ /(nologin|false|sync|shutdown|halt)$/ {print $1, $3, $7}' /etc/passwd
sudo lastlog -u 1000-60000
sudo passwd -S intern
# บนเครื่อง attacker
ssh -p 2222 intern@sec1.lab.test hostname
sudo usermod -e 1 intern
sudo chage -l intern | grep 'Account expires'
# บนเครื่อง attacker
ssh -p 2222 intern@sec1.lab.test hostname
sudo journalctl -u sshd --since '-1min' -o cat | grep expired

# ── รหัสผ่านอย่างน้อย 12 ตัว ────────────────────────────────
for pw in 'Rocky2026' 'sec1-admin' 'Kh0ngJai-Lab!' 'correct horse battery'; do printf '%-24s ' "$pw"; echo "$pw" | pwscore 2>&1; done

# ── ล็อกบัญชีเมื่อใส่รหัสผิดซ้ำ ─────────────────────────────
sudo authselect enable-feature with-faillock
sudo authselect current
grep -n faillock /etc/pam.d/system-auth
printf 'deny = 5\nunlock_time = 900\naudit\n' | sudo tee -a /etc/security/faillock.conf
sudo dnf install -y pamtester
echo 'dev:Lab-Dev-2026!x' | sudo chpasswd
echo 'Lab-Dev-2026!x' | sudo pamtester system-auth dev authenticate
for i in 1 2 3 4 5; do echo wrong-$i | sudo pamtester system-auth dev authenticate 2>&1 | tail -1; done
echo 'Lab-Dev-2026!x' | sudo pamtester system-auth dev authenticate
sudo faillock --user dev
sudo journalctl --since '-2min' -o cat | grep 'temporarily locked'
sudo faillock --user dev --reset
echo 'Lab-Dev-2026!x' | sudo pamtester system-auth dev authenticate

# ── sudo เฉพาะคำสั่งที่จำเป็น ───────────────────────────────
sudo groupadd webops
sudo usermod -aG webops ops
echo '%webops ALL=(root) NOPASSWD: /usr/bin/systemctl reload nginx, /usr/bin/systemctl restart php-fpm' > webops
sudo visudo -cf webops
sudo install -m 440 -o root -g root webops /etc/sudoers.d/webops && rm webops
sudo visudo -c
sudo -l -U ops | tail -2
sudo -iu ops sudo -n systemctl reload nginx; echo rc=$?
sudo -iu ops sudo -n systemctl stop nginx; echo rc=$?
sudo -iu ops sudo -n systemctl reload nginx sshd; echo rc=$?

# ── UMASK 027 ───────────────────────────────────────────────
grep ^UMASK /etc/login.defs; sudo su - dev -c umask
sudo sed -i 's/^UMASK\s.*/UMASK\t\t027/' /etc/login.defs
grep ^UMASK /etc/login.defs; sudo su - dev -c umask
sudo su - dev -c 'touch /tmp/umask-test; ls -l /tmp/umask-test; rm /tmp/umask-test'
# บนเครื่อง attacker
ssh -p 2222 admin@sec1.lab.test umask

# ── port ที่เปิดและบริการที่ไม่ได้ใช้ ───────────────────────
sudo ss -tlnp | awk 'NR>1 && $4 !~ /^(127\.|\[::1\])/ {print $4, $6}'
systemctl status bluetooth --no-pager | head -3
sudo systemctl disable --now bluetooth

# ── firewall ที่เปิดเกิน ────────────────────────────────────
sudo firewall-cmd --list-services
rpm -q cockpit cockpit-ws
sudo firewall-cmd --permanent --remove-service=cockpit
sudo firewall-cmd --reload
sudo firewall-cmd --list-services

# ── ค่าของ kernel ด้วย sysctl ───────────────────────────────
sysctl net.ipv4.conf.all.accept_redirects net.ipv4.conf.all.send_redirects net.ipv4.conf.all.log_martians net.ipv4.tcp_syncookies net.ipv4.ip_forward
sysctl -a 2>/dev/null | grep -E 'ipv4.conf.(all|default|enp0s3|enp0s8).accept_redirects'
sudo sysctl --system > /dev/null
sysctl -a 2>/dev/null | grep -E 'conf.(all|default|enp0s3|enp0s8|lo).accept_redirects'

# ── ฝั่งรับบน attacker ──────────────────────────────────────
# บนเครื่อง attacker
sudo rsyslogd -N1 2>&1 | tail -1
# บนเครื่อง attacker
sudo systemctl restart rsyslog
# บนเครื่อง attacker
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.56.80" port port="514" protocol="tcp" accept'
# บนเครื่อง attacker
sudo firewall-cmd --reload
# บนเครื่อง attacker
sudo ss -ltnp | grep 514

# ── ฝั่งส่งบน sec1 ──────────────────────────────────────────
sudo rsyslogd -N1 2>&1 | tail -1
sudo systemctl restart rsyslog
logger -t m10test 'ทดสอบส่ง log จาก sec1'
# บนเครื่อง attacker
sudo grep m10test /var/log/remote/sec1.log
# บนเครื่อง attacker
sudo systemctl stop rsyslog
logger -t m10test "ส่งระหว่างที่ log server ล่ม"
# บนเครื่อง attacker
sudo systemctl start rsyslog
# บนเครื่อง attacker
sudo grep m10test /var/log/remote/sec1.log
sudo journalctl -u rsyslog --since "-5min" -o cat | grep -E 'suspended|resumed' | cut -c1-80

# ── 4.4 อัปเดตความปลอดภัยอัตโนมัติ ──────────────────────────
sudo dnf install -y dnf-automatic
sudo sed -i -e 's/^upgrade_type = .*/upgrade_type = security/' -e 's/^apply_updates = .*/apply_updates = yes/' /etc/dnf/automatic.conf
grep -E '^(upgrade_type|download_updates|apply_updates|reboot) ' /etc/dnf/automatic.conf
sudo systemctl enable --now dnf-automatic.timer
systemctl cat dnf-automatic.timer | grep -E 'OnCalendar|Randomized'
sudo systemctl start dnf-automatic.service
sudo journalctl -u dnf-automatic.service -o cat --since '-3min' | grep updates
sudo dnf needs-restarting -r; echo rc=$?

# ── 4.5 AIDE: รู้เมื่อไฟล์ระบบถูกแก้ ────────────────────────
sudo dnf install -y aide
sudo grep -E '^(database_in|database_out)' /etc/aide.conf
sudo aide --init 2>&1 | grep -E 'Number of entries|run time'
sudo mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz

# ── ตรวจทุกวันด้วย systemd timer ────────────────────────────
sudo cp ~/ch04/aide-check.service ~/ch04/aide-check.timer /etc/systemd/system/
sudo systemctl daemon-reload && sudo systemctl enable --now aide-check.timer

# ── จำลองการถูกเจาะ ─────────────────────────────────────────
sudo useradd backdoor
sudo cp /usr/bin/true /usr/local/bin/ps
sudo systemctl start aide-check.service
sudo journalctl -u aide-check.service -o cat --since '-3min' | grep -E 'entries:|^f[ +>]|^d >|status='

# ── ลบร่องรอยแล้วยังไม่จบ ───────────────────────────────────
sudo userdel -r backdoor && sudo rm /usr/local/bin/ps
sudo systemctl start aide-check.service
sudo journalctl -u aide-check.service -o cat --since '-2min' | grep -E 'entries:|^f'
sudo aide --update > /dev/null; echo rc=$?
sudo mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
sudo systemctl start aide-check.service && systemctl is-failed aide-check.service

# ── AIDE ที่รันจาก systemd ทำให้เกิด AVC ────────────────────
sudo ausearch -m avc -ts recent -c aide | grep AVC | tail -1
cd ~/selinux && sudo ausearch -m avc -ts today -c aide | audit2allow -M aide_efi
cat ~/selinux/aide_efi.te
sudo semodule -i ~/selinux/aide_efi.pp
sudo systemctl start aide-check.service; systemctl is-failed aide-check.service
sudo ausearch -m avc -ts recent

# ── 4.6 security-audit.sh ทั้ง 30 ข้อ ───────────────────────
grep -nE '^(check\(\)|because\(\)|no_redirects\(\))|^check "Kernel: ไม่รับ' security-audit.sh
24:check() {   # check "หมวด: คำอธิบาย" ฟังก์ชันหรือคำสั่ง...
36:because() { why=$*; return 1; }
139:no_redirects() {   # ทุก interface ต้องไม่รับ ICMP redirect: เมื่อเครื่องไม่ได้ forward kernel ใช้ค่า all OR ค่าของ interface
209:check "Kernel: ไม่รับ ICMP redirect"                 no_redirects
sudo SITE=www.example.com ALLOWED_TCP="22 80 443" CERT_DAYS=21 ./security-audit.sh

# ── คะแนนหลังจบบท ───────────────────────────────────────────
sudo ./security-audit.sh -v | sed -n '/\] 16/,+1p;/\] 1[7-9]/p;/\] 2[0-9]/p;/\] 30/p;$p'

# ── กล่อง Ubuntu ────────────────────────────────────────────
sudo ./security-audit.sh -v | grep -A1 '\] 19'
sudo ss -ltnp | grep ':25 '
sudo postconf -e inet_interfaces=loopback-only && sudo systemctl restart postfix
sudo ss -ltnp | grep ':25 '
