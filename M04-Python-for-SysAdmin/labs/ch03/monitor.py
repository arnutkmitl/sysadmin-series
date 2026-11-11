#!/usr/bin/env python3
# monitor.py แสดงสถานะเครื่องบน terminal วาดใหม่ทุก 5 วินาที กด Ctrl+C เพื่อออก
import time
import psutil

def color(pct):
    code = "31" if pct >= 90 else "33" if pct >= 70 else "32"
    return f"\033[0;{code}m{pct:5.1f}%\033[0m"

def top_cpu(n=5):
    procs = list(psutil.process_iter(["pid", "name"]))
    for p in procs:
        p.cpu_percent(None)                  # เริ่มจับเวลาของแต่ละ process
    time.sleep(1)
    rows = []
    for p in procs:
        try:
            rows.append((p.cpu_percent(None), p.info["pid"], p.info["name"]))
        except psutil.NoSuchProcess:
            pass                             # process จบไประหว่างวัด
    return sorted(rows, reverse=True)[:n]

try:
    while True:
        cpu = psutil.cpu_percent(interval=None)
        rows = top_cpu()
        print("\033[2J\033[H", end="")       # ล้างจอและกลับมุมซ้ายบน
        print(f"CPU  {color(cpu)}")
        print(f"RAM  {color(psutil.virtual_memory().percent)}")
        print(f"Disk {color(psutil.disk_usage('/').percent)}")
        print("\n  CPU%    PID  NAME")
        for pct, pid, name in rows:
            print(f"{pct:6.1f} {pid:>6}  {name}")
        time.sleep(4)
except KeyboardInterrupt:
    print("\nออกจาก monitor")
