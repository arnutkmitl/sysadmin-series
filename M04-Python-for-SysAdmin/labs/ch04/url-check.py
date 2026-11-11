#!/usr/bin/env python3
# url-check.py ตรวจ status code และเวลาตอบสนองของทุก URL ใน endpoints.yaml
from pathlib import Path
import requests
import yaml
from tabulate import tabulate

cfg = yaml.safe_load((Path(__file__).resolve().parent.parent / "configs" / "endpoints.yaml").read_text())
rows = []
for ep in cfg["endpoints"]:
    try:
        r = requests.get(ep["url"], timeout=10)
        secs = r.elapsed.total_seconds()
        state = "OK" if r.ok and secs < cfg["slow_seconds"] else "SLOW" if r.ok else "ERROR"
        rows.append([ep["name"], r.status_code, f"{secs:.2f}", state])
    except requests.exceptions.RequestException as e:
        rows.append([ep["name"], "-", "-", f"DOWN ({type(e).__name__})"])
print(tabulate(rows, headers=["Name", "Status", "Seconds", "State"], tablefmt="github"))
