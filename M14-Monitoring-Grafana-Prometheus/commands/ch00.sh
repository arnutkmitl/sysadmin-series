#!/usr/bin/env bash
# ก่อนเริ่ม: วิธีใช้หนังสือและเตรียม Lab Monitoring
# SysAdmin Pocket Series M14 Monitoring with Grafana & Prometheus
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── สร้าง VM และตั้งชื่อเครื่อง ─────────────────────────────
# PowerShell บนเครื่อง Windows
VBoxManage clonevm server --snapshot base-10.2 --options link --name mon --register
VBoxManage clonevm server --snapshot base-10.2 --options link --name app --register
VBoxManage modifyvm mon --cpus 2 --memory 4096
VBoxManage startvm mon --type headless
# บนเครื่อง mon
sudo hostnamectl set-hostname mon.lab.local
sudo nmcli con mod enp0s8 ipv4.addresses 192.168.56.55/24
sudo nmcli con up enp0s8
# PowerShell บนเครื่อง Windows
ssh -p 2222 admin@192.168.56.55
# บนเครื่อง mon
hostnamectl | head -1
grep PRETTY /etc/os-release

# ── ติดตั้ง Docker บน mon ───────────────────────────────────
# บนเครื่อง mon
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker admin
id
docker version --format '{{.Server.Version}}'
docker compose version
