#!/usr/bin/env python3
# py-backup.py สำรองไฟล์ตามรายการใน backup-config.yaml
import shutil
import tarfile
import time
from datetime import datetime
from pathlib import Path
import yaml

CONFIG = Path(__file__).resolve().parent.parent / "configs" / "backup-config.yaml"
cfg = yaml.safe_load(CONFIG.read_text())
dest = Path(cfg["dest"])
dest.mkdir(parents=True, exist_ok=True)

name = dest / f"backup-{datetime.now():%Y%m%d-%H%M}.tar.gz"
with tarfile.open(name, "w:gz") as tar:
    for src in cfg["sources"]:
        tar.add(src, arcname=src.lstrip("/"))
print(f"สร้าง {name} ขนาด {name.stat().st_size // 1024} KB")

cutoff = time.time() - cfg["keep_days"] * 86400
old = [f for f in dest.glob("backup-*.tar.gz") if f.stat().st_mtime < cutoff]
for f in old:
    f.unlink()
print(f"ลบ backup ที่เก่ากว่า {cfg['keep_days']} วัน {len(old)} ไฟล์")
print(f"พื้นที่ว่างที่ปลายทาง {shutil.disk_usage(dest).free // 2**30} GB")
