#!/usr/bin/env python3
# server-monitor.py ตรวจ CPU, RAM, ดิสก์ และ service ตาม monitor-config.yaml แจ้งเตือนเมื่อสถานะเปลี่ยน
import socket
import subprocess
import psutil
from adminlib import changed, get_logger, load_config, notify

cfg = load_config("monitor-config.yaml")
log = get_logger("server-monitor")
limit = cfg["limits"]
checks = {
    "cpu": psutil.cpu_percent(interval=1),
    "ram": psutil.virtual_memory().percent,
    **{f"disk {m}": psutil.disk_usage(m).percent for m in cfg["disks"]},
}
problems = [f"{name} {value:.0f}% (เกณฑ์ {limit[name.split()[0]]}%)"
            for name, value in checks.items() if value >= limit[name.split()[0]]]
for svc in cfg["services"]:
    if subprocess.run(["systemctl", "is-active", "--quiet", svc]).returncode != 0:
        problems.append(f"service {svc} ไม่ทำงาน")

status = "; ".join(problems) or "OK"
log.info("%s", " ".join(f"{k}={v:.0f}%" for k, v in checks.items()) + f" -> {status}")
if changed("server-monitor", status):            # แจ้งเฉพาะตอนเกิดปัญหาและตอนกลับมาปกติ
    title = f"[{socket.gethostname()}] " + ("กลับมาปกติ" if status == "OK" else "พบปัญหา")
    for err in notify(title, status.replace("; ", "\n")):
        log.error("ส่งแจ้งเตือนไม่สำเร็จ %s", err)
print(status)
