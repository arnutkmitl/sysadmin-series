#!/usr/bin/env bash
# บทที่ 6 โปรเจกต์จบเล่ม: DR Drill กู้ทั้งเครื่องบนเครื่องเปล่า
# SysAdmin Pocket Series M17 Backup & Disaster Recovery
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── NFS บน bkp ──────────────────────────────────────────────
# บนเครื่อง bkp
sudo dnf -y install nfs-utils
sudo install -d -m 700 /srv/backup/rear
echo "/srv/backup/rear 192.168.56.85(rw,no_root_squash,sync) 192.168.56.87(ro,no_root_squash,sync)" | sudo tee /etc/exports.d/rear.exports
sudo systemctl enable --now nfs-server && sudo exportfs -rav
for r in 85 87; do for s in nfs rpc-bind mountd; do sudo firewall-cmd --permanent --add-rich-rule="rule family=ipv4 source address=192.168.56.$r service name=$s accept"; done; done
sudo firewall-cmd --reload

# ── local.conf ──────────────────────────────────────────────
# บนเครื่อง prod
sudo dnf -y install rear xorriso grub2-efi-x64-modules nfs-utils
sudo install -m 600 local.conf /etc/rear/local.conf
time sudo rear -v mkbackup
sudo systemctl start backup.service; systemctl show backup.service -p Result
sudo mariadb -N -e "SELECT COUNT(*) FROM shop.orders"; sudo -u postgres psql -At -d ledger -c "SELECT count(*) FROM entries"
sudo bash -c 'cd /srv/files && find . -type f -print0 | sort -z | xargs -0 sha256sum' > prod-files.sha256

# ── 6.3 เครื่องเปล่า dr ─────────────────────────────────────
# PowerShell บนเครื่อง Windows
VBoxManage createvm --name m17dr --ostype RedHat_64 --register
VBoxManage modifyvm m17dr --firmware efi --memory 2048 --cpus 2 --graphicscontroller vmsvga --vram 16 --nic1 nat --nic2 hostonly --hostonlyadapter2 "VirtualBox Host-Only Ethernet Adapter"
VBoxManage modifyvm m17dr --natpf1 "ssh,tcp,127.0.0.1,52287,,2222"
VBoxManage storagectl m17dr --name SATA --add sata --controller IntelAhci
VBoxManage storagectl m17dr --name IDE --add ide
VBoxManage createmedium disk --filename m17dr.vdi --size 20480
VBoxManage storageattach m17dr --storagectl SATA --port 0 --device 0 --type hdd --medium m17dr.vdi
# บนเครื่อง Host
ssh -p 2222 admin@192.168.56.86 'sudo cat /srv/backup/rear/prod/rear-prod.iso' > rear-prod.iso
# PowerShell บนเครื่อง Windows
VBoxManage storageattach m17dr --storagectl IDE --port 0 --device 0 --type dvddrive --medium rear-prod.iso
VBoxManage modifyvm m17dr --boot1 dvd --boot2 disk

# ── 6.4 Lab 6.1 DR drill ────────────────────────────────────
# ⚠️ ขั้นนี้ปิด prod ถาวรตลอดการซ้อม ระบบที่กู้บน dr ใช้ชื่อและ IP เดียวกับ prod ถ้าเปิดสองเครื่องพร้อมกัน IP จะชนกัน ในเหตุการณ์จริงให้แน่ใจว่าเครื่องเดิมปิดหรือถูกตัดจากเครือข่ายก่อนกู้
# PowerShell บนเครื่อง Windows
VBoxManage controlvm m17prod acpipowerbutton
VBoxManage startvm m17dr

# ── กู้ระบบ ─────────────────────────────────────────────────
# PowerShell บนเครื่อง Windows
VBoxManage storageattach m17dr --storagectl IDE --port 0 --device 0 --type dvddrive --medium emptydrive --forceunmount
# บนเครื่อง Host
ssh -p 52287 admin@127.0.0.1 'hostname; ip -br a show enp0s8; getenforce; systemctl is-active mariadb postgresql docker nginx backup.timer'

# ── ช่องโหว่ข้อแรก: ค่าตั้งใน datadir ───────────────────────
# บนเครื่อง dr
sudo install -d -m 700 /root/dr && sudo install -m 600 wal-archive.conf /root/dr/
time sudo /usr/local/sbin/dr-restore-data.sh

# ── ช่องโหว่ข้อที่สอง: ข้อมูลที่อยู่ในสำเนาเดียว ────────────
# บนเครื่อง dr
sudo bash -c 'source /root/.config/restic/s3-env; restic restore latest --target / --include /var/backup/docker' | tail -1
sudo restorecon -R /var/backup
sudo /usr/local/sbin/docker-restore.sh /var/backup/docker/wordpress-2026-11-18_081024 | tail -2

# ── 6.6 check-backup.sh และผลการซ้อม ────────────────────────
# บนเครื่อง dr
cd /srv/files && sudo sha256sum --quiet -c /tmp/prod-files.sha256 && echo "checksum: all $(wc -l < /tmp/prod-files.sha256) files match"
sudo /usr/local/sbin/check-backup.sh | grep -E "FAIL|ผ่าน"
sudo systemctl start backup.service
sudo /usr/local/sbin/check-backup.sh | grep -v NOTICE
# บนเครื่อง bkp
sudo systemctl start snap-pull.service; systemctl show snap-pull.service -p Result
