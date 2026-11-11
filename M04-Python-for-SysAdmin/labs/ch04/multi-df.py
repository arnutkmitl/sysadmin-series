#!/usr/bin/env python3
# multi-df.py รัน df -h / บนทุกเครื่องใน servers.yaml แล้วสรุปเป็นตาราง
from pathlib import Path
import paramiko
import yaml
from tabulate import tabulate

servers = yaml.safe_load((Path(__file__).resolve().parent.parent / "configs" / "servers.yaml").read_text())["servers"]
rows = []
for s in servers:
    ssh = paramiko.SSHClient()
    ssh.load_system_host_keys()
    try:
        ssh.connect(s["host"], port=s["port"], username=s["user"], timeout=5)
        _, out, _ = ssh.exec_command("df -h / | tail -1")
        size, used, avail, pct = out.read().decode().split()[1:5]
        rows.append([s["host"], s["role"], size, used, pct])
    except Exception as e:
        rows.append([s["host"], s["role"], "-", "-", type(e).__name__])
    finally:
        ssh.close()
print(tabulate(rows, headers=["Host", "Role", "Size", "Used", "Use%"], tablefmt="github"))
