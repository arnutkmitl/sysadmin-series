# Python Script แรก: ลาก่อน echo สวัสดี print()
# SysAdmin Pocket Series M04 Python for SysAdmin
# ตัวอย่างที่พิมพ์ใน Python interactive (>>>) ตามลำดับในเล่ม ตัด prompt และผลลัพธ์ออกแล้ว
# ให้คัดลอกทีละส่วนไปลองใน python3 หรือ .venv/bin/python ไม่ใช่สคริปต์ที่รันทั้งไฟล์

# ── 1.4 Syntax ที่ต้องรู้
host = "web01"
usage = 87
print(f"{host} ดิสก์ใช้ไป {usage}%")
services = ["sshd", "crond", "chronyd"]
server = {"host": "web01", "port": 2222}
print(services[0], server["port"], len(services))
