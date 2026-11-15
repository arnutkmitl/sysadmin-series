#!/usr/bin/env bash
# บทที่ 4 ความปลอดภัย การ deploy และ rollback
# SysAdmin Pocket Series M12 CI/CD & Git Essentials: Deploy อัตโนมัติใน 1 วัน
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# แต่ละคำสั่งมีป้ายบอกเครื่อง [ci] [stg] [prod] [docker] [ubu] หรือ [PowerShell] บน Windows
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── GitHub: ruleset ของ main ────────────────────────────────
# [ci]
git switch main
git push
# [PowerShell]
gh pr create -R arnutkmitl/m12-lab --base main --head staging --title "Release: ..." --body "ตรวจบน stg แล้ว"
gh pr merge -R arnutkmitl/m12-lab --merge

# ── 4.2 ตรวจ secret ใน pipeline ─────────────────────────────
# [ci]
git switch staging
git add .github/workflows/secret-scan.yml
git commit -m "Add secret scan"
git commit --no-verify -m "Add secret scan"
git push
# [ci]
git switch -c feature/db-config staging
echo 'db_password = "Lab-Only-123"' > app/db.conf
git add app/db.conf
git commit --no-verify -m "Add db config"
git push -u origin feature/db-config
# [PowerShell]
gh pr create -R arnutkmitl/m12-lab --base main --head feature/db-config --title "Add db config" --body "ทดสอบ secret scan"
gh pr merge -R arnutkmitl/m12-lab feature/db-config --merge

# ── 4.4 tag รุ่นที่ขึ้น production ──────────────────────────
# [ci]
git switch main
git pull
git tag -a v1.0 -m "First production release" bd28383
git push origin v1.0
git tag -n
git rev-parse --short v1.0
git rev-parse --short "v1.0^{commit}"

# ── deploy image รุ่นก่อน ───────────────────────────────────
# [PowerShell]
gh workflow run deploy.yml -R arnutkmitl/m12-lab --ref main -f environment=staging -f tag=c68f578
gh run view 43613520781 -R arnutkmitl/m12-lab
# [PowerShell]
gh workflow run deploy.yml -R arnutkmitl/m12-lab --ref staging -f environment=staging -f tag=c68f578
gh run watch 43666314517 -R arnutkmitl/m12-lab
# [stg]
curl -s localhost/version.json

# ── rollback ที่ล้มไม่ทำให้ระบบล่ม ──────────────────────────
# [stg]
curl -s localhost/version.json

# ── git revert ──────────────────────────────────────────────
# [ci]
git switch staging
git pull
git show --stat --oneline 1cce9c7
git revert --no-edit 1cce9c7
git push
# [stg]
curl -s localhost/version.json
curl -s localhost/ | grep "<h1"
