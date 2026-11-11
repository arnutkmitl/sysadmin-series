#!/usr/bin/env python3
# log-stats.py สรุป access log ของ nginx: IP, status และหน้าที่หาไม่เจอ
import re
import sys
from collections import Counter, defaultdict

LOG = re.compile(r'(?P<ip>\S+) \S+ \S+ \[(?P<time>[^\]]+)\] "(?P<method>\S+) (?P<path>\S+)[^"]*" (?P<status>\d{3}) (?P<size>\d+|-)')
path = sys.argv[1] if len(sys.argv) > 1 else "/var/log/nginx/access.log"

ips, statuses, hours = Counter(), Counter(), Counter()
not_found = defaultdict(set)
total = bad = 0
with open(path) as f:
    for line in f:
        total += 1
        m = LOG.match(line)
        if not m:
            bad += 1
            continue
        ips[m["ip"]] += 1
        statuses[m["status"]] += 1
        hours[m["time"][12:14]] += 1
        if m["status"] == "404":
            not_found[m["ip"]].add(m["path"])

print(f"อ่าน {total} บรรทัด แยกไม่ได้ {bad} บรรทัด")
print("Top IP     :", ips.most_common(3))
print("Status     :", dict(statuses.most_common()))
print("ตามชั่วโมง :", dict(sorted(hours.items())))
for ip, paths in not_found.items():
    print(f"404 จาก {ip}: {sorted(paths)}")
