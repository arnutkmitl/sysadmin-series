#!/usr/bin/env bash
# โปรเจกต์จบเล่ม: ล็อก server ใหม่ทั้งเครื่องในครั้งเดียว
# SysAdmin Pocket Series M10 SSL & Security Hardening
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 5.1 เตรียม web2 ─────────────────────────────────────────
sudo hostnamectl set-hostname web2
sudo rndc freeze lab.test
sudo sed -i -e 's/192.168.56.80/192.168.56.83/' -e 's/^\(\s*\)5\(\s*; serial\)/\16\2/' -e '$a web2     IN A    192.168.56.83' /var/named/dynamic/lab.test.zone
sudo named-checkzone lab.test /var/named/dynamic/lab.test.zone | tail -1
sudo rndc thaw lab.test
sudo nmcli con mod enp0s8 ipv4.addresses 192.168.56.83/24 && sudo systemctl reboot
hostname; ip -br -4 a | grep enp0s8; dig +short web2.lab.test
curl -s https://site.lab.test/
sudo ./security-audit.sh | tail -1

# ── ขั้นที่ 1 ถึง 3: SSH และ fail2ban ───────────────────────
until dig +short +time=3 rockylinux.org | grep -qE '^[0-9]+\.'; do sleep 10; done
sudo dnf install -y google-authenticator qrencode fail2ban
ls /usr/lib64/security/pam_google_authenticator.so
# ⚠️ ถ้า ls ไม่พบไฟล์ หยุดทันที ห้ามแก้ /etc/pam.d/sshd จนกว่าแพ็กเกจจะติดตั้งสำเร็จ และเปิด session SSH ค้างไว้หนึ่งหน้าต่างตลอดขั้นที่ 2
sudo groupadd sshusers && sudo usermod -aG sshusers admin
sudo cp -a /etc/pam.d/sshd /root/sshd.pam.bak
sudo sed -i 's/^auth\s*substack\s*password-auth/#&\nauth       required     pam_google_authenticator.so secret=${HOME}\/.ssh\/.google_authenticator nullok\nauth       required     pam_permit.so/' /etc/pam.d/sshd
diff <(grep -v '^# ' ~/code/ch02/pam-sshd-auth.txt) <(head -5 /etc/pam.d/sshd) && echo 'ตรงกับไฟล์ประกอบ'
sudo cp ~/code/ch02/20-m10-hardening.conf /etc/ssh/sshd_config.d/
sudo sshd -t && sudo systemctl reload sshd
sudo touch /var/log/fail2ban.log && sudo restorecon /var/log/fail2ban.log
sudo cp ~/code/ch02/jail.local /etc/fail2ban/jail.local
sudo fail2ban-client -t && sudo systemctl enable --now fail2ban
sudo fail2ban-client status | tail -1

# ── ขั้นที่ 4: ย้ายเว็บโดยไม่เกิด AVC ───────────────────────
sudo semanage fcontext -a -t httpd_sys_content_t '/srv/site(/.*)?'
sudo semanage fcontext -a -t httpd_sys_rw_content_t '/srv/site/uploads(/.*)?'
sudo mkdir -p /srv/site/uploads && sudo cp -r /usr/share/nginx/site/. /srv/site/ && sudo chown apache:apache /srv/site/uploads
sudo restorecon -Rv /srv/site
sudo sed -i 's|root /usr/share/nginx/site;|root /srv/site;|' /etc/nginx/conf.d/site.conf
sudo nginx -t && sudo systemctl reload nginx
curl -s https://site.lab.test/
sudo ausearch -m avc -ts today

# ── ขั้นที่ 5 ถึง 7: ผู้ใช้ ระบบ และ log ────────────────────
# บนเครื่อง attacker
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.56.83" port port="514" protocol="tcp" accept'
# บนเครื่อง attacker
sudo firewall-cmd --reload
sudo cp ~/code/ch04/50-m10.conf /etc/security/pwquality.conf.d/
sudo authselect enable-feature with-faillock
printf 'deny = 5\nunlock_time = 900\naudit\n' | sudo tee -a /etc/security/faillock.conf > /dev/null
sudo sed -i 's/^UMASK\s.*/UMASK\t\t027/' /etc/login.defs
sudo systemctl disable --now bluetooth
sudo firewall-cmd --permanent --remove-service=cockpit && sudo firewall-cmd --reload
sudo cp ~/code/ch04/90-m10-hardening.conf /etc/sysctl.d/ && sudo sysctl --system > /dev/null
sudo cp ~/code/ch04/90-remote.conf /etc/rsyslog.d/ && sudo rsyslogd -N1 2>&1 | tail -1 && sudo systemctl restart rsyslog
sudo dnf install -y dnf-automatic aide
sudo sed -i -e 's/^upgrade_type = .*/upgrade_type = security/' -e 's/^apply_updates = .*/apply_updates = yes/' /etc/dnf/automatic.conf
sudo systemctl enable --now dnf-automatic.timer

# ── ขั้นที่ 8: module จากไฟล์ .te ที่เก็บไว้ ────────────────
cd ~/code/ch04 && checkmodule -M -m -o aide_efi.mod aide_efi.te && semodule_package -o aide_efi.pp -m aide_efi.mod
sudo semodule -i ~/code/ch04/aide_efi.pp && sudo semodule -l | grep aide_efi
sudo install -m 750 ~/security-audit.sh /usr/local/sbin/security-audit.sh
sudo cp ~/code/ch04/aide-check.* ~/code/ch05/security-audit.* /etc/systemd/system/
sudo systemctl daemon-reload && sudo systemctl enable --now aide-check.timer security-audit.timer
systemctl list-timers --no-pager | grep -E 'aide|audit|dnf-auto'

# ── ขั้นที่ 9: AIDE เป็นขั้นสุดท้าย ─────────────────────────
sudo aide --init 2>&1 | grep -E 'Number of entries|run time'
sudo mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
sudo systemctl start aide-check.service; systemctl is-failed aide-check.service
sudo ausearch -m avc -ts today

# ── 5.3 ผลและการตรวจรายสัปดาห์ ──────────────────────────────
sudo systemctl start security-audit.service
sudo journalctl -u security-audit.service -o cat --since '-2min' | grep -E 'FAIL|^== '
# บนเครื่อง attacker
sudo grep -E "capstone|security-audit\[[0-9]+\]: == " /var/log/remote/web2.log | head -3
sudo security-audit.sh | tail -1
sudo /usr/local/sbin/security-audit.sh | tail -1

# ── 5.4 ซ้อมเหตุที่ 1: ไฟล์ debug ที่ลืมลบ ──────────────────
echo 'PasswordAuthentication yes' | sudo tee /etc/ssh/sshd_config.d/01-debug.conf
echo 'AuthenticationMethods any' | sudo tee -a /etc/ssh/sshd_config.d/01-debug.conf
sudo sshd -t && sudo systemctl reload sshd
# บนเครื่อง attacker
ssh -p 2222 -o BatchMode=yes -o PubkeyAuthentication=no admin@192.168.56.83
sudo /usr/local/sbin/security-audit.sh -v | grep -E -A1 'FAIL'; sudo /usr/local/sbin/security-audit.sh | tail -1
sudo systemctl start aide-check.service
sudo journalctl -u aide-check.service -o cat --since '-3min' | grep -E '^f\+|Added entries:'
sudo rm /etc/ssh/sshd_config.d/01-debug.conf && sudo sshd -t && sudo systemctl reload sshd
sudo sshd -T | grep -E '^(passwordauthentication|authenticationmethods)'
sudo /usr/local/sbin/security-audit.sh | tail -1
sudo systemctl start aide-check.service && systemctl is-failed aide-check.service

# ── 5.5 ซ้อมเหตุที่ 2: deploy ด้วย mv ───────────────────────
mkdir -p ~/release && echo '<?php echo "site.lab.test v2 บน " . gethostname() . "\n";' > ~/release/index.php
sudo mv ~/release/index.php /srv/site/index.php
curl -s -o /dev/null -w '%{http_code}\n' https://site.lab.test/
sudo /usr/local/sbin/security-audit.sh -v | grep -E -A1 'FAIL'; sudo /usr/local/sbin/security-audit.sh | tail -1
sudo ausearch -m avc -ts today
sudo tail -1 /var/log/nginx/error.log
umask; ls -lZ /srv/site/index.php
sudo restorecon -v /srv/site/index.php
curl -s -o /dev/null -w '%{http_code}\n' https://site.lab.test/
sudo chown root:root /srv/site/index.php && sudo chmod 644 /srv/site/index.php
curl -s https://site.lab.test/
echo '<?php echo "site.lab.test v3 บน " . gethostname() . "\n";' > ~/release/index.php
ls -lZ ~/release/index.php
sudo install -m 644 -o root -g root ~/release/index.php /srv/site/index.php
ls -lZ /srv/site/index.php
curl -s https://site.lab.test/
sudo /usr/local/sbin/security-audit.sh | tail -1
