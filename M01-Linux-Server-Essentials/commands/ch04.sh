#!/usr/bin/env bash
# บทที่ 4 เชื่อมต่อ SSH Remote จากที่ไหนก็ได้
# SysAdmin Pocket Series M01 Linux Server Essentials (Rocky Linux 10.2)
#
# ไฟล์นี้รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# คำสั่งที่ไม่มีป้ายรันบน server ส่วนบรรทัดที่มีป้าย [Host PC] รันใน PowerShell บน Windows
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1
# [Host PC] VBoxManage list runningvms
# [Host PC] VBoxManage snapshot server take ch04-start --description "ก่อนเริ่มบทที่ 4"
# [Host PC] VBoxManage startvm server --type headless


# ── ตรวจเส้นทางก่อน SSH ─────────────────────────────────────────
ip -4 addr show enp0s8
systemctl is-active sshd
sudo ss -tlnp | grep sshd

# [Host PC] ping -n 2 192.168.56.10
# [Host PC] Test-NetConnection 192.168.56.10 -Port 22

# [Host PC] Test-NetConnection 10.0.1.50 -Port 2200 -InformationLevel Quiet

nc -zv -w 3 192.168.56.10 22
nc -zv -w 3 10.0.1.50 2200


# ── จาก Windows Terminal หรือ PowerShell ────────────────────────
# [Host PC] ssh -V

# [Host PC] ssh admin@192.168.56.10



# ── Host key และ fingerprint ตรวจก่อนตอบ yes ────────────────────
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub

for f in /etc/ssh/ssh_host_*_key.pub; do ssh-keygen -lf "$f"; done


# ── known_hosts จำเครื่องอย่างไร ────────────────────────────────
# [Host PC] ssh-keygen -F 192.168.56.10

# [Host PC] ssh admin@192.168.56.10

# [Host PC] ssh-keygen -R 192.168.56.10

# [Host PC] ssh-keygen -R "[192.168.56.10]:2222"


# ── จาก macOS หรือ Linux ────────────────────────────────────────
ssh admin@192.168.56.10


# ── ทดสอบว่าเชื่อมต่อสำเร็จ ─────────────────────────────────────
hostname
whoami
echo $SSH_CONNECTION

w

# [Host PC] ssh admin@192.168.56.10 "uptime; df -h /"


# ── สร้าง SSH Key Pair บนเครื่อง Client ─────────────────────────
# [Host PC] ssh-keygen -t ed25519 -C "admin@hostpc"

# [Host PC] ssh-keygen -t ed25519 -C "somchai@office-2026" -f $env:USERPROFILE\.ssh\id_ed25519_office

# [Host PC] Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub


# ── Passphrase และ ssh-agent ────────────────────────────────────
# [Host PC] ssh-keygen -p -f $env:USERPROFILE\.ssh\id_ed25519

# [Host PC] Get-Service ssh-agent | Set-Service -StartupType Automatic
# [Host PC] Start-Service ssh-agent
# [Host PC] Get-Service ssh-agent

# [Host PC] ssh-add
# [Host PC] ssh-add -l

eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
ssh-add --apple-use-keychain ~/.ssh/id_ed25519


# ── ส่ง Public Key ไปยัง Server ─────────────────────────────────
# [Host PC] Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub | ssh admin@192.168.56.10 "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && restorecon -R ~/.ssh"

ssh-copy-id admin@192.168.56.10

ssh-copy-id -i ~/.ssh/id_ed25519_office.pub -p 2200 webmaster@10.0.1.50

mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF3kQx8vN2pLr7tYc1mW5zA9sD4hJ6bE0gK8uT3oVnRq admin@hostpc" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
restorecon -Rv ~/.ssh

# ⚠️ ใช้ `>>` เสมอเมื่อเพิ่ม Key ถ้าพิมพ์ `>` ตัวเดียว ไฟล์ authorized_keys จะถูกเขียนทับ Key เดิมของทุกคนหายหมด บน Server ที่ปิดรหัสผ่านแล้วจะไม่มีใครเข้าเครื่องได้อีก
ls -ld ~ ~/.ssh ~/.ssh/authorized_keys


# ── ทดสอบ Login ด้วย Key ────────────────────────────────────────
# [Host PC] ssh admin@192.168.56.10


# [Host PC] ssh -v admin@192.168.56.10 exit 2>&1 | Select-String "Offering|Server accepts|Authenticated"


# ── ไฟล์ตั้งค่าของ sshd อยู่ที่ไหน ──────────────────────────────
ls /etc/ssh/sshd_config.d/
sudo ls /etc/ssh/sshd_config.d/
sudo grep -n Include /etc/ssh/sshd_config

sudo grep -rniE '^\s*(port|permitrootlogin|passwordauthentication)\b' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/

sudo cat /etc/ssh/sshd_config.d/01-permitrootlogin.conf
sudo mv /etc/ssh/sshd_config.d/01-permitrootlogin.conf /root/01-permitrootlogin.conf.bak


# ── สำรอง Configuration ก่อนแก้ไข ───────────────────────────────
sudo cp -a /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%Y%m%d)
sudo ls /etc/ssh/sshd_config*

sudo tar czf /root/etc-ssh-$(date +%Y%m%d).tar.gz -C /etc ssh
sudo tar tzf /root/etc-ssh-20261113.tar.gz | head -4


# ── เปิดทางให้พอร์ต 2222 ที่ SELinux และ Firewall ───────────────
sudo dnf install -y policycoreutils-python-utils
sudo semanage port -l | grep -w ssh_port_t
sudo semanage port -a -t ssh_port_t -p tcp 2222
sudo semanage port -l | grep -w ssh_port_t

sudo semanage port -a -t ssh_port_t -p tcp 2200
sudo semanage port -a -t ssh_port_t -p tcp 8022

sudo firewall-cmd --permanent --add-port=2222/tcp
sudo firewall-cmd --reload
sudo firewall-cmd --list-ports
sudo firewall-cmd --list-services


# ── สร้างไฟล์ 10-hardening.conf ─────────────────────────────────
sudo nano /etc/ssh/sshd_config.d/10-hardening.conf


# ── ตรวจสอบ Configuration ทั้งไฟล์ ──────────────────────────────
sudo sshd -t
echo $?

sudo sshd -t

sudo sshd -T | grep -Ei '^(port|permitrootlogin|passwordauthentication|kbdinteractiveauthentication|allowusers|maxauthtries) '

sudo sshd -T -C user=webmaster,host=pc01,addr=10.0.1.20 | grep -Ei '^(passwordauthentication|permitrootlogin) '


# ── Restart SSH Service ─────────────────────────────────────────
sudo systemctl restart sshd
sudo ss -tlnp | grep sshd

sudo journalctl -u sshd -n 3 --no-pager


# ── ทดสอบ Session ใหม่ทันที ─────────────────────────────────────
# [Host PC] ssh -p 2222 admin@192.168.56.10



# ── ทดสอบว่า Hardening ทำงาน ────────────────────────────────────
# [Host PC] ssh -p 2222 -o PubkeyAuthentication=no admin@192.168.56.10

# [Host PC] ssh -p 2222 root@192.168.56.10

sudo journalctl -u sshd --since "5 min ago" | grep -i "not allowed"

# [Host PC] ssh -p 22 admin@192.168.56.10


# ── ปิดพอร์ต 22 ที่ Firewall ────────────────────────────────────
# ⚠️ คำสั่งนี้ปิดพอร์ต 22 ที่ firewall ถ้ายังไม่เคยเข้าพอร์ต 2222 จาก Session ใหม่สำเร็จ อย่ารัน เพราะจะเหลือทางเข้าเครื่องแค่ Console ของ VirtualBox
sudo firewall-cmd --permanent --remove-service=ssh
sudo firewall-cmd --reload
sudo firewall-cmd --list-all

# [Host PC] ssh -p 22 admin@192.168.56.10


# ── กู้คืนเมื่อล็อกตัวเองออก ────────────────────────────────────
# [Host PC] VBoxManage startvm server --type gui

sudo mv /etc/ssh/sshd_config.d/10-hardening.conf /root/10-hardening.conf.broken
sudo systemctl restart sshd
sudo firewall-cmd --add-service=ssh
sudo ss -tlnp | grep sshd

# ⚠️ การย้อน Snapshot ลบทุกอย่างที่ทำบน server หลังจุดนั้น และย้อนกลับไม่ได้ ต้องปิด VM ก่อนย้อน
# [Host PC] VBoxManage controlvm server poweroff
# [Host PC] VBoxManage snapshot server restore "ch04-start"

sudo systemd-run --on-active=5m --unit=ssh-rollback /bin/sh -c 'mv /etc/ssh/sshd_config.d/10-hardening.conf /root/ && systemctl restart sshd'
sudo systemctl restart sshd

sudo systemctl stop ssh-rollback.timer
systemctl list-timers ssh-rollback.timer


# ── สร้างกฎ Port Forwarding ─────────────────────────────────────
# [Host PC] VBoxManage controlvm server natpf1 "ssh,tcp,127.0.0.1,2222,,2222"
# [Host PC] VBoxManage showvminfo server --machinereadable | findstr Forwarding

# [Host PC] VBoxManage modifyvm server --natpf1 delete ssh
# [Host PC] VBoxManage modifyvm server --natpf1 "ssh,tcp,127.0.0.1,2222,,2222"

# [Host PC] ssh -p 2222 admin@127.0.0.1
echo $SSH_CONNECTION


# ── กรณี VM อยู่บนเครื่องอื่น ───────────────────────────────────
# [Host PC] VBoxManage controlvm server natpf1 "ssh-lan,tcp,,2223,,2222"
# [Host PC] New-NetFirewallRule -DisplayName "VBox SSH 2223" -Direction Inbound -Protocol TCP -LocalPort 2223 -Action Allow -Profile Private

# [Host PC] ssh -p 2223 admin@192.168.1.40


# ── ปัญหาของการพิมพ์คำสั่งยาว ───────────────────────────────────
# [Host PC] ssh -p 2222 -i $env:USERPROFILE\.ssh\id_ed25519 admin@192.168.56.10


# ── สร้างไฟล์ SSH Config ────────────────────────────────────────
# [Host PC] notepad $env:USERPROFILE\.ssh\config

nano ~/.ssh/config
chmod 600 ~/.ssh/config


# ── ใช้งาน SSH Config ───────────────────────────────────────────
# [Host PC] ssh server


# [Host PC] ssh -G server | Select-String -Pattern '^(hostname|port|user|identitiesonly) '

# [Host PC] foreach ($h in "server","webserver") { ssh $h "hostname; df -h / | tail -1" }


# ── คัดลอกไฟล์ด้วย scp ──────────────────────────────────────────
# [Host PC] Set-Content -Path .\notes.txt -Value "ทดสอบ scp จาก Host PC"
# [Host PC] scp .\notes.txt server:
# [Host PC] scp server:/etc/os-release .\server-os-release.txt

# [Host PC] scp -P 2222 .\notes.txt admin@192.168.56.10:/tmp/

# [Host PC] scp -r .\site\ webserver:/var/www/staging/


# ── ทำงานกับไฟล์แบบโต้ตอบด้วย sftp ──────────────────────────────
# [Host PC] sftp server

# [Host PC] sftp -P 2200 webmaster@10.0.1.50


# ── ขั้นที่ 1 ตรวจเส้นทางและ fingerprint ────────────────────────
# [Host PC] Test-NetConnection 192.168.56.10 -Port 22 -InformationLevel Quiet

ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub


# ── ขั้นที่ 2 สร้าง Key และเปิด ssh-agent ───────────────────────
# [Host PC] Test-Path $env:USERPROFILE\.ssh\id_ed25519
# [Host PC] ssh-keygen -t ed25519 -C "admin@hostpc"

# [Host PC] ssh-add


# ── ขั้นที่ 3 ส่ง Key ไป server และทดสอบ ────────────────────────
# [Host PC] Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub | ssh admin@192.168.56.10 "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && restorecon -R ~/.ssh"

# [Host PC] ssh -v admin@192.168.56.10 exit 2>&1 | Select-String "Authenticated"


# ── ขั้นที่ 4 เปิด Session สำรองและสำรองค่า ─────────────────────
sudo cp -a /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%Y%m%d)
ls /etc/ssh/sshd_config.d/


# ── ขั้นที่ 5 เปิดพอร์ต 2222 ที่ SELinux และ firewalld ──────────
sudo dnf install -y policycoreutils-python-utils
sudo semanage port -a -t ssh_port_t -p tcp 2222
sudo semanage port -l | grep -w ssh_port_t
sudo firewall-cmd --permanent --add-port=2222/tcp
sudo firewall-cmd --reload
sudo firewall-cmd --list-ports


# ── ขั้นที่ 6 สร้าง 10-hardening.conf แล้ว restart ──────────────
sudo nano /etc/ssh/sshd_config.d/10-hardening.conf

sudo sshd -t
sudo sshd -T | grep -Ei '^(port|permitrootlogin|passwordauthentication|allowusers|maxauthtries) '
sudo systemctl restart sshd
sudo ss -tlnp | grep sshd


# ── ขั้นที่ 7 ทดสอบจาก Session ใหม่ ─────────────────────────────
# [Host PC] ssh -p 2222 admin@192.168.56.10 hostname
# [Host PC] ssh -p 2222 -o PubkeyAuthentication=no admin@192.168.56.10
# [Host PC] ssh -p 2222 root@192.168.56.10
# [Host PC] ssh -p 22 admin@192.168.56.10


# ── ขั้นที่ 8 ตั้ง ~/.ssh/config และทดสอบ scp ───────────────────
# [Host PC] notepad $env:USERPROFILE\.ssh\config

# [Host PC] ssh server whoami
# [Host PC] scp server:/etc/os-release .\server-os-release.txt


# ── ขั้นที่ 9 ปิดพอร์ต 22 ที่ firewalld ─────────────────────────
# ⚠️ คำสั่งนี้ปิดพอร์ต 22 ที่ firewall ถ้ายังไม่เคยเข้าพอร์ต 2222 สำเร็จในขั้นที่ 7 อย่ารัน เพราะจะเหลือทางเข้าเครื่องแค่ Console ของ VirtualBox
# [Host PC] ssh server

sudo firewall-cmd --permanent --remove-service=ssh
sudo firewall-cmd --reload
sudo firewall-cmd --list-services
sudo firewall-cmd --list-ports
exit

# [Host PC] ssh -p 22 admin@192.168.56.10
# [Host PC] ssh server hostname


# ── ขั้นที่ 10 ปิดเครื่องให้พร้อมสำหรับบทที่ 5 ──────────────────
# [Host PC] VBoxManage controlvm server acpipowerbutton
# [Host PC] VBoxManage list runningvms


# ── ติดตั้งและตรวจ OpenSSH Server ───────────────────────────────
# [Ubuntu]
sudo apt install -y openssh-server
# [Ubuntu]
systemctl is-active ssh.socket ssh.service

# [Ubuntu]
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub


# ── ไฟล์ใน sshd_config.d และ 50-cloud-init.conf ─────────────────
# [Ubuntu]
ls /etc/ssh/sshd_config.d/
# [Ubuntu]
cat /etc/ssh/sshd_config.d/50-cloud-init.conf


# ── Ubuntu 26.04 ใช้ ssh.socket ─────────────────────────────────
# [Ubuntu]
sudo sshd -t
# [Ubuntu]
sudo systemctl daemon-reload
# [Ubuntu]
sudo systemctl restart ssh.socket
# [Ubuntu]
sudo ss -tlnp | grep 2222

# [Ubuntu]
systemctl is-active ssh.socket ssh.service


# ── Firewall ที่แตกต่าง ufw แทน firewall-cmd ────────────────────
# ⚠️ ต้องรัน `sudo ufw allow 2222/tcp` ก่อน `sudo ufw enable` เสมอ ถ้าเปิด ufw ก่อน Session SSH ใหม่ทุก Session จะถูกบล็อก และต้องแก้จาก Console
# [Ubuntu]
sudo ufw allow 2222/tcp
# [Ubuntu]
sudo ufw enable
# [Ubuntu]
sudo ufw status numbered


# ── กู้คืนผ่าน Console บน Ubuntu ────────────────────────────────
# [Ubuntu]
sudo mv /etc/ssh/sshd_config.d/10-hardening.conf /root/
# [Ubuntu]
sudo systemctl daemon-reload
# [Ubuntu]
sudo systemctl restart ssh.socket
# [Ubuntu]
sudo ufw allow 22/tcp
