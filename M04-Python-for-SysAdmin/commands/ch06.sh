#!/usr/bin/env bash
# 5 Ready-Made Scripts: คัดลอกไปใช้ได้เลย
# SysAdmin Pocket Series M04 Python for SysAdmin
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 6.1 ส่วนกลาง adminlib.py ────────────────────────────────
pip install ruff
ruff check ~/python-admin/scripts

# ── 6.2 Script #1 server-monitor.py (ระดับกลาง) ─────────────
./server-monitor.py
sed -i 's/  disk: 85/  disk: 10/' ../configs/monitor-config.yaml
./server-monitor.py
tail -1 ../logs/admin-toolkit.log

# ── 6.3 Script #2 multi-host-runner.py (ระดับยาก) ───────────
# ⚠️ multi-host-runner รันคำสั่งที่พิมพ์บนทุกเครื่องในรายการทันทีโดยไม่ถามยืนยัน คำสั่งที่ลบหรือหยุดบริการจะกระทบทุกเครื่องพร้อมกัน ทดลองคำสั่งกับเครื่องเดียวด้วย --config ที่มีเครื่องเดียวก่อนทุกครั้ง
./multi-host-runner.py "df -h / | tail -1"
./multi-host-runner.py "uname -r" --workers 10

# ── 6.4 Script #3 log-analyzer.py (ระดับกลาง) ───────────────
sudo ~/python-admin/.venv/bin/python log-analyzer.py

# ── 6.5 Script #4 api-health-check.py (ระดับกลาง) ───────────
./api-health-check.py
cat ../logs/state.json

# ── 6.6 Script #5 user-report.py (ระดับกลาง) ────────────────
sudo ~/python-admin/.venv/bin/python user-report.py
