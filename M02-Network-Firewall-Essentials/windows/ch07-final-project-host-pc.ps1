# โปรเจกต์จบเล่ม: Secure Network สำหรับ Web Server
# SysAdmin Pocket Series M02 Network & Firewall Essentials
#
# คำสั่งสำหรับ Host PC (Windows) รันใน PowerShell หรือ Command Prompt ทีละคำสั่ง ห้ามรันทั้งไฟล์
# ถ้า VBoxManage ไม่อยู่ใน PATH ให้ใช้ "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
Write-Host "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง"
return

# ── ตรวจผลจากภายนอก ─────────────────────────────────────────────
Test-NetConnection 192.168.57.10 -Port 2222
