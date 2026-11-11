# Log Analysis และ Report: อ่าน Log แล้วสร้างรายงาน
# SysAdmin Pocket Series M04 Python for SysAdmin
# ตัวอย่างที่พิมพ์ใน Python interactive (>>>) ตามลำดับในเล่ม ตัด prompt และผลลัพธ์ออกแล้ว
# ให้คัดลอกทีละส่วนไปลองใน python3 หรือ .venv/bin/python ไม่ใช่สคริปต์ที่รันทั้งไฟล์

# ── 5.1 อ่านไฟล์ใหญ่ทีละบรรทัด
from collections import deque
with open("/var/log/nginx/access.log") as f:
    last = deque(f, maxlen=3)

len(last)

# ── 5.2 แยกฟิลด์ด้วย regular expression
import re
LOG = re.compile(r'(?P<ip>\S+) \S+ \S+ \[(?P<time>[^\]]+)\] "(?P<method>\S+) (?P<path>\S+)[^"]*" (?P<status>\d{3}) (?P<size>\d+|-)')
line = '192.168.56.20 - - [11/Nov/2026:14:30:42 +0700] "GET /wp-login.php HTTP/1.1" 404 153 "-" "curl/8.12.1" "-"'
m = LOG.match(line)
m["ip"], m["path"], m["status"], m["time"][12:14]

# ── 5.4 สร้างรายงาน
from tabulate import tabulate
rows = [["192.168.56.20", 59, 13], ["192.168.56.1", 16, 1]]
print(tabulate(rows, headers=["IP", "Requests", "404"], tablefmt="simple"))
tabulate(rows, headers=["IP", "Requests", "404"], tablefmt="html")[:60]
