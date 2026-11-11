# Cheat Sheet คำสั่งที่ใช้ทุกวัน

จากภาคผนวก ก ของหนังสือ Linux Server Quickstart (SysAdmin Pocket Series M01) คัดลอกคำสั่งไปใช้ได้ทันที
คำที่เป็นตัวอย่าง เช่น file, dir, username ให้เปลี่ยนเป็นชื่อจริงก่อนรัน

## ไฟล์และ Directory

| คำสั่ง | คำอธิบาย |
|---|---|
| `pwd` | แสดง Directory ปัจจุบัน |
| `cd /path` | เปลี่ยน Directory |
| `cd ~` | กลับ Home Directory |
| `cd ..` | ย้อนกลับ 1 ระดับ |
| `cd -` | กลับ Directory ก่อนหน้า |
| `ls -la` | แสดงไฟล์ทั้งหมดแบบละเอียด (รวมไฟล์ซ่อน) |
| `ls -lh` | แสดงไฟล์พร้อมขนาดแบบอ่านง่าย |
| `ls -lt` | แสดงไฟล์เรียงตามเวลาแก้ไขล่าสุด |
| `tree -L 2` | แสดงโครงสร้าง Directory 2 ระดับ |
| `mkdir -p dir/sub` | สร้าง Directory หลายระดับ |
| `cp file dest` | คัดลอกไฟล์ |
| `cp -a dir/ dest/` | คัดลอก Directory รักษา Permission |
| `mv old new` | ย้ายหรือเปลี่ยนชื่อ |
| `rm file` | ลบไฟล์ |
| `rm -rf dir/` | ลบ Directory ทั้งหมด |
| `cat file` | แสดงเนื้อหาไฟล์ทั้งหมด |
| `less file` | แสดงเนื้อหาแบบเลื่อนตรวจสอบ (q=ออก) |
| `head -20 file` | แสดง 20 บรรทัดแรก |
| `tail -20 file` | แสดง 20 บรรทัดสุดท้าย |
| `tail -f file` | ติดตามไฟล์แบบ Real-time |
| `nano file` | แก้ไขไฟล์ (Ctrl+X=ออก) |
| `find / -name "file"` | ค้นหาไฟล์ตามชื่อ |
| `grep "text" file` | ค้นหาข้อความในไฟล์ |

## User และ Permission

| คำสั่ง | คำอธิบาย |
|---|---|
| `whoami` | แสดง Username ปัจจุบัน |
| `id username` | แสดง UID, GID และ Groups |
| `sudo command` | รันคำสั่งด้วยสิทธิ์ root |
| `su - username` | สลับเป็น User อื่น |
| `useradd -m -s /bin/bash user` | สร้าง User ใหม่ |
| `passwd username` | ตั้ง/เปลี่ยน Password |
| `usermod -aG group user` | เพิ่ม User เข้า Group   ต้องมี -a |
| `userdel -r username` | ลบ User พร้อม Home Directory |
| `groupadd groupname` | สร้าง Group |
| `getent group groupname` | ตรวจสอบสมาชิกใน Group |
| `chmod 755 file` | กำหนด Permission แบบตัวเลข |
| `chmod u+x file` | เพิ่มสิทธิ์ Execute ให้ Owner |
| `chown user:group file` | เปลี่ยนเจ้าของไฟล์ |
| `chown -R user:group dir/` | เปลี่ยนเจ้าของแบบ Recursive |
| `visudo` | แก้ไข /etc/sudoers อย่างปลอดภัย |
| `Permission` | ที่ใช้บ่อย |
| `755 = rwxr-xr-x   Directory` | ทั่วไป, Script |
| `644 = rw-r--r--` | ไฟล์ Config |
| `600 = rw-------   Private Key, 700 = rwx------   .ssh/ Directory` | ไฟล์ลับ |
| `775 = rwxrwxr-x   Shared Directory` | ของ Group |

## Service และ systemctl

| คำสั่ง | คำอธิบาย |
|---|---|
| `systemctl status sshd` | ตรวจสอบสถานะ Service |
| `systemctl start sshd` | เปิด Service |
| `systemctl stop sshd` | ปิด Service |
| `systemctl restart sshd` | Restart Service |
| `systemctl reload sshd` | Reload Config (ไม่ต้อง Restart) |
| `systemctl enable sshd` | ตั้งให้เปิดอัตโนมัติเมื่อ Boot |
| `systemctl enable --now sshd` | เปิดอัตโนมัติ + เปิดทันที |
| `systemctl disable sshd` | ยกเลิกการเปิดอัตโนมัติ |
| `systemctl is-enabled sshd` | ตรวจว่าเปิดอัตโนมัติหรือไม่ |
| `systemctl list-units --type=service` | แสดง Service ที่ Active |
| `systemctl --failed` | แสดง Service ที่ Failed |

## สถานะระบบ

| คำสั่ง | คำอธิบาย |
|---|---|
| `uptime` | เวลาเปิดเครื่อง + Load Average |
| `free -h` | RAM ที่ใช้/ว่าง |
| `df -h` | พื้นที่ Disk |
| `du -sh /path` | ขนาดของ Directory |
| `top` | CPU + RAM + Process (q=ออก) |
| `htop` | เหมือน top แต่สวยกว่า |
| `ss -tlnp` | Port ที่เปิดรับ Connection |
| `nproc` | จำนวน CPU Core |
| `uname -r` | Kernel Version |
| `cat /etc/os-release` | OS Version |
| `hostname` | ชื่อ Server |
| `hostname -I` | IP Address |

## Network

| คำสั่ง | คำอธิบาย |
|---|---|
| `ip addr` | ตรวจสอบ IP Address ทุก Interface |
| `ip route` | ตรวจสอบ Routing Table |
| `ping -c 4 8.8.8.8` | ทดสอบ Network (4 ครั้ง) |
| `ping -c 4 google.com` | ทดสอบ DNS + Network |
| `ss -tlnp` | ตรวจสอบ TCP Port ที่ Listen |
| `ss -ulnp` | ตรวจสอบ UDP Port ที่ Listen |
| `curl -I https://example.com` | ทดสอบ HTTP Response |
| `nc -zv host port` | ทดสอบเชื่อมต่อ Port |

## Firewall (firewalld)

| คำสั่ง | คำอธิบาย |
|---|---|
| `firewall-cmd --list-all` | ตรวจสอบกฎทั้งหมด |
| `firewall-cmd --list-ports` | ตรวจสอบเฉพาะ Port ที่เปิด |
| `firewall-cmd --list-services` | ตรวจสอบเฉพาะ Service ที่เปิด |
| `firewall-cmd --permanent --add-port=8080/tcp` | เปิด Port (ถาวร) |
| `firewall-cmd --permanent --add-service=http` | เปิด Service (ถาวร) |
| `firewall-cmd --permanent --remove-port=8080/tcp` | ปิด Port (ถาวร) |
| `firewall-cmd --reload` | Reload กฎ |
| `firewall-cmd --get-services` | ตรวจสอบ Service ที่รองรับ ทั้งหมด |

หมายเหตุ: สูตร permanent + reload ทุกครั้ง

## Package Manager (dnf)

| คำสั่ง | คำอธิบาย |
|---|---|
| `dnf update -y` | อัปเดต Package ทั้งหมด |
| `dnf install -y pkg` | ติดตั้ง Package |
| `dnf remove -y pkg` | ลบ Package |
| `dnf search keyword` | ค้นหา Package |
| `dnf info pkg` | ตรวจสอบข้อมูล Package |
| `dnf list installed` | ตรวจสอบ Package ที่ติดตั้งแล้ว |
| `dnf check-update` | ตรวจสอบว่ามี Update อะไรบ้าง |
| `dnf autoremove -y` | ลบ Package ที่ไม่ใช้แล้ว |
| `dnf repolist` | ตรวจสอบ Repository ที่เปิดอยู่ |

## Log (journalctl)

| คำสั่ง | คำอธิบาย |
|---|---|
| `journalctl -u sshd` | Log ของ Service เฉพาะตัว |
| `journalctl -u sshd -f` | ติดตาม Log แบบ Real-time |
| `journalctl -b` | Log ตั้งแต่ Boot ล่าสุด |
| `journalctl -p err` | เฉพาะ Error ขึ้นไป |
| `journalctl -p err --since today` | Error ของวันนี้ |
| `journalctl -n 50` | 50 บรรทัดล่าสุด |
| `journalctl --since "2025-01-15 08:00"` | Log ตามช่วงเวลา |
| `Log Files` | สำคัญ |
| `/var/log/messages     Log` | ทั่วไป |
| `/var/log/secure       Log` | การ Login, sudo |
| `/var/log/dnf.log      Log` | การติดตั้ง Package |
| `/var/log/cron         Log` | ของ Cron Job |

## SSH

| คำสั่ง | คำอธิบาย |
|---|---|
| `ssh user@host` | เชื่อมต่อ SSH |
| `ssh -p 2222 user@host` | เชื่อมต่อ SSH Port อื่น |
| `ssh-keygen -t ed25519` | สร้าง SSH Key Pair |
| `ssh-copy-id user@host` | ส่ง Public Key ไป Server |
| `scp file user@host:/path` | คัดลอกไฟล์ไป Server |
| `scp user@host:/path file` | คัดลอกไฟล์จาก Server |
| `sshd -t` | ตรวจ Syntax ของ sshd_config |

## Backup

| คำสั่ง | คำอธิบาย |
|---|---|
| `cp file file.bak.$(date +%Y%m%d)` | สำรองไฟล์พร้อมวันที่ |
| `tar czf backup.tar.gz /path` | สำรอง Directory เป็น tar.gz |
| `tar tzf backup.tar.gz` | ตรวจสอบรายการไฟล์ใน Backup |
| `tar xzf backup.tar.gz -C /` | กู้คืนจาก Backup |

