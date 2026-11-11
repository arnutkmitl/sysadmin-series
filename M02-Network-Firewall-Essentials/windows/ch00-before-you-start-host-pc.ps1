# ก่อนเริ่ม: วิธีใช้หนังสือและเตรียม Lab
# SysAdmin Pocket Series M02 Network & Firewall Essentials
#
# คำสั่งสำหรับ Host PC (Windows) รันใน PowerShell หรือ Command Prompt ทีละคำสั่ง ห้ามรันทั้งไฟล์
# ถ้า VBoxManage ไม่อยู่ใน PATH ให้ใช้ "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
Write-Host "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง"
return

# ── สร้างวง Host-Only และตั้ง Adapter ───────────────────────────
VBoxManage modifyvm server --nic1 nat
VBoxManage modifyvm server --nic2 hostonly --hostonlyadapter2 "VirtualBox Host-Only Ethernet Adapter"
VBoxManage list hostonlyifs


# ── ถ่าย Snapshot ก่อนเริ่มทุกบท ────────────────────────────────
VBoxManage snapshot server take "ch03-start"
VBoxManage snapshot client take "lab6-start"
VBoxManage snapshot server list

# ⚠️ การย้อน snapshot จะลบทุกอย่างที่ทำหลังจากจุดนั้น ทั้งไฟล์และค่าที่ตั้งไว้ ต้องปิด VM ก่อนย้อน
VBoxManage controlvm server poweroff
VBoxManage snapshot server restore "ch03-start"


# ── เมื่อ VM ช้าผิดปกติหรือ Rocky Linux 10 บูตไม่ขึ้น ───────────
# ⚠️ คำสั่งนี้แก้ค่าการบูตของ Windows หลังปิด WSL2 และ Docker Desktop จะใช้งานไม่ได้จนกว่าจะเปิดกลับด้วย `bcdedit /set hypervisorlaunchtype auto` แล้วรีบูต
bcdedit /set hypervisorlaunchtype off
