#!/usr/bin/env python3
# watchdog.py ตรวจ service ตาม watchdog.yaml และ restart ตัวที่หยุด (รันด้วย sudo)
import logging
import subprocess
import time
from pathlib import Path
import yaml

BASE = Path(__file__).resolve().parent.parent
logging.basicConfig(filename=BASE / "logs" / "watchdog.log",
                    format="[%(asctime)s] [%(levelname)s] %(message)s",
                    datefmt="%Y-%m-%d %H:%M:%S", level=logging.INFO)
log = logging.getLogger("watchdog")

def is_active(service):
    return subprocess.run(["systemctl", "is-active", "--quiet", service]).returncode == 0

services = yaml.safe_load((BASE / "configs" / "watchdog.yaml").read_text())["services"]
for svc in services:
    if is_active(svc):
        continue
    log.warning("%s หยุดทำงาน กำลัง restart", svc)
    subprocess.run(["systemctl", "restart", svc], check=False)
    time.sleep(3)
    if is_active(svc):
        log.info("%s กลับมาทำงานแล้ว", svc)
    else:
        log.error("%s restart ไม่สำเร็จ", svc)
log.info("ตรวจครบ %d service", len(services))
