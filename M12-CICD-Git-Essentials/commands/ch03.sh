#!/usr/bin/env bash
# บทที่ 3 GitLab CI
# SysAdmin Pocket Series M12 CI/CD & Git Essentials: Deploy อัตโนมัติใน 1 วัน
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# แต่ละคำสั่งมีป้ายบอกเครื่อง [ci] [stg] [prod] [docker] [ubu] หรือ [PowerShell] บน Windows
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 3.2 เปิด GitLab และสร้างโปรเจกต์ ────────────────────────
# [docker]
cd ~/stacks/gitlab
docker compose up -d
until curl -s -o /dev/null -w '%{http_code}' http://gitlab.lab.test:8929/users/sign_in | grep -q 200; do sleep 15; done; echo ready

# ── ใส่กุญแจของ ci เป็น deploy key ──────────────────────────
# [ci]
cd ~/m12-lab
git remote add gitlab ssh://git@gitlab.lab.test:2424/infra/m12-lab.git
git remote -v
ssh -T -p 2424 git@gitlab.lab.test
git push gitlab main staging

# ── 3.3 ติดตั้ง GitLab Runner บน ci ─────────────────────────
# [ci]
curl -sSL -o runner-repo.sh https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh
less runner-repo.sh
sudo bash runner-repo.sh
sudo dnf install -y gitlab-runner
gitlab-runner --version | head -n 2
id gitlab-runner
# [ci]
sudo usermod -aG docker gitlab-runner
sudo systemctl restart gitlab-runner

# ── ลงทะเบียน runner ด้วย authentication token ──────────────
# [ci]
sudo gitlab-runner register --non-interactive \
      --url http://gitlab.lab.test:8929 \
      --token glrt-XXXXXXXXXXXXXXXXXXXX \
      --executor shell \
      --name ci-shell
# [ci]
sudo gitlab-runner register --non-interactive \
      --url http://gitlab.lab.test:8929 \
      --token glrt-YYYYYYYYYYYYYYYYYYYY \
      --executor docker \
      --docker-image alpine:3.22 \
      --docker-extra-hosts gitlab.lab.test:192.168.56.30 \
      --name ci-docker
sudo gitlab-runner list
sudo gitlab-runner verify

# ── 3.4 CI/CD variables ─────────────────────────────────────
# [ci]
ssh-keygen -t ed25519 -C "gitlab-ci deploy" -f ~/gitlab_deploy_key -N "" -q
cat ~/gitlab_deploy_key.pub
# [stg]
echo 'from="192.168.56.35" ssh-ed25519 AAAA...(public key ใหม่)... gitlab-ci deploy' | sudo tee -a /home/deploy/.ssh/authorized_keys

# ── 3.5 .gitlab-ci.yml ──────────────────────────────────────
# [ci]
git switch staging
git add .gitlab-ci.yml
git commit -m "Add GitLab CI pipeline"
git push gitlab staging
# [stg]
curl -s localhost/version.json

# ── 3.6 deploy production ด้วยปุ่ม ──────────────────────────
# [ci]
git switch main
git merge --no-ff staging -m "Release: GitLab pipeline"
git push gitlab main
# [prod]
curl -s localhost/version.json
