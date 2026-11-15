#!/usr/bin/env bash
# บทที่ 2 GitHub Actions
# SysAdmin Pocket Series M12 CI/CD & Git Essentials: Deploy อัตโนมัติใน 1 วัน
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# แต่ละคำสั่งมีป้ายบอกเครื่อง [ci] [stg] [prod] [docker] [ubu] หรือ [PowerShell] บน Windows
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 2.2 workflow แรก ────────────────────────────────────────
# [ci]
cd ~/m12-lab
mkdir -p .github/workflows
# [ci]
git add .github/workflows/hello.yml
git commit -m "Add first workflow"
git push
# [PowerShell]
gh run list -R arnutkmitl/m12-lab -L 1
gh run view 43608963651 -R arnutkmitl/m12-lab --log

# ── สร้างผู้ใช้ runner และติดตั้ง ───────────────────────────
# [ci]
sudo useradd -m -s /bin/bash runner
sudo usermod -aG docker runner
id runner
# สมาชิกกลุ่ม docker สั่ง Docker ให้รัน container ที่ mount / ของเครื่องได้ จึงมีสิทธิ์เทียบเท่า root ของเครื่องนั้น ผู้ใช้ runner บน ci และผู้ใช้ deploy บน stg และ prod ในหัวข้อถัดไปจึงต้องถือว่าเป็นบัญชีระดับ root บทที่ 4 จะลดความเสี่ยงนี้ด้วยการจำกัดว่าใครสั่งงาน runner ได้
# [ci]
sudo -iu runner

# ── รันเป็น service และปัญหา SELinux ────────────────────────
# [ci]
cd /home/runner/actions-runner
sudo ./svc.sh install runner
sudo ./svc.sh start
# [ci]
sudo ausearch -m avc -ts recent | grep runsvc | tail -1
# [ci]
sudo semanage fcontext -a -t bin_t '/home/runner/actions-runner/runsvc\.sh'
sudo restorecon -v /home/runner/actions-runner/runsvc.sh
sudo systemctl restart actions.runner.arnutkmitl-m12-lab.ci.service
sudo journalctl -u actions.runner.arnutkmitl-m12-lab.ci -n 4 --no-pager -o cat

# ── ห้ามคนนอกใช้ runner ของเรา ──────────────────────────────
# [PowerShell]
gh api repos/arnutkmitl/m12-lab/actions/permissions/fork-pr-contributor-approval
gh api -X PUT repos/arnutkmitl/m12-lab/actions/permissions/fork-pr-contributor-approval -f approval_policy=all_external_contributors
gh api repos/arnutkmitl/m12-lab/actions/permissions/fork-pr-contributor-approval

# ── กุญแจและผู้ใช้ deploy ───────────────────────────────────
# [ci]
ssh-keygen -t ed25519 -C "github-actions deploy" -f ~/deploy_key -N "" -q
cat ~/deploy_key.pub
# [stg]
sudo useradd -m -s /bin/bash deploy
sudo usermod -aG docker deploy
sudo install -d -m 700 -o deploy -g deploy /home/deploy/.ssh
echo 'from="192.168.56.35" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGFWoMatjDP3sQ4tHRj3rDt6Vgm0H5nlSO1Dfk3ZPdyO github-actions deploy' | sudo tee /home/deploy/.ssh/authorized_keys
sudo chown deploy:deploy /home/deploy/.ssh/authorized_keys
sudo chmod 600 /home/deploy/.ssh/authorized_keys
sudo install -d -o deploy -g deploy /srv/m12-app
sudo dnf install -y rsync
# [ci]
ssh-keyscan -p 2222 -t ed25519 stg.lab.test prod.lab.test 2>/dev/null | grep -v "^#" | tee ~/deploy_known_hosts
ssh -i ~/deploy_key -o UserKnownHostsFile=~/deploy_known_hosts -p 2222 deploy@stg.lab.test 'id; docker ps'

# ── ใส่ค่าใน GitHub ─────────────────────────────────────────
# [PowerShell]
ssh -p 2222 admin@192.168.56.35 cat deploy_key | gh secret set DEPLOY_SSH_KEY -R arnutkmitl/m12-lab
ssh -p 2222 admin@192.168.56.35 cat deploy_known_hosts | gh variable set DEPLOY_KNOWN_HOSTS -R arnutkmitl/m12-lab
gh variable set REGISTRY -R arnutkmitl/m12-lab --body "192.168.56.30:5000"
gh secret list -R arnutkmitl/m12-lab

# ── ชุดที่ 2 build และ push image ───────────────────────────
# [ci]
git switch staging
git merge --ff-only main

# ── ชุดที่ 3 deploy ด้วย Compose ────────────────────────────
# [ci]
git add deploy .github/workflows
git commit -m "Add build and deploy pipeline"
git push
# [stg]
curl -s localhost/version.json

# ── ชุดที่ 1 rsync หน้าเว็บ ─────────────────────────────────
# [stg]
sudo install -d -o deploy -g deploy /srv/m12-site
sudo -u deploy docker run -d --name site --restart unless-stopped -p 8081:80 -v /srv/m12-site:/usr/share/nginx/html:ro nginx:1.30-alpine
sudo -u deploy docker ps --format '{{.Names}} {{.Status}} {{.Ports}}'

# ── ชุดที่ 4 รัน Ansible playbook ───────────────────────────
# [ci]
sudo dnf install -y ansible-core
ansible --version | head -n 1

# ── ชุดที่ 5 สำรองข้อมูลตามเวลาและแจ้งเมื่อล้ม ──────────────
# [PowerShell]
gh workflow run backup.yml -R arnutkmitl/m12-lab --ref main -f host=nohost.lab.test

# ── ชุด 1, 4 และ 5 ต้องอยู่บน main ก่อน ─────────────────────
# [ci]
git add .github/workflows ansible
git commit -m "Add site, ansible and backup workflows [skip ci]"
git push
git switch main
git merge --ff-only staging
git push

# ── 2.6 production ต้องมีคนกดอนุมัติ ────────────────────────
# [ci]
git switch main
git pull -q
git merge --no-ff staging -m "Release: heading change"
git push
git log --oneline --graph -4
# [PowerShell]
gh run view 43611789496 -R arnutkmitl/m12-lab
gh api repos/arnutkmitl/m12-lab/actions/runs/43611789496/pending_deployments --jq '.[] | "\(.environment.name) \([.reviewers[].reviewer.login]|join(","))"'
# [PowerShell]
gh api repos/arnutkmitl/m12-lab/actions/runs/43611789496/approvals --jq '.[] | "\(.user.login) \(.state) \([.environments[].name]|join(","))"'
