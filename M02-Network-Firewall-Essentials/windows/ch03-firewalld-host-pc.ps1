# บทที่ 3 Firewall ขั้นกลาง: firewalld Zone และ Rich Rules
# SysAdmin Pocket Series M02 Network & Firewall Essentials
#
# คำสั่งสำหรับ Host PC (Windows) รันใน PowerShell หรือ Command Prompt ทีละคำสั่ง ห้ามรันทั้งไฟล์
# ถ้า VBoxManage ไม่อยู่ใน PATH ให้ใช้ "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
Write-Host "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง"
return

# ── Lab 3.1 ตั้ง Firewall สำหรับ Multi-Zone Server ──────────────
Test-NetConnection 192.168.57.10 -Port 2222
