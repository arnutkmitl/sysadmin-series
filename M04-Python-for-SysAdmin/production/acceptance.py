#!/usr/bin/env python3
# acceptance.py ตรวจรับ Python Admin Toolkit (รันด้วย sudo พร้อม Python ของ venv)
import stat
import subprocess
from pathlib import Path
import yaml

BASE = Path("/home/admin/python-admin")
PY = BASE / ".venv" / "bin" / "python"
SCRIPTS = ["server-monitor.py", "api-health-check.py", "log-analyzer.py", "user-report.py"]
results = []

def check(name, ok):
    results.append(ok)
    print(f"{'PASS' if ok else 'FAIL'} {name}")

def ok_run(*cmd):
    return subprocess.run(cmd, capture_output=True, text=True, timeout=120).returncode == 0

for cfg in ["servers.yaml", "monitor-config.yaml", "endpoints.yaml", "alert-config.yaml"]:
    path = BASE / "configs" / cfg
    check(f"{cfg} อ่านได้", path.exists() and yaml.safe_load(path.read_text()) is not None)
mode = stat.S_IMODE((BASE / "configs" / "alert-config.yaml").stat().st_mode)
check("alert-config.yaml สิทธิ์ 600", mode == 0o600)
check("ruff ไม่พบปัญหา", ok_run(str(BASE / ".venv/bin/ruff"), "check", "-q", str(BASE / "scripts")))

crontab = subprocess.run(["crontab", "-l", "-u", "admin"], capture_output=True, text=True).stdout
crontab += subprocess.run(["crontab", "-l"], capture_output=True, text=True).stdout
for s in SCRIPTS:
    check(f"{s} รันผ่าน", ok_run(str(PY), str(BASE / "scripts" / s)))
    check(f"{s} อยู่ใน cron พร้อม Python ของ venv", any(s in line and ".venv/bin/python" in line
                                                       for line in crontab.splitlines()))
log = (BASE / "logs" / "admin-toolkit.log").read_text()
check("log มีครบทุก Script", all(f"[{s[:-3]}]" in log for s in SCRIPTS))
check("มีรายงาน HTML", any((BASE / "reports").glob("nginx-*.html")))
check("มี README.md", (BASE / "README.md").is_file())
print(f"\nผ่าน {sum(results)} จาก {len(results)} ข้อ")
