#!/usr/bin/env bash
# SSH และ fail2ban: ปิดประตูหน้าบ้าน
# SysAdmin Pocket Series M10 SSL & Security Hardening
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 2.1 อ่านค่าที่ sshd ใช้จริงก่อนแก้ ──────────────────────
sudo ls /etc/ssh/sshd_config.d/
sudo grep -n Include /etc/ssh/sshd_config
sudo sshd -T | grep -E '^(port|permitrootlogin|passwordauthentication|maxauthtries|x11forwarding|authenticationmethods) '
# บนเครื่อง attacker
ssh -p 2222 -o BatchMode=yes -o PubkeyAuthentication=no admin@sec1.lab.test

# ── กลุ่ม sshusers และผู้ใช้ทดสอบ ───────────────────────────
sudo groupadd sshusers
sudo usermod -aG sshusers admin
id admin
sudo useradd -m dev
sudo install -d -m 700 -o dev -g dev /home/dev/.ssh
sudo cp ~/.ssh/authorized_keys /home/dev/.ssh/
sudo chown dev:dev /home/dev/.ssh/authorized_keys
sudo restorecon -R /home/dev/.ssh

# ── ไฟล์ drop-in ของเล่ม ────────────────────────────────────
sudo sshd -t && echo OK
sudo sshd -T | grep -E '^(passwordauthentication|maxauthtries|allowgroups|x11forwarding|gssapiauthentication) '
# ⚠️ ก่อน reload sshd ให้เปิด session SSH ค้างไว้หนึ่งหน้าต่าง แล้วทดสอบการเข้าใหม่จากอีกหน้าต่างหนึ่ง session ที่เปิดอยู่ไม่ถูกตัดเมื่อ reload ถ้าเข้าใหม่ไม่ได้ ยังใช้หน้าต่างเดิมแก้กลับได้ ถ้าปิดทุกหน้าต่างไปแล้ว ทางเดียวคือ Console ของ VM หรือของผู้ให้บริการ Cloud
sudo systemctl reload sshd
# บนเครื่อง attacker
ssh -p 2222 admin@sec1.lab.test hostname
# บนเครื่อง attacker
ssh -p 2222 -o BatchMode=yes -o PubkeyAuthentication=no admin@sec1.lab.test
# บนเครื่อง attacker
ssh -p 2222 dev@sec1.lab.test
# บนเครื่อง attacker
ssh -p 2222 root@sec1.lab.test
sudo journalctl -u sshd --since "-5min" -o cat | grep -E 'not allowed|Connection closed'

# ── 2.2 2FA: กุญแจ + OTP ────────────────────────────────────
sudo dnf install -y google-authenticator qrencode
rpm -q google-authenticator

# ── เวลาต้องตรง ─────────────────────────────────────────────
timedatectl | grep synchronized
chronyc tracking | grep -E 'Reference|System time'
sudo mkdir -p /etc/systemd/system/chronyd.service.d
printf '[Unit]\nAfter=named.service\n' | sudo tee /etc/systemd/system/chronyd.service.d/after-named.conf > /dev/null
sudo systemctl daemon-reload
sudo systemctl restart chronyd

# ── สร้าง secret ให้ผู้ใช้ ──────────────────────────────────
sudo usermod -aG sshusers dev
sudo -iu dev
# บนเครื่อง dev
google-authenticator -t -d -f -r 3 -R 30 -w 3 -s ~/.ssh/.google_authenticator -l dev@sec1 -i sec1.lab.test

# ── ทำไมต้องเก็บ secret ใน ~/.ssh ───────────────────────────
sudo ausearch -m avc -ts today | grep google | head -1
sudo ls -laZ /home/dev/.ssh/
sudo mv /home/dev/.google_authenticator /home/dev/.ssh/
sudo restorecon -v /home/dev/.ssh/.google_authenticator

# ── ตั้ง PAM ────────────────────────────────────────────────
# ⚠️ ไฟล์ใน /etc/pam.d ผิดหนึ่งบรรทัดอาจทำให้ไม่มีใครเข้าเครื่องได้ สำรองไฟล์ก่อนแก้ และเปิด session ที่ใช้ sudo ได้ค้างไว้จนทดสอบเสร็จ
sudo cp -a /etc/pam.d/sshd /root/sshd.pam.bak
sudo vi /etc/pam.d/sshd

# ── บังคับให้ใช้ทั้งกุญแจและ OTP ────────────────────────────
sudo sshd -t && sudo systemctl reload sshd
sudo sshd -T | grep -E '^(kbdinteractiveauthentication|authenticationmethods|usepam) '
# บนเครื่อง attacker
ssh -p 2222 dev@sec1.lab.test
# บนเครื่อง attacker
ssh -p 2222 dev@sec1.lab.test
sudo journalctl --since "-2min" -o cat | grep -E 'reuse|Too many concurrent'

# ── ข้อยกเว้นด้วย Match ─────────────────────────────────────
sudo sshd -T -C user=dev,host=x,addr=192.168.56.81 | grep ^authenticationmethods
sudo sshd -T -C user=dev,host=x,addr=192.168.56.1 | grep ^authenticationmethods

# ── เมื่อใดจึงเอา nullok ออก ────────────────────────────────
for u in $(getent group sshusers | cut -d: -f4 | tr , ' '); do sudo test -f /home/$u/.ssh/.google_authenticator || echo "ยังไม่มี 2FA: $u"; done

# ── 2.3 fail2ban: ส่วนที่ M02 ยังไม่ได้ทำ ───────────────────
sudo dnf install -y fail2ban
rpm -q fail2ban

# ── recidive ต้องมีไฟล์ log ก่อน ────────────────────────────
sudo fail2ban-client -t
sudo touch /var/log/fail2ban.log
sudo restorecon -v /var/log/fail2ban.log
sudo fail2ban-client -t
sudo systemctl enable --now fail2ban
sudo fail2ban-client status

# ── mode = aggressive ───────────────────────────────────────
# บนเครื่อง attacker
for i in 1 2 3 4 5; do ssh -p 2222 -o BatchMode=yes -o PubkeyAuthentication=no -o ConnectTimeout=5 admin@sec1.lab.test; sleep 2; done
sudo fail2ban-regex systemd-journal 'sshd[mode=normal]' | grep ^Lines
sudo fail2ban-regex systemd-journal 'sshd[mode=aggressive]' | grep ^Lines
# บนเครื่อง attacker
for i in 1 2 3 4; do ssh -p 2222 -o BatchMode=yes -o PubkeyAuthentication=no -o ConnectTimeout=5 admin@sec1.lab.test; sleep 2; done
sudo fail2ban-client status sshd
sudo firewall-cmd --list-rich-rules

# ── nginx-botsearch ต้องอ่าน access log ─────────────────────
sudo fail2ban-regex /var/log/nginx/error.log nginx-botsearch | grep ^Lines
sudo fail2ban-regex /var/log/nginx/access.log nginx-botsearch | grep ^Lines
# บนเครื่อง attacker
for p in wp-login.php phpmyadmin/ pma/; do curl -s -o /dev/null -m 5 -w "%{http_code} /$p\n" https://site.lab.test/$p; sleep 1; done
# บนเครื่อง attacker
sleep 2; curl -s -o /dev/null -m 5 -w "%{http_code} /\n" https://site.lab.test/
sudo firewall-cmd --list-rich-rules

# ── recidive: แบนทุก port เมื่อกลับมาซ้ำ ────────────────────
for k in bantime findtime maxretry; do echo "$k=$(sudo fail2ban-client get recidive $k)"; done
sudo fail2ban-client set sshd unbanip 192.168.56.81
# บนเครื่อง attacker
for i in 1 2 3 4; do ssh -p 2222 -o BatchMode=yes -o PubkeyAuthentication=no -o ConnectTimeout=5 admin@sec1.lab.test; sleep 2; done
sudo grep NOTICE /var/log/fail2ban.log
sudo fail2ban-client get recidive banip --with-time
sudo firewall-cmd --list-rich-rules
# บนเครื่อง attacker
curl -s -m 5 -o /dev/null -w "%{http_code}\n" https://site.lab.test/
# บนเครื่อง attacker
ping -c1 -W2 sec1.lab.test | tail -1
sudo fail2ban-client unban 192.168.56.81
sudo fail2ban-client banned
# บนเครื่อง attacker
curl -s -m 5 -o /dev/null -w "%{http_code}\n" https://site.lab.test/

# ── วัดคะแนนหลังจบบท ────────────────────────────────────────
sudo ./security-audit.sh -v | sed -n '2,9p;/FAIL\] 16/,+1p;$p'
