#!/usr/bin/env bash
# ก่อนเริ่ม: วิธีใช้หนังสือและเตรียมเครื่อง
# SysAdmin Pocket Series M11 Proxmox VE: สร้าง Virtual Lab ใน 1 วัน
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# บรรทัดที่มี [PowerShell] รันใน PowerShell ของ Windows, [Git Bash] รันใน Git Bash, ที่เหลือรันบน pve ในนาม root
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── ตรวจ nested virtualization ก่อนลงมือ ────────────────────
# [PowerShell]
Select-String -Path "$HOME\VirtualBox VMs\M02-Lab\pve\Logs\VBox.log" -Pattern "fall back to NEM"
# [PowerShell]
VBoxManage showvminfo pve | Select-String "Nested VT-x"
grep -cE 'vmx|svm' /proc/cpuinfo
ls -l /dev/kvm

# ── สร้าง VM pve ใน VirtualBox ──────────────────────────────
# [PowerShell]
$env:Path += ";C:\Program Files\Oracle\VirtualBox"
# [PowerShell]
VBoxManage createvm --name pve --ostype Debian_64 --groups /M02-Lab --register
# [PowerShell]
VBoxManage modifyvm pve --memory 10240 --cpus 4 --firmware efi --graphicscontroller vmsvga --vram 16 `
      --nested-hw-virt on --nic1 nat --nic2 hostonly --hostonlyadapter2 "VirtualBox Host-Only Ethernet Adapter" `
      --nicpromisc2 allow-all --audio-enabled off
# [PowerShell]
$d = "$HOME\VirtualBox VMs\M02-Lab\pve"
# [PowerShell]
VBoxManage createmedium disk --filename "$d\pve.vdi" --size 102400 --format VDI
# [PowerShell]
VBoxManage storagectl pve --name SATA --add sata --controller IntelAhci --portcount 2
# [PowerShell]
VBoxManage storageattach pve --storagectl SATA --port 0 --device 0 --type hdd --medium "$d\pve.vdi" --nonrotational on
# [PowerShell]
VBoxManage storageattach pve --storagectl SATA --port 1 --device 0 --type dvddrive --medium "$HOME\Downloads\proxmox-ve_9.2-1.iso"
# [PowerShell]
(Get-FileHash "$HOME\Downloads\proxmox-ve_9.2-1.iso").Hash
