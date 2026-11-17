#!/usr/bin/env bash
# ภาคผนวก ข เครื่องมือไล่ปัญหา
# SysAdmin Pocket Series M15 Ansible Automation
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── ตรวจก่อนรัน ─────────────────────────────────────────────
# บนเครื่อง ctl
ansible-config dump --only-changed
ansible-inventory --host web
ansible-playbook playbooks/broken.yml --syntax-check
ansible web -b -m ansible.builtin.lineinfile -a "path=/etc/motd line=TEST" --check --diff

# ── รันเฉพาะบางส่วน ─────────────────────────────────────────
# บนเครื่อง ctl
ansible-playbook playbooks/webserver.yml --limit web --start-at-task "เปิดบริการ nginx"
ansible-playbook playbooks/webserver.yml --list-tasks
ansible-playbook playbooks/webserver.yml --limit web --start-at-task "เปิดบริการ nginx และให้เริ่มเองหลัง Reboot"
ansible-playbook playbooks/webserver.yml --limit web --step

# ── ดูค่าระหว่างรัน ─────────────────────────────────────────
# บนเครื่อง ctl
ansible web -m ansible.builtin.debug -a "var=site_port"
ansible web -m ansible.builtin.debug -a "msg={{ ansible_distribution }}"
ansible web -m ansible.builtin.setup -a "filter=ansible_distribution*"

# ── -v ถึง -vvvv: ดูการเชื่อมต่อ ────────────────────────────
# บนเครื่อง ctl
ansible web -m ping -vvv

# ── ansible-console: ad-hoc แบบโต้ตอบ ───────────────────────
# บนเครื่อง ctl
ansible-console web
