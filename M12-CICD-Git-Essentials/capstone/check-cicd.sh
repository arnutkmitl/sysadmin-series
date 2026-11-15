#!/bin/bash
# check-cicd.sh: ตรวจ pipeline ของ capstone M12 จากเครื่อง ci
# ใช้: ./check-cicd.sh [โฟลเดอร์ repository]   (ค่าเริ่มต้น ~/m12-lab)
REPO=${1:-$HOME/m12-lab}
REGISTRY=192.168.56.30:5000
REMOTE=gitlab
pass=0; fail=0
ok()  { echo "PASS  $1"; pass=$((pass+1)); }
bad() { echo "FAIL  $1"; fail=$((fail+1)); }
check() { local msg=$1; shift; if "$@" > /dev/null 2>&1; then ok "$msg"; else bad "$msg"; fi; }

cd "$REPO" || { echo "ไม่พบ $REPO"; exit 2; }
git fetch -q "$REMOTE" || bad "fetch จาก $REMOTE ไม่ได้"

# 1. Git และ branch
check "remote $REMOTE ชี้ไปที่ gitlab.lab.test" bash -c "git remote get-url $REMOTE | grep -q gitlab.lab.test"
for b in main staging; do
    check "branch $b มีบน $REMOTE" git rev-parse --verify -q "$REMOTE/$b"
done

# 2. image ของหัว branch อยู่ใน registry (tag 8 ตัวแบบ CI_COMMIT_SHORT_SHA)
tags=$(curl -fsS -m 10 "http://$REGISTRY/v2/m12-app/tags/list")
for b in main staging; do
    t=$(git rev-parse --short=8 "$REMOTE/$b")
    if grep -q "\"$t\"" <<< "$tags"; then ok "registry มี image $t ของ $b"; else bad "registry ไม่มี image $t ของ $b"; fi
done

# 3. รุ่นที่รันบน server
ver() { curl -fsS -m 10 "http://$1/version.json" | sed -n 's/.*"commit":"\([0-9a-f]*\)".*/\1/p'; }
stg=$(ver stg.lab.test); prod=$(ver prod.lab.test)
[ -n "$stg" ] && ok "stg ตอบ version.json (commit $stg)" || bad "stg ไม่ตอบ version.json"
[ -n "$prod" ] && ok "prod ตอบ version.json (commit $prod)" || bad "prod ไม่ตอบ version.json"
if [ -n "$stg" ] && git merge-base --is-ancestor "$stg" "$REMOTE/staging" 2>/dev/null; then
    ok "รุ่นบน stg มาจากประวัติของ staging"
else
    bad "รุ่นบน stg ไม่อยู่ในประวัติของ staging"
fi
if [ -n "$prod" ] && git merge-base --is-ancestor "$prod" "$REMOTE/main" 2>/dev/null; then
    ok "รุ่นบน prod มาจากประวัติของ main"
else
    bad "รุ่นบน prod ไม่อยู่ในประวัติของ main"
fi
[ -n "$stg" ] && [ "$stg" = "$(git rev-parse --short=8 "$REMOTE/staging")" ] \
    && ok "stg รันหัวของ staging" || bad "stg ไม่ได้รันหัวของ staging (ยังไม่ deploy หรือ rollback อยู่)"

# 4. runner
check "service gitlab-runner ทำงาน" systemctl is-active -q gitlab-runner
check "runner ของ GitHub Actions ทำงาน" bash -c "systemctl list-units --state=active 'actions.runner.*' | grep -q actions.runner"

# 5. secret
check "ไม่มี private key ของ pipeline ค้างในโฟลเดอร์บ้าน" bash -c "! ls ~/deploy_key ~/gitlab_deploy_key 2>/dev/null | grep -q ."
pattern='(PRIVATE KEY-----|password[[:space:]]*[=:]|AKIA[0-9A-Z]{16}|ghp_[0-9A-Za-z]{36}|glpat-)'
if git grep -qEIi "$pattern" "$REMOTE/main" -- . ':!.env.example' ':!.github/workflows/secret-scan.yml'; then
    bad "พบข้อความคล้าย secret ใน main"
else
    ok "ไม่พบข้อความคล้าย secret ใน main"
fi
check ".gitignore กัน .env" git check-ignore -q .env

echo "----"
echo "ผ่าน $pass จาก $((pass+fail)) ข้อ"
[ "$fail" -eq 0 ]
