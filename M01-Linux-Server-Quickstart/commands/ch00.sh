#!/usr/bin/env bash
# ก่อนเริ่ม: วิธีใช้หนังสือและสิ่งที่ต้องเตรียม
# SysAdmin Pocket Series M01 Linux Server Quickstart ฉบับปรับปรุง (Rocky Linux 10.2)
#
# ไฟล์นี้รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# คำสั่งที่ไม่มีป้ายรันบน server ส่วนบรรทัดที่มีป้าย [Host PC] รันใน PowerShell บน Windows
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── รูปแบบที่ใช้ในเล่ม ──────────────────────────────────────────
hostname
whoami

# [Host PC] hostname
# [Host PC] whoami


# ── ไฟล์ประกอบหนังสือ ───────────────────────────────────────────
# [Host PC] git clone https://github.com/arnutkmitl/sysadmin-series.git
# [Host PC] Get-ChildItem -Name sysadmin-series\M01-Linux-Server-Quickstart
# [Host PC] Get-ChildItem -Name sysadmin-series\M01-Linux-Server-Quickstart\commands

# [Host PC] cd sysadmin-series
# [Host PC] git pull


# ── Hardware ขั้นต่ำ ────────────────────────────────────────────
# [Host PC] (Get-CimInstance Win32_Processor).Name

# [Host PC] (Get-CimInstance Win32_Processor).Name

# [Host PC] systeminfo | Select-String "Total Physical Memory","Hyper-V Requirements","Virtualization Enabled"

# [Host PC] systeminfo | Select-String "Total Physical Memory","Hyper-V Requirements","Virtualization Enabled"


# ── ดาวน์โหลดไฟล์ ISO และตรวจ checksum ──────────────────────────
# [Host PC] cd $env:USERPROFILE\Downloads
# [Host PC] Get-FileHash .\Rocky-10.2-x86_64-minimal.iso -Algorithm SHA256
# [Host PC] Get-Content .\CHECKSUM | Select-String -SimpleMatch "SHA256 (Rocky-10.2-x86_64-minimal.iso)"

# [Host PC] certutil -hashfile "$env:USERPROFILE\Downloads\Rocky-10.2-x86_64-minimal.iso" SHA256

sha256sum -c CHECKSUM --ignore-missing


# ── เตรียม USB Boot ─────────────────────────────────────────────
# ⚠️ การเขียน ISO ลง USB จะลบข้อมูลทั้งหมดในไดรฟ์นั้น ถ้าเลือกไดรฟ์ผิด ข้อมูลในดิสก์นั้นจะหายและกู้คืนไม่ได้ ตรวจชื่อและขนาดไดรฟ์ทุกครั้ง และสำรองข้อมูลสำคัญก่อน
lsblk -d -o NAME,SIZE,MODEL,TRAN

sudo dd if=Rocky-10.2-x86_64-minimal.iso of=/dev/sdb bs=4M status=progress oflag=direct
sync


# ── เวลาและเครื่องมือที่ต้องมี ──────────────────────────────────
# [Host PC] ssh -V


# ── ติดตั้ง VirtualBox และตรวจวง Host-Only ──────────────────────
# [Host PC] $env:Path += ";C:\Program Files\Oracle\VirtualBox"
# [Host PC] VBoxManage --version

# [Host PC] VBoxManage list hostonlyifs

# [Host PC] VBoxManage list dhcpservers

# [Host PC] VBoxManage hostonlyif create
# [Host PC] VBoxManage hostonlyif ipconfig "VirtualBox Host-Only Ethernet Adapter" --ip 192.168.56.1 --netmask 255.255.255.0


# ── สร้าง VM ด้วย VBoxManage ────────────────────────────────────
# [Host PC] VBoxManage createvm --name server --ostype RedHat_64 --register

# [Host PC] VBoxManage modifyvm server --memory 2048 --cpus 2 --ioapic on --firmware efi --graphicscontroller vmsvga --vram 16 --nic1 nat --nic2 hostonly --hostonlyadapter2 "VirtualBox Host-Only Ethernet Adapter"

# [Host PC] VBoxManage createmedium disk --filename "$env:USERPROFILE\VirtualBox VMs\server\server.vdi" --size 20480
# [Host PC] VBoxManage storagectl server --name SATA --add sata --controller IntelAhci
# [Host PC] VBoxManage storageattach server --storagectl SATA --port 0 --device 0 --type hdd --medium "$env:USERPROFILE\VirtualBox VMs\server\server.vdi"
# [Host PC] VBoxManage storageattach server --storagectl SATA --port 1 --device 0 --type dvddrive --medium "$env:USERPROFILE\Downloads\Rocky-10.2-x86_64-minimal.iso"

# [Host PC] VBoxManage showvminfo server --machinereadable | findstr /b "nic1= nic2= hostonlyadapter2="
# [Host PC] VBoxManage showvminfo server --machinereadable | findstr /b "memory= cpus= firmware= graphicscontroller= vram="

# [Host PC] VBoxManage list bridgedifs | findstr /b "Name:"
# [Host PC] VBoxManage createvm --name web-test --ostype RedHat_64 --register
# [Host PC] VBoxManage modifyvm web-test --memory 4096 --cpus 2 --ioapic on --firmware efi --graphicscontroller vmsvga --vram 16 --nic1 bridged --bridgeadapter1 "Intel(R) Ethernet Connection (17) I219-LM"


# ── ทดสอบการเชื่อมต่อของ Lab ────────────────────────────────────
ip -br addr

ip route

ping -c 2 rockylinux.org

# [Host PC] ping -n 2 192.168.56.10

# [Host PC] ssh admin@192.168.56.10


# [Host PC] ssh -p 2222 admin@192.168.56.10
# [Host PC] ssh server


# ── ถ่าย Snapshot ───────────────────────────────────────────────
# [Host PC] VBoxManage controlvm server acpipowerbutton
# [Host PC] VBoxManage showvminfo server --machinereadable | findstr VMState=
# [Host PC] VBoxManage snapshot server take "base-10.2" --description "Rocky 10.2 installed + dnf update"

# [Host PC] VBoxManage snapshot server take "ch04-start"
# [Host PC] VBoxManage snapshot server list

# ⚠️ การย้อน snapshot ลบทุกอย่างที่ทำหลังจากจุดนั้น ทั้งไฟล์และค่าที่ตั้งไว้ และย้อนคืนไม่ได้ ถ้ามีไฟล์ที่ต้องการเก็บ ให้คัดลอกออกจาก VM ก่อน ส่วน `poweroff` ตัดไฟทันทีเหมือนดึงปลั๊ก ข้อมูลที่ยังไม่เขียนลงดิสก์จะหาย
# [Host PC] VBoxManage controlvm server poweroff
# [Host PC] VBoxManage snapshot server restore "ch04-start"

# [Host PC] VBoxManage clonevm server --snapshot base-10.2 --name client --options link --register


# ── เมื่อ Rocky Linux 10 บูตไม่ขึ้น ─────────────────────────────
# [Host PC] bcdedit /enum "{current}" | Select-String hypervisorlaunchtype

# ⚠️ คำสั่งนี้แก้ค่าการบูตของ Windows หลังปิดแล้ว WSL2 และ Docker Desktop จะใช้งานไม่ได้จนกว่าจะเปิดกลับด้วย `bcdedit /set hypervisorlaunchtype auto` แล้วรีบูต ถ้าเครื่องเป็นของหน่วยงาน ให้ขออนุญาตฝ่าย IT ก่อน เพราะนโยบายความปลอดภัยบางแห่งบังคับเปิด Hyper-V
# [Host PC] bcdedit /set hypervisorlaunchtype off
# [Host PC] bcdedit /set hypervisorlaunchtype auto

/lib64/ld-linux-x86-64.so.2 --help | grep -A3 "glibc-hwcaps"

/lib64/ld-linux-x86-64.so.2 --help | grep -A3 "glibc-hwcaps"


# ── รุ่นซอฟต์แวร์ที่ใช้ทดสอบ ────────────────────────────────────
cat /etc/rocky-release
rpm -q kernel openssh-server firewalld dnf


# ── กล่อง Ubuntu ────────────────────────────────────────────────
# [Host PC] Get-FileHash "$env:USERPROFILE\Downloads\ubuntu-26.04.1-live-server-amd64.iso" -Algorithm SHA256

# [Ubuntu]
sha256sum -c SHA256SUMS --ignore-missing

# [Host PC] VBoxManage createvm --name ubuntu --ostype Ubuntu_64 --register
# [Host PC] VBoxManage modifyvm ubuntu --memory 2048 --cpus 2 --ioapic on --firmware efi --graphicscontroller vmsvga --vram 16 --nic1 nat --nic2 hostonly --hostonlyadapter2 "VirtualBox Host-Only Ethernet Adapter"
# [Host PC] VBoxManage createmedium disk --filename "$env:USERPROFILE\VirtualBox VMs\ubuntu\ubuntu.vdi" --size 20480
# [Host PC] VBoxManage storagectl ubuntu --name SATA --add sata --controller IntelAhci
# [Host PC] VBoxManage storageattach ubuntu --storagectl SATA --port 0 --device 0 --type hdd --medium "$env:USERPROFILE\VirtualBox VMs\ubuntu\ubuntu.vdi"
# [Host PC] VBoxManage storageattach ubuntu --storagectl SATA --port 1 --device 0 --type dvddrive --medium "$env:USERPROFILE\Downloads\ubuntu-26.04.1-live-server-amd64.iso"

# [Ubuntu]
grep PRETTY_NAME /etc/os-release
# [Ubuntu]
ip -br addr

# [Host PC] VBoxManage controlvm ubuntu acpipowerbutton
# [Host PC] VBoxManage showvminfo ubuntu --machinereadable | findstr VMState=
# [Host PC] VBoxManage snapshot ubuntu take "base-26.04" --description "Ubuntu 26.04.1 installed + apt full-upgrade"
