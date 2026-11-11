#!/usr/bin/env python3
# log-analyzer.py สรุป access log ของ nginx เป็นรายงาน HTML บันทึกลง reports/ และส่งอีเมล (รันด้วย sudo)
import re
from collections import Counter
from datetime import date
from tabulate import tabulate
from adminlib import BASE, get_logger, load_config, own, send_html_email

LOG = re.compile(r'(?P<ip>\S+) \S+ \S+ \[(?P<time>[^\]]+)\] "(?P<method>\S+) (?P<path>\S+)[^"]*" (?P<status>\d{3}) (?P<size>\d+|-)')
cfg = load_config("monitor-config.yaml")["log_analyzer"]
log = get_logger("log-analyzer")

ips, statuses, paths, sent = Counter(), Counter(), Counter(), 0
with open(cfg["access_log"]) as f:
    for m in filter(None, map(LOG.match, f)):
        ips[m["ip"]] += 1
        statuses[m["status"]] += 1
        sent += int(m["size"]) if m["size"] != "-" else 0
        if m["status"] == "404":
            paths[m["path"]] += 1

total = sum(statuses.values())
errors = sum(n for s, n in statuses.items() if s[0] in "45")
summary = [["คำขอทั้งหมด", total], ["error (4xx, 5xx)", f"{errors} ({errors / max(total, 1):.0%})"],
           ["ข้อมูลที่ส่งออก", f"{sent / 2**20:.1f} MB"]]
html = f"""<h2>Nginx report {date.today()}</h2>
{tabulate(summary, tablefmt="html")}
<h3>Top {cfg['top']} IP</h3>{tabulate(ips.most_common(cfg['top']), headers=["IP", "Requests"], tablefmt="html")}
<h3>Status</h3>{tabulate(sorted(statuses.items()), headers=["Status", "Count"], tablefmt="html")}
<h3>หน้าที่หาไม่เจอ</h3>{tabulate(paths.most_common(cfg['top']), headers=["Path", "404"], tablefmt="html")}"""

out = BASE / "reports" / f"nginx-{date.today()}.html"
out.parent.mkdir(exist_ok=True)
out.write_text(html)
own(out.parent)
own(out)
mailed = send_html_email(f"Nginx report {date.today()}", html)
log.info("สรุป %d คำขอ error %d บันทึก %s อีเมล %s", total, errors, out.name, mailed)
print(tabulate(summary, tablefmt="plain"))
print(f"รายงาน: {out} | อีเมล: {'ส่งแล้ว' if mailed else 'ไม่ได้ตั้งค่า'}")
