#!/usr/bin/env bash
# บทที่ 2 Playbook: เขียนแผนงานเป็น YAML
# SysAdmin Pocket Series M15 Ansible Automation
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── Lab 2.1 ติดตั้ง Nginx ด้วย Playbook ─────────────────────
# บนเครื่อง ctl
ansible-playbook playbooks/webserver.yml --syntax-check
ansible-playbook playbooks/webserver.yml --list-tasks
ansible-playbook playbooks/webserver.yml
curl -s http://192.168.56.66/
ansible-playbook playbooks/webserver.yml --diff

# ── 2.3 Idempotent: รันซ้ำแล้วต้องไม่เปลี่ยนอะไร ────────────
# บนเครื่อง ctl
ansible-playbook playbooks/webserver.yml
ansible-playbook playbooks/hosts-bad.yml
ansible-playbook playbooks/hosts-bad.yml
ansible rocky -m command -a "grep -c ctl.lab.local /etc/hosts" -o
ansible rocky -b -m ansible.builtin.lineinfile -a "path=/etc/hosts regexp=ctl.lab.local state=absent"
ansible-playbook playbooks/hosts-good.yml
ansible-playbook playbooks/hosts-good.yml
ansible rocky -m command -a "grep -c ctl.lab.local /etc/hosts" -o

# ── Lab 2.2 ทำให้ command รันซ้ำได้ ─────────────────────────
# บนเครื่อง ctl
time ansible-playbook playbooks/command-idempotent.yml
time ansible-playbook playbooks/command-idempotent.yml

# ── 2.4 ตรวจก่อนรันจริง ─────────────────────────────────────
# บนเครื่อง ctl
ansible-playbook playbooks/hosts-good.yml --check --diff --limit web
ansible-playbook playbooks/webserver.yml --check

# ── ตรวจ YAML ก่อนรัน ───────────────────────────────────────
# บนเครื่อง ctl
ansible-playbook playbooks/broken.yml --syntax-check
