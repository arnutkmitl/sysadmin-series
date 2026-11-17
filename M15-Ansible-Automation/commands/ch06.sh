#!/usr/bin/env bash
# บทที่ 6 โปรเจกต์จบเล่ม: Server Farm ด้วยคำสั่งเดียว
# SysAdmin Pocket Series M15 Ansible Automation
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── Lab 6.1 รัน site.yml สองรอบ ─────────────────────────────
# บนเครื่อง ctl
time ansible-playbook site.yml

# ── 6.3 ตรวจคุณภาพด้วย ansible-lint ─────────────────────────
# บนเครื่อง ctl
python3 -m venv --system-site-packages ~/.venvs/lint
~/.venvs/lint/bin/pip install -q ansible-lint==26.11.0
~/.venvs/lint/bin/ansible-lint --version
~/.venvs/lint/bin/ansible-lint
~/.venvs/lint/bin/ansible-lint

# ── Lab 6.2 ทำ drift บน web แล้วแก้ด้วย site.yml ────────────
# ⚠️ คำสั่งชุดนี้หยุดเว็บไซต์บน web และลดความปลอดภัยของ sshd ทำเฉพาะใน Lab เท่านั้น
# บนเครื่อง web
sudo sed -i "s/^MaxAuthTries 3/MaxAuthTries 10/" /etc/ssh/sshd_config.d/10-m15-hardening.conf
sudo systemctl stop nginx
echo "แก้ด้วยมือตอนตีสอง" | sudo tee -a /etc/motd
sudo firewall-cmd --remove-service=https
# บนเครื่อง ctl
ansible-playbook site.yml --limit web --check
time ansible-playbook site.yml --limit web
ansible-playbook site.yml --limit web

# ── Lab 6.3 แทน db ด้วยเครื่องใหม่ ──────────────────────────
# PowerShell บนเครื่อง Windows
VBoxManage controlvm db acpipowerbutton
VBoxManage clonevm server --snapshot base-10.2 --options link --name db-new --register
VBoxManage discardstate db-new
VBoxManage startvm db-new --type headless
# บนเครื่อง ctl
ansible db -m ping
ssh-copy-id -p 2222 admin@192.168.56.68
NODES=192.168.56.68 ./bootstrap-ansible-user.sh
cd ~/ansible-lab
time ansible-playbook site.yml --limit db
ansible-playbook site.yml --limit db
ansible db -b -m shell -a "mariadb -N -e \"show databases like 'shop'\"; systemctl is-active mariadb node_exporter fail2ban backup-db.timer"

# ── เครื่องที่ clone มามี host key เดียวกัน ─────────────────
# บนเครื่อง ctl
ansible db,web -b -m shell -a "ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub | cut -d' ' -f2"
ansible db -b -m shell -a "rm -f /etc/ssh/ssh_host_*; ssh-keygen -A; systemctl restart sshd"
sleep 75; ansible db -m ping
ssh-keygen -R "[192.168.56.68]:2222"
ssh-keyscan -p 2222 -t ed25519 192.168.56.68 >> ~/.ssh/known_hosts
ansible db -m ping -o

# ── 6.7 เอกสารส่งมอบ ────────────────────────────────────────
# บนเครื่อง ctl
echo ".ansible/" >> .gitignore
git rm -r -q --cached .ansible
git add .gitignore
git commit -q --amend --no-edit
# ⚠️ `git commit --amend` เขียน commit ล่าสุดทับ ใช้ได้เฉพาะ commit ที่ยังไม่ได้ push ถ้า push ไปแล้ว ให้สร้าง commit ใหม่ที่ลบไฟล์แทน
git status --short
git add .
git commit -m "M15: site.yml, ansible-lint และ Semaphore (บทที่ 6)"
git ls-files | grep -E "vault|pki"
head -1 group_vars/dockerhosts/vault.yml
