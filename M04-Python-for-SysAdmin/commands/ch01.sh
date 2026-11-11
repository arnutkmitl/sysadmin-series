#!/usr/bin/env bash
# Python Script แรก: ลาก่อน echo สวัสดี print()
# SysAdmin Pocket Series M04 Python for SysAdmin
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 1.1 Python Script กับ Bash Script ───────────────────────
echo "Hello $(hostname)"
python3 -c 'import socket; print(f"Hello {socket.gethostname()}")'

# ── 1.2 สร้าง Python Script ตัวแรก ──────────────────────────
cd ~/python-admin/scripts
nano hello-admin.py
chmod +x hello-admin.py
./hello-admin.py
python3 hello-admin.py

# ── 1.3 Script ที่สอง: System Info ──────────────────────────
./sysinfo.py

# ── 1.4 Syntax ที่ต้องรู้ ───────────────────────────────────
# ⚠️ อย่าใช้ Tab ปนกับเว้นวรรคในการเยื้อง Python 3 จะหยุดด้วย TabError ทันที ตั้ง editor ให้แทน Tab ด้วยเว้นวรรค 4 ตัว ใน nano ใช้ nano -E หรือเพิ่ม set tabstospaces ในไฟล์ ~/.nanorc

# ── 1.5 import โมดูล ────────────────────────────────────────
deactivate
python3 -c "import psutil"
source ~/python-admin/.venv/bin/activate
python3 -c "import psutil; print(psutil.cpu_count())"
