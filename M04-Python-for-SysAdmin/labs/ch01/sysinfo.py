#!/usr/bin/env python3
# sysinfo.py ข้อมูลเครื่องแปดรายการ ใช้เฉพาะโมดูลในตัวของ Python
import os
import platform
import shutil
import socket

def ram_mb():
    with open("/proc/meminfo") as f:
        for line in f:
            if line.startswith("MemTotal:"):
                return int(line.split()[1]) // 1024   # ค่าในไฟล์เป็น kB

def main_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.connect(("1.1.1.1", 53))       # UDP ไม่ส่งข้อมูลจริง แค่ให้ระบบเลือกการ์ด
    ip = s.getsockname()[0]
    s.close()
    return ip

with open("/proc/uptime") as f:
    hours = float(f.read().split()[0]) / 3600
disk = shutil.disk_usage("/")

print(f"Host   : {socket.gethostname()}")
print(f"OS     : {platform.freedesktop_os_release()['PRETTY_NAME']}")
print(f"Kernel : {platform.release()}")
print(f"CPU    : {os.cpu_count()} core")
print(f"RAM    : {ram_mb()} MB")
print(f"Disk / : ใช้ {disk.used / disk.total:.0%} จาก {disk.total // 2**30} GB")
print(f"IP     : {main_ip()}")
print(f"Uptime : {hours:.1f} ชั่วโมง")
