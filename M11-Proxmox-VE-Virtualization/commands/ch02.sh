#!/usr/bin/env bash
# บทที่ 2 Virtual Machine: template, clone, snapshot และ backup
# SysAdmin Pocket Series M11 Proxmox VE: สร้าง Virtual Lab ใน 1 วัน
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# บรรทัดที่มี [PowerShell] รันใน PowerShell ของ Windows, [Git Bash] รันใน Git Bash, ที่เหลือรันบน pve ในนาม root
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 2.1 CPU type ของ Rocky Linux 10 ─────────────────────────
qm showcmd 100 --pretty | grep -E -- '-cpu|accel'

# ── 2.2 cloud image ─────────────────────────────────────────
pvesh create /nodes/pve/storage/local/download-url --content import \
    --filename Rocky-10-GenericCloud-Base-10.2.qcow2 \
    --url https://download.rockylinux.org/pub/rocky/10/images/x86_64/Rocky-10-GenericCloud-Base-10.2-20260525.0.x86_64.qcow2 \
    --checksum 9fc9e9ff16888bb68ac39b0392e25c9c92684d50c85f1cce6ab549363bbc4b48 --checksum-algorithm sha256
pvesh create /nodes/pve/storage/local/download-url --content import \
    --filename ubuntu-26.04-server-cloudimg-amd64.qcow2 \
    --url https://cloud-images.ubuntu.com/releases/resolute/release/ubuntu-26.04-server-cloudimg-amd64.img \
    --checksum 5645d0318ad21f643ebb1ac4567514620e9893380b07b0201fda163baa5b7eb5 --checksum-algorithm sha256
pvesm list local --content import

# ── 2.3 template แบบ Cloud-Init ─────────────────────────────
qm create 9000 --name rocky10-tpl --memory 2048 --cores 2 --cpu max --kvm 0 \
    --net0 virtio,bridge=vmbr1 --scsihw virtio-scsi-single \
    --scsi0 local-lvm:0,import-from=local:import/Rocky-10-GenericCloud-Base-10.2.qcow2 \
    --ide2 local-lvm:cloudinit --boot order=scsi0 --serial0 socket --vga serial0 \
    --agent enabled=1 --ostype l26
qm set 9000 --ciuser admin --sshkeys /root/lab.pub \
    --ipconfig0 ip=10.10.10.10/24,gw=10.10.10.1 --nameserver 1.1.1.1 --searchdomain lab.test
qm resize 9000 scsi0 20G
qm template 9000
qm list

# ── 2.4 clone และ boot ครั้งแรก ─────────────────────────────
qm clone 9000 101 --name rocky1
qm set 101 --ipconfig0 ip=10.10.10.11/24,gw=10.10.10.1
lvs | grep 101
qm start 101
qm agent 101 network-get-interfaces | grep '"ip-address"'
ssh -i /root/.ssh/lab admin@10.10.10.11 'hostname; cat /etc/rocky-release; ip -br -4 a | grep eth; df -h / | tail -1; systemctl is-active qemu-guest-agent'

# ── 2.5 snapshot ────────────────────────────────────────────
qm snapshot 101 lab-clean --description "clean state for class101"
qm listsnapshot 101
qm rollback 101 lab-clean

# ── 2.6 backup และ restore ──────────────────────────────────
vzdump 101 --storage local --mode stop --compress zstd
qmrestore /var/lib/vz/dump/vzdump-qemu-101-2026_11_14-11_22_15.vma.zst 105 --storage local-lvm
qm config 105 | grep -E '^(name|ipconfig0|scsi0)'
vzdump 201 --storage local --mode snapshot --compress zstd
pct restore 204 local:backup/vzdump-lxc-201-2026_11_14-11_07_21.tar.zst --storage local-lvm
