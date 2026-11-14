#!/usr/bin/env bash
# บทที่ 1 ติดตั้ง Proxmox VE และเตรียมเครื่อง
# SysAdmin Pocket Series M11 Proxmox VE: สร้าง Virtual Lab ใน 1 วัน
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# บรรทัดที่มี [PowerShell] รันใน PowerShell ของ Windows, [Git Bash] รันใน Git Bash, ที่เหลือรันบน pve ในนาม root
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 1.1 ติดตั้งจาก ISO ──────────────────────────────────────
# [PowerShell]
VBoxManage storageattach pve --storagectl SATA --port 1 --device 0 --type dvddrive --medium emptydrive
# [PowerShell]
ssh root@192.168.56.60
pveversion

# ── 1.2 ให้ pve ออก Internet ใน VirtualBox ──────────────────
cat /etc/network/interfaces
cp /etc/network/interfaces /root/interfaces.orig
sed -i -e '/gateway 192.168.56.1/d' -e 's/^iface nic0 inet manual/auto nic0\niface nic0 inet dhcp/' /etc/network/interfaces
ifreload -a
ip -br a
ip r
ping -c2 deb.debian.org | tail -1

# ── 1.3 เปลี่ยน repository เป็น no-subscription ─────────────
ls /etc/apt/sources.list.d/
cat /etc/apt/sources.list.d/pve-enterprise.sources
apt-get update 2>&1 | tail -4
echo "Enabled: false" >> /etc/apt/sources.list.d/pve-enterprise.sources
echo "Enabled: false" >> /etc/apt/sources.list.d/ceph.sources
cat > /etc/apt/sources.list.d/proxmox.sources <<'EOF'
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
apt-get update 2>&1 | tail -3
apt full-upgrade -y
reboot
pveversion

# ── 1.4 storage และ ISO ─────────────────────────────────────
pvesm status
cat /etc/pve/storage.cfg
lvs
pvesh create /nodes/pve/storage/local/download-url --content iso \
    --filename Rocky-10.2-x86_64-minimal.iso \
    --url https://download.rockylinux.org/pub/rocky/10/isos/x86_64/Rocky-10.2-x86_64-minimal.iso \
    --checksum aac6ac3ce781b91a91ce78463405f66c611a5dca4b3840c79e5e01d97302f6c8 --checksum-algorithm sha256
pvesm list local --content iso

# ── 1.5 สร้างวง Lab ภายใน vmbr1 ─────────────────────────────
pvesh create /nodes/pve/network --iface vmbr1 --type bridge --cidr 10.10.10.1/24 \
    --autostart 1 --comments "Lab internal 10.10.10.0/24"
pvesh set /nodes/pve/network
ip -br a show vmbr1
cat /proc/sys/net/ipv4/ip_forward
iptables -t nat -S POSTROUTING

# ── VLAN บน bridge ──────────────────────────────────────────
pvesh set /nodes/pve/network/vmbr1 --type bridge --cidr 10.10.10.1/24 --autostart 1 \
    --bridge_vlan_aware 1 --comments "Lab internal 10.10.10.0/24"
pvesh set /nodes/pve/network
bridge vlan show dev vmbr1
