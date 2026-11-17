#!/usr/bin/env bash
# ก่อนเริ่ม: วิธีใช้หนังสือและเตรียม Lab Ansible
# SysAdmin Pocket Series M15 Ansible Automation
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── สร้าง VM และตั้งชื่อเครื่อง ─────────────────────────────
# PowerShell บนเครื่อง Windows
VBoxManage clonevm server --snapshot base-10.2 --options link --name ctl --register
VBoxManage clonevm server --snapshot base-10.2 --options link --name web --register
VBoxManage clonevm server --snapshot base-10.2 --options link --name app --register
VBoxManage clonevm server --snapshot base-10.2 --options link --name db --register
VBoxManage discardstate ctl
VBoxManage modifyvm ctl --memory 2048 --cpus 2
VBoxManage startvm ctl --type headless
# บนเครื่อง ctl
sudo hostnamectl set-hostname ctl.lab.local
sudo nmcli con mod enp0s8 ipv4.addresses 192.168.56.65/24
sudo nmcli con up enp0s8
# PowerShell บนเครื่อง Windows
ssh -p 2222 admin@192.168.56.65
# บนเครื่อง ctl
hostname; ip -4 -br a show enp0s8
python3 -V

# ── SSH key จาก ctl ไปทุกเครื่อง ────────────────────────────
# บนเครื่อง ctl
ssh-keygen -t ed25519 -C admin@ctl
for h in 192.168.56.66 192.168.56.67 192.168.56.68 192.168.56.82; do ssh-copy-id -p 2222 admin@$h; done

# ── ผู้ใช้ ansible บนทุกเครื่อง ─────────────────────────────
# ⚠️ ผู้ใช้ที่มี `NOPASSWD: ALL` เทียบเท่า root ใครได้ private key ของ ctl ไปก็เป็น root ได้ทุกเครื่อง เก็บ ~/.ssh/id_ed25519 บน ctl ให้ดี และอย่าคัดลอกไปเครื่องอื่น
# บนเครื่อง ctl
chmod +x bootstrap-ansible-user.sh
./bootstrap-ansible-user.sh
for h in 66 67 68 82; do ssh -p 2222 ansible@192.168.56.$h "hostname; sudo -n whoami"; done
