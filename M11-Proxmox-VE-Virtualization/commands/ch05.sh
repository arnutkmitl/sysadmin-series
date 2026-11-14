#!/usr/bin/env bash
# โปรเจกต์จบเล่ม: Lab วิชา Linux Administration
# SysAdmin Pocket Series M11 Proxmox VE: สร้าง Virtual Lab ใน 1 วัน
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# บรรทัดที่มี [PowerShell] รันใน PowerShell ของ Windows, [Git Bash] รันใน Git Bash, ที่เหลือรันบน pve ในนาม root
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 5.2 container สำหรับ DNS ของ Lab ────────────────────────
pct create 250 local:vztmpl/rockylinux-10-default_20251001_amd64.tar.xz --hostname infra \
    --unprivileged 1 --features nesting=1 --memory 256 --swap 256 --rootfs local-lvm:4 \
    --net0 name=eth0,bridge=vmbr1,ip=10.10.10.2/24,gw=10.10.10.1 --nameserver 1.1.1.1 \
    --onboot 1 --start 1
pct exec 250 -- dnf install -y dnsmasq
pct push 250 /root/lab-hosts.conf /etc/dnsmasq.d/lab.conf
pct exec 250 -- systemctl enable --now dnsmasq
dig +short @10.10.10.2 stu07.lab.test
dig +short @10.10.10.2 rockylinux.org | head -1

# ── 5.3 สร้าง Lab ด้วย build-lab.sh ─────────────────────────
build-lab.sh linux101 9000 10 401 111
ls -l /root/linux101-accounts.csv
cut -d, -f1-3 /root/linux101-accounts.csv | head -3

# ── 5.4 ตรวจ Lab ด้วย check-lab.sh ──────────────────────────
check-lab.sh linux101
qm delsnapshot 405 lab-clean
check-lab.sh linux101 | grep -E 'ไม่ผ่าน|== ผ่าน'
qm snapshot 405 lab-clean --description "clean state for linux101"
# [Git Bash]
curl -sk -b "PVEAuthCookie=$T" "$A/cluster/resources?type=vm"

# ── 5.5 reset และรื้อ Lab ───────────────────────────────────
reset-lab.sh linux101
remove-lab.sh test102
