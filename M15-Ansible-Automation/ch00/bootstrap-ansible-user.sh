#!/bin/bash
# /home/admin/bootstrap-ansible-user.sh
# สร้างผู้ใช้ ansible บน managed node ทุกเครื่อง ให้เข้าด้วย key ของ ctl และใช้ sudo โดยไม่ถามรหัสผ่าน
# รันบน ctl ด้วยผู้ใช้ admin หลัง ssh-copy-id ไปทุกเครื่องแล้ว
set -euo pipefail
NODES="${NODES:-192.168.56.66 192.168.56.67 192.168.56.68 192.168.56.82}"
PUB=$(cat ~/.ssh/id_ed25519.pub)

for h in $NODES; do
    echo "== $h"
    ssh -t -p 2222 "admin@$h" "
        id ansible >/dev/null 2>&1 || sudo useradd -m -s /bin/bash ansible
        sudo install -d -m 700 -o ansible -g ansible /home/ansible/.ssh
        echo '$PUB' | sudo tee /home/ansible/.ssh/authorized_keys >/dev/null
        sudo chown ansible:ansible /home/ansible/.ssh/authorized_keys
        sudo chmod 600 /home/ansible/.ssh/authorized_keys
        command -v restorecon >/dev/null && sudo restorecon -R /home/ansible/.ssh
        echo 'ansible ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/ansible >/dev/null
        sudo chmod 440 /etc/sudoers.d/ansible
        sudo visudo -cf /etc/sudoers.d/ansible
    "
done
