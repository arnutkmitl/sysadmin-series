#!/usr/bin/env python3
# sysinfo2.py ข้อมูลเครื่องด้วย psutil พร้อมสีตามเกณฑ์
import platform
import socket
from datetime import datetime
import psutil

GREEN, RED, NC = "\033[0;32m", "\033[0;31m", "\033[0m"
LIMIT = 80

def color(pct):
    return f"{RED if pct >= LIMIT else GREEN}{pct:.0f}%{NC}"

mem = psutil.virtual_memory()
disk = psutil.disk_usage("/")
print(f"Host : {socket.gethostname()} ({platform.freedesktop_os_release()['PRETTY_NAME']})")
print(f"RAM  : {color(mem.percent)} ของ {mem.total // 2**20} MB")
print(f"Disk : {color(disk.percent)} ของ {disk.total // 2**30} GB")
print(f"Boot : {datetime.fromtimestamp(psutil.boot_time()):%Y-%m-%d %H:%M}")
