#!/usr/bin/env bash
# บทที่ 3 ตัวแปร Template และเงื่อนไข
# SysAdmin Pocket Series M15 Ansible Automation
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 3.1 ตัวแปรและที่เก็บตัวแปร ──────────────────────────────
# บนเครื่อง ctl
ansible-inventory --host ubu2
ansible-playbook playbooks/ch03-demo.yml --tags vars
ansible-playbook playbooks/ch03-demo.yml --tags vars -e "site_title=จาก_extra_vars"

# ── Lab 3.2 รันครั้งแรกบนสองเครื่อง ─────────────────────────
# บนเครื่อง ctl
ansible-playbook playbooks/web-multi.yml

# ── 3.5 Handlers: ทำเมื่อมีการเปลี่ยนแปลงเท่านั้น ───────────
# บนเครื่อง ctl
ansible-playbook playbooks/web-multi.yml

# ── Lab 3.3 เมื่อ handler รายงานว่าสำเร็จ แต่เว็บไม่ทำงาน ────
# บนเครื่อง ctl
ansible-playbook playbooks/web-multi.yml --limit web -e site_port=8090
curl -s -m 5 -o /dev/null -w "%{http_code}\n" http://192.168.56.66:8090/
# บนเครื่อง web
sudo tail -1 /var/log/nginx/error.log

# ── ตรวจปลายทางด้วย uri และ flush_handlers ──────────────────
# บนเครื่อง ctl
ansible-playbook playbooks/web-multi.yml --limit web -e site_port=8090

# ── แก้ต้นเหตุด้วย seport และ notify ────────────────────────
# บนเครื่อง ctl
ansible-playbook playbooks/web-multi.yml --limit web -e site_port=8090
curl -s -m 5 -o /dev/null -w "%{http_code}\n" http://192.168.56.66:8090/
ansible-playbook playbooks/web-multi.yml
ansible web -b -m ansible.posix.firewalld -a "port=8090/tcp permanent=true immediate=true state=disabled"
ansible web -b -m community.general.seport -a "ports=8090 proto=tcp setype=http_port_t state=absent"

# ── failed_when, block และ tags ─────────────────────────────
# บนเครื่อง ctl
ansible-playbook playbooks/ch03-demo.yml
# ⚠️ อย่าใช้ `ignore_errors: true` เพื่อให้ Playbook ผ่าน เพราะ ignore_errors ทำให้ Task ที่ล้มเหลวดูเหมือนไม่มีอะไรเกิดขึ้น และ Task ถัดไปจะทำงานบนเครื่องที่อยู่ในสถานะไม่ครบ ใช้ failed_when เมื่อรู้ว่ารหัสไหนคือความล้มเหลวจริง และใช้ block กับ rescue เมื่อมีทางแก้สำรอง
ansible-playbook playbooks/ch03-demo.yml --list-tags
