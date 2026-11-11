# จัดการไฟล์และ Directory: pathlib และ shutil
# SysAdmin Pocket Series M04 Python for SysAdmin
# ตัวอย่างที่พิมพ์ใน Python interactive (>>>) ตามลำดับในเล่ม ตัด prompt และผลลัพธ์ออกแล้ว
# ให้คัดลอกทีละส่วนไปลองใน python3 หรือ .venv/bin/python ไม่ใช่สคริปต์ที่รันทั้งไฟล์

# ── 2.1 pathlib จัดการ path แบบใหม่
from pathlib import Path
logdir = Path("/var/log")
logdir.is_dir(), (logdir / "messages").exists()
for f in sorted(logdir.glob("*.log")):
    print(f.name, f.stat().st_size)

# ── 2.1 pathlib จัดการ path แบบใหม่
p = Path.home() / "python-admin" / "labs" / "note.txt"
p.write_text("server=web01\nport=2222\n")
p.read_text().splitlines()
p.suffix, p.stem, p.parent.name

# ── 2.2 shutil คัดลอก ย้าย ลบ และบีบอัด
import shutil
shutil.copy2("/etc/hosts", Path.home() / "hosts.bak")
shutil.make_archive("/tmp/configs", "gztar", Path.home() / "python-admin", "configs")
total, used, free = shutil.disk_usage("/")
print(f"ว่าง {free // 2**30} GB")

# ── 2.3 อ่านและเขียน JSON กับ YAML
import json, yaml
cfg = {"server": "web01", "ports": [80, 443], "backup": {"keep_days": 7}}
print(json.dumps(cfg, indent=2))
print(yaml.safe_dump(cfg, sort_keys=False))

# ── 2.4 อ่าน CSV
import csv
with open(Path.home() / "python-admin/configs/servers.csv") as f:
    for row in csv.DictReader(f):
        print(f"{row['host']:<8} {row['ip']:<15} {row['role']}")

# ── 2.5 ไฟล์และโฟลเดอร์ชั่วคราว
import tempfile
with tempfile.TemporaryDirectory() as tmp:
    work = Path(tmp) / "report.txt"
    work.write_text("draft")
    print(work, work.exists())

work.exists()
