#!/usr/bin/env python3
# user-report.py รายงานผู้ใช้: กลุ่ม sudo, ล็อกอินล่าสุด, อายุรหัสผ่าน และ shell แล้วส่งอีเมล (รันด้วย sudo)
import grp
import pwd
import subprocess
from datetime import date
from tabulate import tabulate
from adminlib import get_logger, load_config, send_html_email

cfg = load_config("monitor-config.yaml")["user_report"]
log = get_logger("user-report")
sudoers = set(grp.getgrnam(cfg["sudo_group"]).gr_mem)

def run(*cmd):
    return subprocess.run(cmd, capture_output=True, text=True).stdout

def last_login(user):
    for word in run("last", "-n1", "--time-format", "iso", user).split():
        if word[:4].isdigit() and "T" in word:
            return word[:16].replace("T", " ")        # 2026-11-11T10:53:47+07:00 -> 2026-11-11 10:53
    return "ไม่มีประวัติ"

def password_changed(user):
    for line in run("chage", "-l", user).splitlines():
        if line.startswith("Last password change"):
            return line.split(":", 1)[1].strip()
    return "-"

rows = []
for u in pwd.getpwall():
    if u.pw_uid < 1000 or u.pw_uid >= 65534 or u.pw_shell.endswith(("nologin", "false")):
        continue
    rows.append([u.pw_name, "yes" if u.pw_name in sudoers else "",
                 last_login(u.pw_name), password_changed(u.pw_name), u.pw_shell])

headers = ["User", "Sudo", "Last login", "Password changed", "Shell"]
print(tabulate(rows, headers=headers, tablefmt="simple"))
mailed = send_html_email(f"User report {date.today()}", tabulate(rows, headers=headers, tablefmt="html"))
log.info("รายงานผู้ใช้ %d บัญชี อีเมล %s", len(rows), mailed)
