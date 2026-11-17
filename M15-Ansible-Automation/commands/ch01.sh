#!/usr/bin/env bash
# บทที่ 1 พื้นฐาน Ansible และคำสั่ง Ad-Hoc
# SysAdmin Pocket Series M15 Ansible Automation
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 1.2 ติดตั้ง Ansible บน ctl ──────────────────────────────
# บนเครื่อง ctl
sudo dnf install -y ansible-core
ansible --version

# ── Lab 1.1 โฟลเดอร์โปรเจกต์และ ansible.cfg ─────────────────
# บนเครื่อง ctl
mkdir ~/ansible-lab
cd ~/ansible-lab
cd /tmp && ansible --version | sed -n 2p
cd ~/ansible-lab && ansible --version | sed -n 2p
ansible-config dump --only-changed

# ── Lab 1.2 ตรวจ Inventory ──────────────────────────────────
# บนเครื่อง ctl
ansible-inventory --graph
ansible-inventory --host ubu2
ansible 'rocky:!dbservers' --list-hosts

# ── Lab 1.3 สำรวจและแก้ไขทุกเครื่อง ─────────────────────────
# บนเครื่อง ctl
ansible all -m ping -o
ansible rocky -m command -a uptime
ansible all -m shell -a "df -h / | tail -1"
ansible rocky -m ansible.builtin.dnf -a "name=tree state=present"
ansible rocky -b -m ansible.builtin.dnf -a "name=tree state=present" -o
ansible rocky -b -m ansible.builtin.dnf -a "name=tree state=present" -o
ansible all -b -m ansible.builtin.package -a "name=tree state=present" -o
ansible all -b -m ansible.builtin.copy -a "content='เครื่องนี้จัดการด้วย Ansible จาก ctl\n' dest=/etc/motd mode=0644"
ansible rocky -b -m ansible.builtin.service -a "name=chronyd state=started enabled=true" -o

# ── 1.5 Module ที่ใช้บ่อยและ Collection ─────────────────────
# บนเครื่อง ctl
ansible-galaxy collection install community.general -p /tmp/coltest
ANSIBLE_COLLECTIONS_PATH=/tmp/coltest ansible localhost -m community.general.timezone -a name=Asia/Bangkok --check

# ── Lab 1.4 ติดตั้ง collection ของโปรเจกต์ ──────────────────
# บนเครื่อง ctl
ansible-galaxy collection install -r requirements.yml
ansible-galaxy collection list
ansible ubu2 -b -m community.general.timezone -a name=Asia/Bangkok

# ── 1.6 Facts: ข้อมูลของเครื่องที่ Ansible เก็บให้ ──────────
# บนเครื่อง ctl
ansible all -m ansible.builtin.setup -a "filter=ansible_distribution*"
