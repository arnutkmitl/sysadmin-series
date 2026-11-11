#!/usr/bin/env python3
# log-report.py สรุป access log ของ nginx พิมพ์ตารางและส่งสรุปผ่าน notify
import re
from collections import Counter
from tabulate import tabulate
from notify import notify

LOG = re.compile(r'(?P<ip>\S+) \S+ \S+ \[(?P<time>[^\]]+)\] "(?P<method>\S+) (?P<path>\S+)[^"]*" (?P<status>\d{3}) (?P<size>\d+|-)')
ips, statuses, errors = Counter(), Counter(), Counter()
with open("/var/log/nginx/access.log") as f:
    for m in filter(None, map(LOG.match, f)):
        ips[m["ip"]] += 1
        statuses[m["status"]] += 1
        if m["status"][0] in "45":
            errors[m["ip"]] += 1

total = sum(ips.values())
error_rate = sum(errors.values()) / total if total else 0
rows = [[ip, n, errors[ip]] for ip, n in ips.most_common(5)]
print(tabulate(rows, headers=["IP", "Requests", "Errors"], tablefmt="simple"))
print(f"\nรวม {total} คำขอ error {error_rate:.0%} status {dict(statuses)}")

summary = [f"รวม {total} คำขอ error {error_rate:.0%}"]
summary += [f"{ip}: {n} ครั้ง error {errors[ip]}" for ip, n in ips.most_common(3)]
failed = notify("Nginx daily report", "\n".join(summary))
print("ส่งแจ้งเตือนไม่สำเร็จ:", failed) if failed else print("ส่งรายงานแล้ว")
