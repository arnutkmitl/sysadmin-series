#!/usr/bin/env bash
# ก่อนเริ่ม: วิธีใช้หนังสือและเตรียม Lab
# SysAdmin Pocket Series M17 Backup & Disaster Recovery
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── สร้าง VM สองเครื่อง ─────────────────────────────────────
# PowerShell บนเครื่อง Windows
VBoxManage clonevm server --snapshot base-10.2 --options link --name m17prod --register
VBoxManage discardstate m17prod
VBoxManage modifyvm m17prod --memory 2048 --cpus 2
VBoxManage modifyvm m17prod --natpf1 delete ssh
VBoxManage modifyvm m17prod --natpf1 "ssh,tcp,127.0.0.1,52285,,2222"
VBoxManage startvm m17prod --type headless
VBoxManage controlvm m17prod screenshotpng prod.png
VBoxManage controlvm m17prod reset
ssh -p 52285 admin@127.0.0.1
# บนเครื่อง prod
sudo hostnamectl set-hostname prod.lab.local
sudo nmcli con mod enp0s8 ipv4.addresses 192.168.56.85/24
sudo nmcli con up enp0s8
# บนเครื่อง Host
for ip in 85 86; do ssh -p 2222 admin@192.168.56.$ip hostname; done

# ── ระบบที่ต้องปกป้องบน prod ────────────────────────────────
# บนเครื่อง prod
sudo bash seed-prod.sh
sudo mariadb -e "SHOW VARIABLES LIKE 'character_set_server'; SELECT name FROM shop.products LIMIT 1"

# ── เตรียม bkp ──────────────────────────────────────────────
# บนเครื่อง bkp
sudo bash setup-bkp.sh
