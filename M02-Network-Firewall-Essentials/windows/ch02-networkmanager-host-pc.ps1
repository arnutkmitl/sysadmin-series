# บทที่ 2 ตั้งค่า Network ด้วย NetworkManager
# SysAdmin Pocket Series M02 Network & Firewall Essentials
#
# คำสั่งสำหรับ Host PC (Windows) รันใน PowerShell หรือ Command Prompt ทีละคำสั่ง ห้ามรันทั้งไฟล์
# ถ้า VBoxManage ไม่อยู่ใน PATH ให้ใช้ "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
Write-Host "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง"
return

# ── Lab 2.2 ตั้ง Dual NIC แยก Management กับ Service ────────────
VBoxManage modifyvm server --nic3 hostonly --hostonlyadapter3 "VirtualBox Host-Only Ethernet Adapter #2"
VBoxManage modifyvm client --nic3 hostonly --hostonlyadapter3 "VirtualBox Host-Only Ethernet Adapter #2"
