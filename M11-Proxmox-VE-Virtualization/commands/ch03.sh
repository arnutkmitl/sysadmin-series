#!/usr/bin/env bash
# บทที่ 3 LXC Container
# SysAdmin Pocket Series M11 Proxmox VE: สร้าง Virtual Lab ใน 1 วัน
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# บรรทัดที่มี [PowerShell] รันใน PowerShell ของ Windows, [Git Bash] รันใน Git Bash, ที่เหลือรันบน pve ในนาม root
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 3.2 template ของ container ──────────────────────────────
pveam update
pveam available --section system | grep -E 'rocky|ubuntu-26|debian-13'
pveam download local rockylinux-10-default_20251001_amd64.tar.xz
pveam download local ubuntu-26.04-standard_26.04-1_amd64.tar.zst
pveam list local

# ── 3.3 สร้าง container ตัวแรก ──────────────────────────────
pct create 200 local:vztmpl/rockylinux-10-default_20251001_amd64.tar.xz \
    --hostname web1 --unprivileged 1 --cores 1 --memory 512 --swap 512 \
    --rootfs local-lvm:8 \
    --net0 name=eth0,bridge=vmbr0,ip=192.168.56.61/24,gw=192.168.56.60 \
    --nameserver 1.1.1.1 --ssh-public-keys /root/lab.pub --features nesting=1 --start 1
pct status 200

# ── ให้เครื่องบน vmbr0 ออก Internet ─────────────────────────
pct exec 200 -- ping -c2 -W3 1.1.1.1 | tail -1
ifreload -a
iptables -t nat -S POSTROUTING
iptables -t nat -D POSTROUTING -s 10.10.10.0/24 -o nic0 -j MASQUERADE
pct exec 200 -- ping -c2 -W3 1.1.1.1 | tail -1

# ── ติดตั้งเว็บใน container ─────────────────────────────────
pct exec 200 -- dnf install -y nginx
pct exec 200 -- systemctl enable --now nginx
pct exec 200 -- bash -c 'echo "web1 in LXC on $(hostname)" > /usr/share/nginx/html/index.html'
# [PowerShell]
curl.exe -sI http://192.168.56.61 | Select-Object -First 2
# [PowerShell]
curl.exe -s http://192.168.56.61
pct exec 200 -- free -m | head -2

# ── 3.4 แชร์โฟลเดอร์จาก pve ด้วย bind mount ─────────────────
mkdir -p /srv/webdata && echo "from host /srv/webdata" > /srv/webdata/index.html
pct set 200 -mp0 /srv/webdata,mp=/usr/share/nginx/html
pct reboot 200
pct exec 200 -- ls -ln /usr/share/nginx/html
pct exec 200 -- touch /usr/share/nginx/html/test.txt
pct exec 200 -- cat /proc/self/uid_map
chown -R 100000:100000 /srv/webdata
pct exec 200 -- touch /usr/share/nginx/html/test.txt
pct exec 200 -- ls -ln /usr/share/nginx/html
ls -ln /srv/webdata

# ── 3.5 unprivileged กับ privileged ─────────────────────────
pct create 202 local:vztmpl/ubuntu-26.04-standard_26.04-1_amd64.tar.zst --hostname priv-test \
    --unprivileged 0 --memory 512 --rootfs local-lvm:4 \
    --net0 name=eth0,bridge=vmbr1,ip=10.10.10.62/24,gw=10.10.10.1 --start 1
pct exec 202 -- cat /proc/self/uid_map
(pct exec 200 -- sleep 222 &); (pct exec 202 -- sleep 333 &); sleep 8
ps -o user,pid,cmd -C sleep | grep -E 'USER|222|333'
pct stop 202
pct destroy 202 --purge

# ── 3.6 template และ clone ของ container ────────────────────
pct shutdown 200
pct template 200
pct clone 200 201 --hostname web2
pct set 200 -delete mp0
pct clone 200 201 --hostname web2
pct set 201 -net0 name=eth0,bridge=vmbr0,ip=192.168.56.62/24,gw=192.168.56.60
pct start 201
pct list
lvs | grep -E '200|201'
# [PowerShell]
curl.exe -s http://192.168.56.62
pct exec 201 -- dnf install -y openssh-server
pct exec 201 -- systemctl enable --now sshd
ssh -i /root/.ssh/lab root@192.168.56.62 'hostname; cat /etc/rocky-release'

# ── 3.7 กล่อง Ubuntu Server 26.04 ───────────────────────────
pct create 203 local:vztmpl/ubuntu-26.04-standard_26.04-1_amd64.tar.zst --hostname ubu1 \
    --unprivileged 1 --features nesting=1 --memory 512 --rootfs local-lvm:4 \
    --net0 name=eth0,bridge=vmbr1,ip=10.10.10.63/24,gw=10.10.10.1 --nameserver 1.1.1.1 --start 1
pct exec 203 -- bash -c 'apt-get update && apt-get install -y nginx'
pct exec 203 -- nginx -v
curl -sI http://10.10.10.63 | head -2
