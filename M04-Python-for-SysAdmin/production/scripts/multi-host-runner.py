#!/usr/bin/env python3
# multi-host-runner.py รันคำสั่งเดียวกันบนทุกเครื่องใน servers.yaml พร้อมกัน แล้วสรุปเป็นตาราง
# ใช้: ./multi-host-runner.py "df -h /" [--config servers.yaml] [--workers 5]
import argparse
from concurrent.futures import ThreadPoolExecutor
import paramiko
from tabulate import tabulate
from adminlib import get_logger, load_config

parser = argparse.ArgumentParser(description="รันคำสั่งบนหลายเครื่องผ่าน SSH")
parser.add_argument("command")
parser.add_argument("--config", default="servers.yaml")
parser.add_argument("--workers", type=int, default=5)
args = parser.parse_args()
log = get_logger("multi-host-runner")

def run(server):
    ssh = paramiko.SSHClient()
    ssh.load_system_host_keys()                    # ยืนยัน host key จาก known_hosts
    try:
        ssh.connect(server["host"], port=server.get("port", 22), username=server["user"], timeout=5)
        _, out, err = ssh.exec_command(args.command, timeout=60)
        text = (out.read() + err.read()).decode().strip()
        return [server["host"], out.channel.recv_exit_status(), text]
    except Exception as e:
        return [server["host"], "-", f"{type(e).__name__}: {e}"]
    finally:
        ssh.close()

servers = load_config(args.config)["servers"]
with ThreadPoolExecutor(max_workers=args.workers) as pool:
    rows = list(pool.map(run, servers))
for host, rc, _ in rows:
    log.info("%s rc=%s cmd=%s", host, rc, args.command)
print(tabulate(rows, headers=["Host", "Exit", "Output"], tablefmt="simple"))
