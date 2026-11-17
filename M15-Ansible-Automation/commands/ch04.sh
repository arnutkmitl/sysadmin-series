#!/usr/bin/env bash
# บทที่ 4 Roles, Galaxy และ Vault
# SysAdmin Pocket Series M15 Ansible Automation
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 4.1 ทำไมต้อง Role ───────────────────────────────────────
# บนเครื่อง ctl
ansible-galaxy role init --init-path /tmp demo
find /tmp/demo | sort

# ── Lab 4.1 เขียน Role common ───────────────────────────────
# บนเครื่อง ctl
ansible-playbook playbooks/common.yml
ansible all -m command -a hostname -o

# ── Lab 4.2 ติดตั้ง Docker ด้วย Role จาก Galaxy ─────────────
# บนเครื่อง ctl
ansible-galaxy install -r requirements.yml
ansible-galaxy role list
ansible-playbook playbooks/docker.yml
ansible app -m command -a "docker --version" -o
ansible app -b -m command -a "id ops" -o

# ── Lab 4.3 รหัสผ่านฐานข้อมูลใน Vault ───────────────────────
# บนเครื่อง ctl
install -d -m 700 ~/.ansible
(umask 077; python3 -c "import secrets;print(secrets.token_urlsafe(24))" > ~/.ansible/vault-pass-m15)
ls -l ~/.ansible/vault-pass-m15
printf -- "---\n# group_vars/dbservers/vault.yml\nvault_db_password: %s\n" "$(python3 -c 'import secrets;print(secrets.token_urlsafe(18))')" > group_vars/dbservers/vault.yml
ansible-vault encrypt group_vars/dbservers/vault.yml --vault-password-file ~/.ansible/vault-pass-m15
head -3 group_vars/dbservers/vault.yml
ls -l group_vars/dbservers/
ansible-galaxy collection install -r requirements.yml
ansible-playbook playbooks/db.yml
ansible-playbook playbooks/db.yml --vault-password-file ~/.ansible/vault-pass-m15
ansible-playbook playbooks/db.yml -v

# ── คำสั่งของ ansible-vault ─────────────────────────────────
# บนเครื่อง ctl
ansible-vault encrypt_string "ตัวอย่างเท่านั้น" --name demo_token
printf "demo_token: ตัวอย่างเท่านั้น\n" > /tmp/demo-vault.yml
ansible-vault encrypt /tmp/demo-vault.yml
ansible-vault view /tmp/demo-vault.yml

# ── Lab 4.4 เก็บโปรเจกต์ใน Git ──────────────────────────────
# บนเครื่อง ctl
sudo dnf install -y git
git config --global user.name "admin@ctl"
git config --global user.email admin@ctl.lab.local
git config --global init.defaultBranch main
git init -q
git add .
git status --short
git commit -q -m "M15: โปรเจกต์ Ansible บทที่ 1-4"
git show HEAD:group_vars/dbservers/vault.yml | head -1
