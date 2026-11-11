#!/usr/bin/env python3
# api-health-check.py ตรวจ status และเวลาตอบสนองของ endpoints.yaml แจ้งเตือนเมื่อ endpoint ใดเปลี่ยนสถานะ
import requests
from tabulate import tabulate
from adminlib import changed, get_logger, load_config, notify

cfg = load_config("endpoints.yaml")
log = get_logger("api-health-check")
rows, alerts = [], []
for ep in cfg["endpoints"]:
    try:
        r = requests.get(ep["url"], timeout=ep.get("timeout", 10))
        secs = r.elapsed.total_seconds()
        state = "DOWN" if not r.ok else "SLOW" if secs > cfg["slow_seconds"] else "OK"
        rows.append([ep["name"], r.status_code, f"{secs:.2f}", state])
    except requests.exceptions.RequestException as e:
        state = "DOWN"
        rows.append([ep["name"], "-", "-", f"DOWN {type(e).__name__}"])
    if changed(f"api:{ep['name']}", state):
        alerts.append(f"{ep['name']}: {state}")
    log.info("%s %s", ep["name"], rows[-1][1:])

print(tabulate(rows, headers=["Name", "Status", "Seconds", "State"], tablefmt="simple"))
if alerts:
    for err in notify("API health", "\n".join(alerts)):
        log.error("ส่งแจ้งเตือนไม่สำเร็จ %s", err)
