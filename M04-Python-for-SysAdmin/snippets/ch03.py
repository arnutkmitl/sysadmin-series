# รันคำสั่งและจัดการ Process: subprocess และ psutil
# SysAdmin Pocket Series M04 Python for SysAdmin
# ตัวอย่างที่พิมพ์ใน Python interactive (>>>) ตามลำดับในเล่ม ตัด prompt และผลลัพธ์ออกแล้ว
# ให้คัดลอกทีละส่วนไปลองใน python3 หรือ .venv/bin/python ไม่ใช่สคริปต์ที่รันทั้งไฟล์

# ── 3.1 subprocess รันคำสั่งจาก Python
import subprocess
r = subprocess.run(["systemctl", "is-active", "sshd"], capture_output=True, text=True)
r.returncode, r.stdout.strip()
r = subprocess.run(["systemctl", "is-active", "nginx"], capture_output=True, text=True)
r.returncode, r.stdout.strip()

# ── 3.1 subprocess รันคำสั่งจาก Python
try:
    subprocess.run(["dnf", "-q", "check-update"], check=True, timeout=60)
except subprocess.CalledProcessError as e:
    print(f"มีแพ็กเกจรออัปเดต (exit code {e.returncode})")
except subprocess.TimeoutExpired:
    print("dnf ไม่ตอบภายใน 60 วินาที")

# ── 3.1 subprocess รันคำสั่งจาก Python
svc = "nginx; echo HACKED"
subprocess.run(f"systemctl is-active {svc}", shell=True)
subprocess.run(["systemctl", "is-active", svc]).returncode

# ── 3.2 psutil อ่านสถานะเครื่อง
import psutil
psutil.cpu_percent(interval=1), psutil.cpu_count(), psutil.getloadavg()
mem = psutil.virtual_memory()
print(f"RAM {mem.used // 2**20} MB / {mem.total // 2**20} MB ({mem.percent}%)")
for part in psutil.disk_partitions():
    print(part.mountpoint, f"{psutil.disk_usage(part.mountpoint).percent}%")

net = psutil.net_io_counters(pernic=True)["enp0s8"]
print(f"enp0s8 ส่ง {net.bytes_sent // 2**10} KB รับ {net.bytes_recv // 2**10} KB")

# ── 3.2 psutil อ่านสถานะเครื่อง
procs = psutil.process_iter(["pid", "name", "memory_percent"])
top = sorted(procs, key=lambda p: p.info["memory_percent"] or 0, reverse=True)[:5]
for p in top:
    print(f"{p.info['pid']:>6} {p.info['name']:<16} {p.info['memory_percent']:.1f}%")

# ── 3.4 จัดการ process
hogs = [p for p in psutil.process_iter(["name"]) if p.info["name"] == "sleep"]
for p in hogs:
    p.terminate()

gone, alive = psutil.wait_procs(hogs, timeout=5)
len(gone), len(alive)
