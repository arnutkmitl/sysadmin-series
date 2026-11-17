#!/usr/bin/env bash
# ภาคผนวก ก Module ที่ใช้ในเล่ม (FQCN)
# SysAdmin Pocket Series M15 Ansible Automation
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── เปิดเอกสารของ Module จาก command line ───────────────────
# บนเครื่อง ctl
cd ~/ansible-lab
ansible-doc -l | wc -l
ansible-doc -l | grep firewalld
ansible-doc -s ansible.builtin.lineinfile | head -6
