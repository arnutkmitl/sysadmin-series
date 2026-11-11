#!/usr/bin/env python3
# set-port.py เปลี่ยนค่า port ในไฟล์ YAML ใช้: ./set-port.py app.yaml 9090
import shutil
import sys
from pathlib import Path
import yaml

if len(sys.argv) != 3:
    sys.exit(f"Usage: {sys.argv[0]} <file.yaml> <port>")
path, port = Path(sys.argv[1]), int(sys.argv[2])

data = yaml.safe_load(path.read_text())
old = data.get("port")
shutil.copy2(path, path.with_suffix(path.suffix + ".bak"))
data["port"] = port
path.write_text(yaml.safe_dump(data, sort_keys=False, allow_unicode=True))
print(f"{path}: port {old} -> {port}")
