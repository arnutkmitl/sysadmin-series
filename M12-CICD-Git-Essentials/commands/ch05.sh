#!/usr/bin/env bash
# บทที่ 5 โปรเจกต์จบเล่ม: pipeline ครบวงจรบน GitLab
# SysAdmin Pocket Series M12 CI/CD & Git Essentials: Deploy อัตโนมัติใน 1 วัน
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# แต่ละคำสั่งมีป้ายบอกเครื่อง [ci] [stg] [prod] [docker] [ubu] หรือ [PowerShell] บน Windows
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 5.2 เตรียมโปรเจกต์ ──────────────────────────────────────
# [ci]
mkdir -p ~/bin && cp check-cicd.sh ~/bin/ && chmod +x ~/bin/check-cicd.sh
check-cicd.sh

# ── 5.3 งานใหม่ผ่าน feature branch ──────────────────────────
# [ci]
cd ~/m12-lab
git switch staging
git pull gitlab staging
git switch -c feature/service-hours
sed -i 's|<footer>|<p>เปิดให้บริการ 08:30-16:30 น.</p>\n<footer>|' app/site/index.html
git diff
git commit -am "Show service hours"
git push -u gitlab feature/service-hours

# ── 5.4 merge request เข้า staging ──────────────────────────
# [stg]
curl -s localhost/ | grep บริการ
# [ci]
check-cicd.sh

# ── 5.5 release เข้า production ─────────────────────────────
# [prod]
curl -s localhost/version.json
# [ci]
git fetch gitlab && git tag -a v1.1 -m "Service hours" gitlab/main && git push gitlab v1.1
git diff --stat gitlab/staging gitlab/main -- app deploy
check-cicd.sh | tail -1

# ── 5.6 ซ้อม rollback ───────────────────────────────────────
# [prod]
curl -s localhost/version.json
curl -s localhost/ | grep -c บริการ

# ── 5.7 ตรวจครบทุกข้อ ───────────────────────────────────────
# [ci]
git switch main
git pull --ff-only gitlab main
git commit --allow-empty -m "Direct push test"
git push gitlab main
git reset --hard gitlab/main
check-cicd.sh | tail -1
