#!/usr/bin/env bash
# บทที่ 5 Playbook พร้อมใช้ 8 ชุด
# SysAdmin Pocket Series M15 Ansible Automation
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── Playbook #1 ตั้งค่าเครื่องใหม่ ──────────────────────────
# บนเครื่อง ctl
ansible-playbook playbooks/ready/01-initial-setup.yml
ansible ubu2 -b -m command -a "ufw status"

# ── Playbook #2 Security hardening ──────────────────────────
# บนเครื่อง ctl
ansible all -b -m shell -a "ls /etc/ssh/sshd_config.d/; sshd -T | grep -E '^(permitrootlogin|maxauthtries|port) '"
ansible all -b -m command -a "fail2ban-client status sshd" | grep -E "SUCCESS|CHANGED|Journal"

# ── Playbook #3 Nginx และ HTTPS ─────────────────────────────
# บนเครื่อง ctl
ansible-playbook playbooks/ready/03-nginx-tls.yml
ansible-playbook playbooks/ready/03-nginx-tls.yml
curl -sv --cacert pki/m15-ca.crt https://192.168.56.66/ -o /dev/null 2>&1 | grep -E 'SSL connection|subject:|issuer:|expire date|< HTTP'

# ── Playbook #5 Docker host ─────────────────────────────────
# บนเครื่อง ctl
ansible-playbook playbooks/ready/05-docker-host.yml

# ── Playbook #6 Monitoring ──────────────────────────────────
# บนเครื่อง ctl
ansible-playbook playbooks/ready/06-monitoring.yml

# ── Playbook #7 Backup และแจ้งผลทาง LINE ────────────────────
# บนเครื่อง ctl
ansible-vault edit group_vars/dbservers/vault.yml
sudo firewall-cmd --add-rich-rule="rule family=ipv4 source address=192.168.56.68/32 port port=8099 protocol=tcp accept"
nohup python3 lab-mock/line_mock.py 8099 /tmp/line-mock.log >/dev/null 2>&1 &
ansible-playbook playbooks/ready/07-backup.yml
ansible db -b -m command -a "systemctl start backup-db.service"
ansible db -b -m shell -a "systemctl list-timers backup-db.timer --no-pager | head -2; ls -l /var/backup/mariadb"
cat /tmp/line-mock.log

# ── Playbook #8 ลงแพตช์ทีละเครื่อง ──────────────────────────
# บนเครื่อง web
systemctl --failed --no-pager
sudo journalctl -u kdump -b --no-pager | grep kdumpctl
# บนเครื่อง ctl
time ansible-playbook playbooks/ready/08-patch.yml
