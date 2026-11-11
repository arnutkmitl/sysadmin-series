#!/usr/bin/env bash
# รันคำสั่งและจัดการ Process: subprocess และ psutil
# SysAdmin Pocket Series M04 Python for SysAdmin
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 3.1 subprocess รันคำสั่งจาก Python ──────────────────────
# ⚠️ อย่าใช้ shell=True กับข้อความที่มีค่าจากภายนอก Python จะส่งข้อความทั้งก้อนให้ shell ตีความ ถ้าชื่อ service มาจากไฟล์ค่าตั้งหรือจากผู้ใช้ ค่าอย่าง "nginx; rm -rf ~" จะถูกรันเป็นสองคำสั่ง ส่งคำสั่งเป็น list เสมอ shell จะไม่ถูกเรียกเลย

# ── 3.4 จัดการ process ──────────────────────────────────────
# ⚠️ terminate กับ kill ต่างกัน terminate ส่ง SIGTERM ให้โปรแกรมปิดไฟล์และบันทึกงานก่อนจบ kill ส่ง SIGKILL ให้ kernel หยุดทันที ฐานข้อมูลที่ถูก kill กลางการเขียนอาจต้องซ่อมไฟล์ตอนเปิดใหม่ ใช้ terminate ก่อนเสมอ แล้ว kill เฉพาะตัวที่ยังเหลือใน alive หลังรอแล้ว

# ── Lab 3.2 Service Watchdog ────────────────────────────────
sudo systemctl stop chronyd
sudo ~/python-admin/.venv/bin/python ~/python-admin/labs/watchdog.py
tail -3 ~/python-admin/logs/watchdog.log
