#!/usr/bin/env bash
# บทที่ 1 Git สำหรับผู้ดูแลระบบ
# SysAdmin Pocket Series M12 CI/CD & Git Essentials: Deploy อัตโนมัติใน 1 วัน
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# แต่ละคำสั่งมีป้ายบอกเครื่อง [ci] [stg] [prod] [docker] [ubu] หรือ [PowerShell] บน Windows
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 1.1 ติดตั้งและตั้งค่า Git ───────────────────────────────
# [ci]
sudo dnf install -y git
git --version
# [ci]
git config --global user.name "Lab Admin"
git config --global user.email "admin@lab.test"
git config --global init.defaultBranch main
git config --global core.editor vi
git config --global pull.rebase false
git config --global --list
# [ci]
cat ~/.gitconfig

# ── 1.2 กุญแจ SSH และ deploy key ────────────────────────────
# [ci]
ssh-keygen -t ed25519 -C "ci-m12-lab" -f ~/.ssh/id_ed25519 -N ""
cat ~/.ssh/id_ed25519.pub
# [PowerShell]
gh repo deploy-key add ci.pub -R arnutkmitl/m12-lab --title "ci (192.168.56.35)" --allow-write
gh repo deploy-key list -R arnutkmitl/m12-lab
# [ci]
ssh -T git@github.com

# ── clone, add, commit และ push ─────────────────────────────
# [ci]
git clone git@github.com:arnutkmitl/m12-lab.git
cd m12-lab
echo "# m12-lab: Lab ของหนังสือ CI/CD & Git Essentials" > README.md
git status
# [ci]
git add README.md
git status --short
git commit -m "Add README"
git log --oneline
git push -u origin main

# ── เพิ่มแอปที่จะ deploy ────────────────────────────────────
# [ci]
mkdir -p app/site app/tests
cat > app/site/index.html <<'EOF'
<!doctype html>
<html lang="th">
<head><meta charset="utf-8"><title>M12 Lab App</title></head>
<body>
<h1>M12 Lab App</h1>
<p>version: @VERSION@</p>
<p>commit: @COMMIT@</p>
</body>
</html>
EOF
# [ci]
cat > app/Dockerfile <<'EOF'
FROM nginx:1.30-alpine
ARG VERSION=dev
ARG COMMIT=unknown
COPY site/ /usr/share/nginx/html/
RUN sed -i "s/@VERSION@/${VERSION}/; s/@COMMIT@/${COMMIT}/" /usr/share/nginx/html/index.html \
 && printf '{"version":"%s","commit":"%s"}\n' "$VERSION" "$COMMIT" > /usr/share/nginx/html/version.json
HEALTHCHECK --interval=10s --timeout=3s CMD wget -qO- http://127.0.0.1/version.json || exit 1
EOF
# [ci]
cat > app/tests/test.sh <<'EOF'
#!/bin/bash
# ตรวจไฟล์เว็บก่อน build: ต้องมี title และตัวแทน version/commit ครบ
set -e
f=site/index.html
grep -q '<title>' "$f"
grep -q '@VERSION@' "$f"
grep -q '@COMMIT@' "$f"
echo "test passed: $f"
EOF
chmod +x app/tests/test.sh
git status --short
git add app
git status --short
git commit -m "Add web app with version page"

# ── diff, restore และ log ───────────────────────────────────
# [ci]
sed -i 's|<h1>M12 Lab App</h1>|<h1>M12 Lab App (staging)</h1>|' app/site/index.html
git diff
git restore app/site/index.html
git diff --stat
# [ci]
git log --oneline --stat -1
git push

# ── fetch และ pull ──────────────────────────────────────────
# [ci]
git fetch
git status

# ── 1.4 branch และ merge ────────────────────────────────────
# [ci]
git switch -c staging
git push -u origin staging
git switch -c feature/footer
sed -i 's|</body>|<footer>SysAdmin Knowledge Press</footer>\n</body>|' app/site/index.html
git commit -am "Add footer"
# [ci]
git switch staging
git merge feature/footer
git push
git branch -d feature/footer

# ── 1.5 แก้ conflict ────────────────────────────────────────
# [ci]
git switch main
git switch -c feature/title-a
sed -i 's|<title>M12 Lab App</title>|<title>M12 App</title>|' app/site/index.html
git commit -am "Shorten title"
git switch main
git switch -c feature/title-b
sed -i 's|<title>M12 Lab App</title>|<title>M12 Lab Web App</title>|' app/site/index.html
git commit -am "Rename title"
git switch main
git merge feature/title-a
git merge feature/title-b
# [ci]
git status --short
sed -n 1,7p app/site/index.html
# [ci]
sed -i '/^<<<<<<< /d; /^=======/d; /^>>>>>>> /d; /<title>M12 App<\/title>/d' app/site/index.html
sed -n 1,5p app/site/index.html
git add app/site/index.html
git commit --no-edit
git log --oneline --graph -6
git branch -d feature/title-a feature/title-b

# ── 1.6 rebase ──────────────────────────────────────────────
# [ci]
git switch -c feature/docs
echo "แอปตัวอย่างอยู่ในโฟลเดอร์ app/" >> README.md
git commit -am "Describe app folder"
git switch main
git merge staging -m "Merge staging into main"
git switch feature/docs
git rebase main
git log --oneline --graph -3
git switch main
git merge --ff-only feature/docs
git branch -d feature/docs
git push

# ── 1.7 เก็บ /etc ด้วย etckeeper ────────────────────────────
# [prod]
sudo dnf install -y epel-release
sudo dnf install -y etckeeper etckeeper-dnf
sudo git config --global init.defaultBranch main
sudo etckeeper init
sudo etckeeper commit "Initial commit of /etc"
sudo git -C /etc log --oneline
# [prod]
echo "Managed by Git (etckeeper). Do not edit by hand without commit." | sudo tee /etc/motd
sudo etckeeper vcs status --short
sudo etckeeper vcs diff
sudo etckeeper commit "Add motd notice"
# [prod]
sudo systemctl enable --now etckeeper.timer
systemctl list-timers etckeeper.timer --no-pager
# [prod]
sudo dnf install -y sysstat
sudo git -C /etc log --oneline -3
sudo git -C /etc show --stat HEAD | head -14
# repository ใน /etc เก็บ /etc/shadow และ /etc/gshadow ซึ่งมี hash รหัสผ่านของทุกบัญชี etckeeper ป้องกันด้วยการตั้ง /etc/.git เป็นสิทธิ์ 700 ของ root ห้าม push repository นี้ขึ้น GitHub หรือ GitLab ทั้งแบบ public และ private ถ้าต้องสำรอง /etc ไปเครื่องอื่น ใช้วิธีสำรองข้อมูลแบบเข้ารหัสใน M17
# [prod]
sudo git -C /etc ls-files shadow gshadow
sudo stat -c '%a %U %n' /etc/.git

# ── 1.8 กันรหัสผ่านไม่ให้หลุดเข้า Git ───────────────────────
# [ci]
printf 'DB_USER=app\nDB_PASSWORD=Lab-Only-123\n' > .env
cat > .gitignore <<'EOF'
# ไฟล์ลับ ห้ามเข้า Git
.env
*.key
*.pem
id_*
# ไฟล์ชั่วคราว
*.swp
*.bak
EOF
git status --short
git check-ignore -v .env
# [ci]
cat > .env.example <<'EOF'
DB_USER=app
DB_PASSWORD=change-me
EOF
git add .gitignore .env.example
git commit -m "Ignore secret files, add .env.example"
# [ci]
mkdir -p deploy && echo "-----BEGIN OPENSSH PRIVATE KEY-----" > deploy/backup.key
git add -f deploy/backup.key
git commit -m "Add deploy key by mistake"
git rm --cached deploy/backup.key
git commit -m "Stop tracking deploy/backup.key"
git log --oneline --all -- deploy/backup.key
# [ci]
# ⚠️ คำสั่งนี้ลบหรือเขียนทับงานแบบย้อนไม่ได้ อ่านคำอธิบายในเล่มก่อนรัน
git reset --hard HEAD~2
ls deploy/
# [ci]
cat > .git/hooks/pre-commit <<'EOF'
#!/bin/bash
# กัน secret เข้า commit: ตรวจเฉพาะบรรทัดที่เพิ่มใน staged changes
pattern='(PRIVATE KEY-----|password[[:space:]]*[=:]|AKIA[0-9A-Z]{16}|ghp_[0-9A-Za-z]{36}|glpat-)'
if git diff --cached -U0 | grep '^+' | grep -v '^+++' | grep -Eiq "$pattern"; then
    echo "pre-commit: พบข้อความที่อาจเป็น secret ยกเลิก commit"
    git diff --cached -U0 | grep '^+' | grep -v '^+++' | grep -Ein "$pattern"
    exit 1
fi
EOF
chmod +x .git/hooks/pre-commit
echo 'mysql -u app --password=Lab-Only-123 app < backup.sql' > restore-db.sh
git add restore-db.sh
git commit -m "Add restore script"
# [ci]
echo 'mysql --defaults-extra-file=/etc/app/db.cnf app < backup.sql' > restore-db.sh
git add restore-db.sh
git commit -m "Add restore script"
git push

# ── reset ───────────────────────────────────────────────────
# [ci]
sed -i 's|<h1>M12 Lab App</h1>|<h1>Broken</h1>|' app/site/index.html
git commit -am "Try new heading"
git reset --soft HEAD~1
git status --short
git log --oneline -1
git restore --staged app/site/index.html
git restore app/site/index.html
# [ci]
echo "test" >> README.md
git status --short
# ⚠️ คำสั่งนี้ลบหรือเขียนทับงานแบบย้อนไม่ได้ อ่านคำอธิบายในเล่มก่อนรัน
git reset --hard
git status --short

# ── revert ──────────────────────────────────────────────────
# [ci]
sed -i 's|<p>commit: @COMMIT@</p>|<p>git commit: @COMMIT@</p>|' app/site/index.html
git commit -am "Label commit line"
git push
git revert --no-edit HEAD
git log --oneline -3
git push

# ── stash ───────────────────────────────────────────────────
# [ci]
sed -i 's|<h1>M12 Lab App</h1>|<h1>M12 Lab App v2</h1>|' app/site/index.html
git stash
git stash list
git switch staging
git switch main
git stash pop
git diff --stat

# ── Ubuntu Server 26.04 ─────────────────────────────────────
# [ubu]
sudo apt-get install -y etckeeper
sudo git -C /etc log --oneline
sudo apt-get install -y smartmontools
