# ภาคผนวก ก Cheat Sheet คำสั่งที่ใช้ทุกวัน

ภาคผนวกนี้รวมคำสั่งที่ใช้ในบทที่ 1 ถึง 7 จัดเป็นหมวดตามงานที่ทำจริง พิมพ์ไปแปะข้างจอได้ หรือเปิดไฟล์ `cheatsheet.md` ใน GitHub ของเล่มเพื่อคัดลอกไปวาง (ดูภาคผนวก ง)

คำสั่งในตารางรันบน server ที่ prompt `[admin@server ~]$` ยกเว้นหมวด SSH บางแถวและหมวด VirtualBox ซึ่งรันบน Host PC คำที่เป็นภาษาไทยในคำสั่ง เช่น ชื่อไฟล์ หรือ พอร์ต คือค่าที่ต้องแทนเอง คำสั่งที่ทำลายข้อมูลหรือตัดการเชื่อมต่อได้ไม่อยู่ในตาราง แต่แยกไว้ในกรอบเตือนท้ายแต่ละหมวด

## ค่าของ Lab ที่ต้องจำ

ตารางที่ ก-1 ค่ามาตรฐานของ Lab ที่ทุกเล่มในซีรีส์อ้างถึง

| รายการ | ค่า |
|---|---|
| VM | `server` 2 vCPU, RAM 2048 MB, ดิสก์ VDI 20 GB, SATA |
| OS | Rocky Linux 10.2 (Red Quartz) |
| hostname | `server.lab.local` |
| enp0s3 (Adapter 1) | NAT, DHCP 10.0.2.15/24, gateway 10.0.2.2, DNS ของ Host PC |
| enp0s8 (Adapter 2) | Host-only #1, Static 192.168.56.10/24 ไม่มี gateway และ DNS |
| Host PC | 192.168.56.1 |
| DHCP ของ Host-only | .100 เป็น DHCP server แจก .101 ถึง .254 ห้ามตั้ง Static ช่วงนี้ |
| sudo user | `admin` อยู่ใน group wheel, root ถูกปิด |
| SSH | พอร์ต 2222, key ed25519 เท่านั้น, เข้าด้วย `ssh server` หรือ `ssh -p 2222 admin@192.168.56.10` |
| Firewall | firewalld zone public: 2222/tcp, http, https |
| SELinux | Enforcing, ssh_port_t รวมพอร์ต 2222 |
| Snapshot | `base-10.2`, `ch02-start` ถึง `ch06-start`, `m01-done` ถ่ายตอนปิดเครื่องเท่านั้น |

## ไฟล์และ Directory

ตารางที่ ก-2 คำสั่งจัดการไฟล์และ Directory

| คำสั่ง | ใช้ทำอะไร |
|---|---|
| `pwd` | แสดง Directory ปัจจุบัน |
| `cd /etc/ssh` | เปลี่ยน Directory แบบ absolute path |
| `cd ~` หรือ `cd` | กลับ Home Directory |
| `cd ..` | ขึ้นไป 1 ระดับ |
| `cd -` | กลับ Directory ก่อนหน้า |
| `ls -la` | แสดงทุกไฟล์รวมไฟล์ซ่อนพร้อมสิทธิ์และเจ้าของ |
| `ls -lh` | แสดงขนาดไฟล์แบบ K, M, G |
| `ls -lt` | เรียงตามเวลาแก้ไขล่าสุด ไฟล์ใหม่อยู่บน |
| `ls -ld /backup` | ดูสิทธิ์ของตัว Directory เอง ไม่ใช่ของข้างใน |
| `tree -L 2 /etc/ssh` | แสดงโครงสร้าง 2 ระดับ (ติดตั้งก่อนด้วย `sudo dnf install -y tree`) |
| `mkdir -p /projects/webapp/logs` | สร้าง Directory หลายระดับในคำสั่งเดียว |
| `touch ชื่อไฟล์` | สร้างไฟล์ว่าง หรืออัปเดตเวลาของไฟล์เดิม |
| `cp ไฟล์ ปลายทาง` | คัดลอกไฟล์ |
| `cp -a dir/ ปลายทาง/` | คัดลอกทั้ง Directory โดยคงสิทธิ์ เจ้าของ และเวลา |
| `mv ชื่อเดิม ชื่อใหม่` | ย้ายหรือเปลี่ยนชื่อ |
| `stat ไฟล์` | ดูขนาด สิทธิ์ เจ้าของ และเวลาแก้ไขแบบละเอียด |
| `file ไฟล์` | ตรวจชนิดไฟล์ เช่น text หรือ gzip |
| `ln -s ต้นทาง ชื่อลิงก์` | สร้าง Symbolic Link |

ตารางที่ ก-3 คำสั่งอ่านและค้นหาเนื้อหาไฟล์

| คำสั่ง | ใช้ทำอะไร |
|---|---|
| `cat ไฟล์` | แสดงเนื้อหาไฟล์สั้นทั้งไฟล์ |
| `less ไฟล์` | เลื่อนอ่านไฟล์ยาว กด `/` เพื่อค้นหา กด `q` เพื่อออก |
| `head -20 ไฟล์` | แสดง 20 บรรทัดแรก |
| `tail -20 ไฟล์` | แสดง 20 บรรทัดสุดท้าย |
| `sudo tail -f /var/log/secure` | ติดตามไฟล์ที่กำลังเขียนแบบ Real-time กด Ctrl+C เพื่อหยุด |
| `sudo grep -n "Port" /etc/ssh/sshd_config` | ค้นข้อความพร้อมเลขบรรทัด |
| `grep -rn "PasswordAuthentication" /etc/ssh/` | ค้นทุกไฟล์ใน Directory |
| `grep -v "^#" ไฟล์ \| grep -v "^$"` | ตัดบรรทัด comment และบรรทัดว่าง เหลือเฉพาะค่าที่ใช้จริง |
| `find /etc -name "*.conf" -mmin -60` | หาไฟล์ .conf ที่แก้ในชั่วโมงที่ผ่านมา |
| `find /home -size +100M` | หาไฟล์ใหญ่กว่า 100 MB |
| `wc -l ไฟล์` | นับจำนวนบรรทัด |
| `nano ไฟล์` | แก้ไขไฟล์ Ctrl+O บันทึก Ctrl+X ออก (Minimal ต้องติดตั้ง nano ก่อน) |
| `vi ไฟล์` | แก้ไขไฟล์ด้วย vi กด `i` เพื่อพิมพ์ กด Esc แล้ว `:wq` เพื่อบันทึกและออก |

> ⚠️ คำสั่งต่อไปนี้ลบไฟล์ถาวร Linux ไม่มีถังขยะ ตรวจ path ด้วย `ls` ก่อนกด Enter ทุกครั้ง

- `rm ไฟล์` ลบไฟล์
- `rm -i ไฟล์` ลบโดยถามยืนยันทีละไฟล์ ใช้แบบนี้เมื่อไม่แน่ใจ
- `rm -r dir/` ลบ Directory พร้อมทุกอย่างข้างใน
- `rm -rf dir/` ลบโดยไม่ถาม ห้ามใช้กับตัวแปรที่อาจว่าง เช่น `rm -rf $DIR/` เพราะถ้า `$DIR` ว่างจะกลายเป็น `/`
- `cp` และ `mv` เขียนทับไฟล์ปลายทางที่ชื่อซ้ำโดยไม่ถาม ใส่ `-i` เมื่อไม่แน่ใจ

## สถานะระบบ

ตารางที่ ก-4 คำสั่งดูสถานะเครื่อง

| คำสั่ง | ใช้ทำอะไร |
|---|---|
| `cat /etc/rocky-release` | รุ่นของ Rocky Linux ต้องได้ `Rocky Linux release 10.2 (Red Quartz)` |
| `cat /etc/os-release` | ข้อมูล OS แบบที่ทุก Distribution มีเหมือนกัน |
| `uname -r` | รุ่นของ Kernel |
| `hostnamectl` | hostname, OS, Kernel และชนิด Virtualization ในหน้าเดียว |
| `sudo hostnamectl set-hostname server.lab.local` | ตั้ง hostname ถาวร |
| `timedatectl` | เวลา เขตเวลา และสถานะซิงก์ NTP |
| `sudo timedatectl set-timezone Asia/Bangkok` | ตั้งเขตเวลาเป็นประเทศไทย |
| `uptime` | เปิดเครื่องมานานเท่าไร และ Load Average 1, 5, 15 นาที |
| `nproc` | จำนวน CPU Core |
| `free -h` | RAM และ Swap ที่ใช้และเหลือ ดูช่อง available |
| `df -h` | พื้นที่ดิสก์แต่ละ Filesystem |
| `df -i` | จำนวน inode ที่เหลือ ใช้เมื่อดิสก์ยังว่างแต่สร้างไฟล์ไม่ได้ |
| `sudo du -sh /var/log` | ขนาดรวมของ Directory |
| `sudo du -xh / --max-depth=1 \| sort -rh \| head` | หา Directory ที่ใหญ่ที่สุดใน Filesystem ราก |
| `lsblk` | ดิสก์และ Partition ทั้งหมด |
| `top` | CPU, RAM และ Process แบบ Real-time กด `q` เพื่อออก |
| `htop` | top ที่อ่านง่ายกว่า ต้องเปิด CRB และ EPEL ก่อนติดตั้ง |
| `ps aux --sort=-%mem \| head` | Process ที่ใช้ RAM มากที่สุด |
| `last -n 10` | 10 การ Login ล่าสุด |
| `who` | ใครกำลัง Login อยู่ |

> ⚠️ `sudo reboot` และ `sudo poweroff` ตัด Session SSH ทุกคนทันที ใน Production ให้แจ้งผู้ใช้ก่อน หรือนัดเวลาด้วย `sudo shutdown -r +10` ซึ่งยกเลิกได้ด้วย `sudo shutdown -c`

## User และ Group

ตารางที่ ก-5 คำสั่งจัดการ User และ Group

| คำสั่ง | ใช้ทำอะไร |
|---|---|
| `whoami` | ชื่อ User ปัจจุบัน |
| `id admin` | UID, GID และทุก Group ของ User |
| `groups` | Group ของ User ปัจจุบัน |
| `getent passwd alice` | ตรวจว่ามี User นี้หรือไม่ ใช้ก่อนสร้างเพื่อกันชื่อซ้ำ |
| `getent group webdev` | ดูสมาชิกของ Group |
| `sudo useradd -m -s /bin/bash -c "ชื่อเต็ม" alice` | สร้าง User พร้อม Home และ Shell |
| `sudo passwd alice` | ตั้งหรือเปลี่ยน Password |
| `sudo passwd -S alice` | ดูสถานะบัญชี PS คือปกติ LK คือถูก Lock |
| `sudo chage -l alice` | ดูวันหมดอายุของ Password |
| `sudo chage -d 0 alice` | บังคับให้เปลี่ยน Password ตอน Login ครั้งถัดไป |
| `sudo groupadd webdev` | สร้าง Group |
| `sudo usermod -aG webdev alice` | เพิ่ม User เข้า Group เสริม ต้องมี `-a` เสมอ |
| `sudo usermod -aG wheel alice` | ให้สิทธิ์ sudo บน Rocky Linux |
| `sudo usermod -L alice` | Lock Password ของบัญชี |
| `sudo usermod -U alice` | ปลด Lock |
| `su - alice` | สลับเป็น User อื่นพร้อม Environment ของเขา |
| `newgrp webdev` | ใช้ Group ใหม่ทันทีโดยไม่ต้อง Logout |

> ⚠️ คำสั่งต่อไปนี้แก้ไขหรือลบบัญชีแบบย้อนกลับไม่ได้

- `sudo usermod -G webdev alice` ที่ไม่มี `-a` จะลบ alice ออกจากทุก Group เสริมอื่น รวมถึง wheel
- `sudo userdel -r alice` ลบบัญชีพร้อม Home Directory และ Mail Spool ถ้าไม่แน่ใจให้ `usermod -L` ไว้ก่อน
- `sudo groupdel webdev` ลบ Group ไฟล์ที่เคยเป็นของ Group นี้จะเหลือเป็นเลข GID

## Permission และ sudo

ตารางที่ ก-6 คำสั่งจัดการสิทธิ์

| คำสั่ง | ใช้ทำอะไร |
|---|---|
| `chmod 644 ไฟล์` | กำหนดสิทธิ์แบบตัวเลข |
| `chmod u+x script.sh` | เพิ่มสิทธิ์ Execute ให้เจ้าของ |
| `chmod g+w,o-rwx ไฟล์` | เพิ่มและลดสิทธิ์หลายกลุ่มพร้อมกัน |
| `sudo chmod 2775 /projects/webapp` | Shared Directory พร้อม Set-GID ไฟล์ใหม่ได้ Group เดียวกับ Directory |
| `sudo chmod +t /shared` | Sticky Bit ลบได้เฉพาะไฟล์ของตัวเอง |
| `sudo chown alice:webdev ไฟล์` | เปลี่ยนเจ้าของและ Group |
| `sudo chown -R alice:webdev dir/` | เปลี่ยนเจ้าของทั้ง Directory |
| `sudo chgrp webdev ไฟล์` | เปลี่ยนเฉพาะ Group |
| `umask` | ดูค่า umask ปัจจุบัน ค่าปกติ 0022 |
| `sudo -l` | ดูว่า User ปัจจุบันใช้ sudo กับคำสั่งใดได้บ้าง |
| `sudo visudo` | แก้ `/etc/sudoers` อย่างปลอดภัย ตรวจ Syntax ก่อนบันทึก |
| `sudo visudo -cf /etc/sudoers.d/webmaster` | ตรวจ Syntax ของไฟล์ใน sudoers.d |
| `sudo journalctl -t sudo -n 20` | ดูประวัติการใช้ sudo 20 รายการล่าสุด |

ตารางที่ ก-7 ค่าสิทธิ์ที่ใช้บ่อย

| ตัวเลข | สัญลักษณ์ | ใช้กับ |
|---|---|---|
| 755 | rwxr-xr-x | Directory ทั่วไป และ Script ที่ทุกคนรันได้ |
| 644 | rw-r--r-- | ไฟล์ Config และไฟล์ทั่วไป |
| 640 | rw-r----- | ไฟล์ Config ที่ Group อ่านได้ คนอื่นห้ามอ่าน |
| 600 | rw------- | Private Key, `authorized_keys`, ไฟล์ Backup |
| 700 | rwx------ | `~/.ssh`, `/backup`, Script ของ root |
| 440 | r--r----- | ไฟล์ใน `/etc/sudoers.d/` |
| 2775 | rwxrwsr-x | Shared Directory ของทีมที่มี Set-GID |

> ⚠️ `chmod -R 777` และ `chown -R` บน Directory ระบบ เช่น `/etc` หรือ `/` ทำให้ sshd ปฏิเสธ Key และ sudo หยุดทำงาน แก้คืนยากมาก ตรวจ path ก่อนใช้ `-R` ทุกครั้ง และอย่าแก้ `/etc/sudoers` ด้วย `nano` ตรง ๆ ให้ใช้ `visudo` เสมอ

## Service ด้วย systemctl

ตารางที่ ก-8 คำสั่งจัดการ Service

| คำสั่ง | ใช้ทำอะไร |
|---|---|
| `systemctl status sshd` | สถานะ Service พร้อม Log 10 บรรทัดล่าสุด |
| `systemctl is-active sshd` | ตอบสั้น ๆ ว่า active หรือ inactive ใช้ใน Script ได้ |
| `systemctl is-enabled sshd` | เปิดอัตโนมัติตอน Boot หรือไม่ |
| `sudo systemctl start ชื่อ` | เปิด Service |
| `sudo systemctl restart sshd` | ปิดแล้วเปิดใหม่ ใช้ค่า Config ใหม่ |
| `sudo systemctl reload ชื่อ` | อ่าน Config ใหม่โดยไม่ตัด Connection (ถ้า Service รองรับ) |
| `sudo systemctl enable --now ชื่อ` | ตั้งให้เปิดตอน Boot และเปิดทันที |
| `sudo systemctl disable ชื่อ` | ยกเลิกการเปิดตอน Boot |
| `systemctl list-units --type=service --state=running` | Service ที่กำลังทำงาน |
| `systemctl --failed` | Service ที่ล้มเหลว |
| `systemctl list-timers` | Timer ทั้งหมดและเวลาที่จะรันครั้งถัดไป |
| `systemctl cat sshd` | ดูไฟล์ Unit ที่ใช้งานจริงรวม Drop-in |
| `sudo systemctl daemon-reload` | ให้ systemd อ่านไฟล์ Unit ใหม่หลังแก้ |

> ⚠️ `sudo systemctl stop sshd` และ `sudo systemctl restart sshd` ที่ Config ผิด ทำให้ SSH Session ใหม่เข้าไม่ได้ รัน `sudo sshd -t` ก่อน restart ทุกครั้ง และเปิด Session เดิมค้างไว้จนทดสอบ Session ใหม่ผ่าน

## Log ด้วย journalctl

ตารางที่ ก-9 คำสั่งอ่าน Log

| คำสั่ง | ใช้ทำอะไร |
|---|---|
| `sudo journalctl -u sshd` | Log ของ Service เดียว |
| `sudo journalctl -u sshd -f` | ติดตาม Log แบบ Real-time |
| `sudo journalctl -u sshd -n 50 --no-pager` | 50 บรรทัดล่าสุดโดยไม่เปิด pager |
| `sudo journalctl -b` | Log ตั้งแต่ Boot ครั้งล่าสุด |
| `sudo journalctl -b -1` | Log ของ Boot ครั้งก่อน ใช้หาสาเหตุเครื่อง Reboot เอง |
| `sudo journalctl -p err -b` | เฉพาะระดับ error ขึ้นไปของ Boot นี้ |
| `sudo journalctl -p err --since today` | error ทั้งหมดของวันนี้ จุดเริ่มต้นเมื่อเจอปัญหา |
| `sudo journalctl --since "2026-11-13 08:00" --until "2026-11-13 09:00"` | Log ตามช่วงเวลา |
| `sudo journalctl -t sudo` | Log ที่ติดป้ายชื่อโปรแกรมนั้น |
| `sudo journalctl -k` | Log ของ Kernel เหมือน dmesg |
| `journalctl --disk-usage` | Journal ใช้ดิสก์ไปเท่าไร |

ตารางที่ ก-10 ไฟล์ Log สำคัญบน Rocky Linux 10

| ไฟล์ | เนื้อหา |
|---|---|
| `/var/log/messages` | Log ทั่วไปของระบบ (เมื่อมี rsyslog) |
| `/var/log/secure` | การ Login, SSH และ sudo (rsyslog ติดตั้งมากับ Minimal) |
| `/var/log/dnf.log` | การติดตั้งและอัปเดต Package |
| `/var/log/cron` | การทำงานของ Cron Job |
| `/var/log/audit/audit.log` | เหตุการณ์ของ SELinux และ audit |
| `/var/log/backup.log` | Log ของ Backup Script จากบทที่ 6 |

> ⚠️ `sudo journalctl --vacuum-time=7d` และ `sudo journalctl --vacuum-size=200M` ลบ Log เก่าถาวร ใช้เมื่อดิสก์เต็มเท่านั้น และควรเก็บ Log ที่ต้องใช้ตรวจสอบย้อนหลังออกไปก่อน

## Package ด้วย dnf

ตารางที่ ก-11 คำสั่ง dnf ที่ใช้บ่อย

| คำสั่ง | ใช้ทำอะไร |
|---|---|
| `sudo dnf check-update` | ดูรายการที่มีอัปเดต ไม่ติดตั้ง |
| `sudo dnf update -y` | อัปเดตทุก Package |
| `sudo dnf update --security -y` | อัปเดตเฉพาะ Security Advisory |
| `sudo dnf install -y ชื่อ` | ติดตั้ง Package |
| `sudo dnf install -y tar nano vim-enhanced bash-completion` | เครื่องมือที่ Minimal ไม่มีมาให้ |
| `dnf search คำค้น` | ค้นหา Package |
| `dnf info ชื่อ` | รุ่น ขนาด และ Repository ของ Package |
| `dnf provides /usr/bin/semanage` | หาว่าไฟล์หรือคำสั่งนี้มาจาก Package ใด |
| `rpm -qf /etc/ssh/sshd_config` | ไฟล์ที่มีอยู่แล้วเป็นของ Package ใด |
| `dnf list installed` | Package ที่ติดตั้งแล้ว |
| `dnf repolist` | Repository ที่เปิดอยู่ |
| `sudo dnf config-manager --set-enabled crb` | เปิด CRB ก่อนติดตั้ง EPEL |
| `sudo dnf install -y epel-release` | ติดตั้ง Repository EPEL |
| `sudo dnf history` | ประวัติการติดตั้งและอัปเดต |
| `sudo dnf needs-restarting -r` | ตรวจว่าต้อง Reboot หรือไม่หลังอัปเดต |
| `sudo dnf needs-restarting -s` | Service ที่ควร restart หลังอัปเดต |
| `sudo dnf makecache` | โหลด Metadata จาก Mirror ใช้ทดสอบว่าออกเน็ตได้ |
| `sudo dnf clean all` | ล้าง Cache ของ dnf |
| `systemctl list-timers dnf-automatic*` | เวลาที่ dnf-automatic จะรันครั้งถัดไป |

> ⚠️ คำสั่งต่อไปนี้ถอด Package ออกจากระบบ อ่านรายการที่ dnf สรุปก่อนตอบ y ทุกครั้ง และอย่าใส่ `-y`

- `sudo dnf remove ชื่อ` ถอด Package พร้อม Package ที่พึ่งพามันอยู่ ถอด Package ระบบ เช่น openssh-server ผ่าน SSH จะเข้าเครื่องไม่ได้อีก
- `sudo dnf autoremove` ถอด Package ที่ dnf คิดว่าไม่มีใครใช้แล้ว
- `sudo dnf history undo หมายเลข` ย้อนการติดตั้งครั้งนั้นทั้งชุด

## Network

ตารางที่ ก-12 คำสั่งตรวจเครือข่าย

| คำสั่ง | ใช้ทำอะไร |
|---|---|
| `ip -br addr` | IP ของทุกการ์ดแบบบรรทัดเดียว enp0s3 ต้องได้ 10.0.2.15 enp0s8 ต้องได้ 192.168.56.10 |
| `ip -4 addr show enp0s8` | IP ของการ์ดเดียวแบบละเอียด |
| `ip route` | ตาราง Routing ต้องมี default ทาง enp0s3 เส้นเดียว |
| `ip route get 1.1.1.1` | แพ็กเก็ตไปปลายทางนี้ออกการ์ดใด ต้องเห็น `dev enp0s3` |
| `ping -c 3 10.0.2.2` | ทดสอบถึง gateway ของ NAT |
| `ping -c 3 8.8.8.8` | ทดสอบออกอินเทอร์เน็ตด้วย IP |
| `ping -c 3 rockylinux.org` | ทดสอบ DNS และอินเทอร์เน็ตพร้อมกัน |
| `cat /etc/resolv.conf` | DNS ที่ใช้อยู่ ต้องมีบรรทัด `nameserver` อย่างน้อยหนึ่งบรรทัด |
| `nmcli device status` | สถานะการ์ดและ Connection Profile ที่ผูกอยู่ |
| `nmcli con show` | รายการ Connection Profile |
| `nmcli con show enp0s8 \| grep ipv4` | ค่า IPv4 ทั้งหมดของ Profile |
| `sudo nmcli con mod enp0s8 ipv4.method manual ipv4.addresses 192.168.56.10/24` | ตั้ง Static IP ให้การ์ด Host-only |
| `sudo nmcli con mod enp0s8 ipv4.gateway "" ipv4.never-default yes` | ลบ gateway ที่ใส่ผิดการ์ด |
| `sudo nmcli con up enp0s8` | ใช้ค่าใหม่ของ Profile |
| `sudo ss -tlnp` | พอร์ต TCP ที่ Listen พร้อมชื่อโปรแกรม |
| `sudo ss -ulnp` | พอร์ต UDP ที่ Listen |
| `ss -tn state established` | Connection ที่เชื่อมต่ออยู่ตอนนี้ |
| `curl -I http://192.168.56.10` | ทดสอบ HTTP ดูเฉพาะ Header |
| `nc -zv -w 3 192.168.56.10 2222` | ทดสอบว่าพอร์ตเดียวเข้าได้หรือไม่ (ติดตั้ง `nmap-ncat` ก่อน) |
| `dig +short rockylinux.org` | ถาม DNS โดยตรง (ติดตั้ง `bind-utils` ก่อน) |

คำสั่งฝั่ง Host PC ที่ใช้คู่กันคือ `ping -n 2 192.168.56.10` ใน Command Prompt และ `Test-NetConnection 192.168.56.10 -Port 2222` ใน PowerShell คำสั่งหลังตอบ `TcpTestSucceeded : True` เมื่อพอร์ตเปิด

> ⚠️ `sudo nmcli con down ชื่อ` และ `sudo nmcli con mod` ที่การ์ด enp0s8 ตัด SSH ที่เข้ามาทางการ์ดนั้นทันที ให้แก้เครือข่ายจาก Console ของ VirtualBox เสมอ

## SSH

ตารางที่ ก-13 คำสั่ง SSH ฝั่ง Host PC

| คำสั่ง | ใช้ทำอะไร |
|---|---|
| `ssh admin@192.168.56.10` | เข้าเครื่องพอร์ต 22 (บทที่ 1 ถึง 3) |
| `ssh -p 2222 admin@192.168.56.10` | เข้าเครื่องพอร์ต 2222 (ตั้งแต่บทที่ 4) |
| `ssh server` | เข้าเครื่องผ่าน `~/.ssh/config` ที่ตั้งชื่อ Host ไว้ |
| `ssh -v server` | แสดงขั้นตอนเชื่อมต่อ ใช้หาว่า Key ถูกส่งหรือไม่ |
| `ssh server "uptime"` | รันคำสั่งเดียวบน server แล้วกลับมา |
| `ssh-keygen -t ed25519 -C "admin@hostpc"` | สร้าง Key Pair ed25519 |
| `type $env:USERPROFILE\.ssh\id_ed25519.pub \| ssh admin@192.168.56.10 "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"` | ส่ง Public Key จาก Windows (PowerShell) ไปที่ server |
| `ssh-copy-id -p 2222 admin@192.168.56.10` | ส่ง Public Key จาก Linux หรือ macOS |
| `ssh-keygen -lf ~/.ssh/id_ed25519.pub` | ดู Fingerprint ของ Key |
| `ssh-keygen -R 192.168.56.10` | ลบ Host Key เก่าเมื่อเจอ `REMOTE HOST IDENTIFICATION HAS CHANGED` |
| `scp -P 2222 ไฟล์ admin@192.168.56.10:~/` | คัดลอกไฟล์ไป server ใช้ `-P` ตัวใหญ่ |
| `scp server:~/ไฟล์ .` | ดึงไฟล์จาก server ผ่าน `~/.ssh/config` |

ตารางที่ ก-14 คำสั่ง SSH ฝั่ง server

| คำสั่ง | ใช้ทำอะไร |
|---|---|
| `sudo sshd -t` | ตรวจ Syntax ของ Config ไม่มีผลลัพธ์แปลว่าผ่าน |
| `sudo sshd -T \| grep -Ei '^(port\|passwordauthentication\|permitrootlogin\|allowusers\|maxauthtries)'` | ค่าที่ sshd ใช้จริงหลังรวมทุกไฟล์ |
| `sudo nano /etc/ssh/sshd_config.d/10-hardening.conf` | ไฟล์ Hardening ของเล่มนี้ |
| `ls -la ~/.ssh/` | ตรวจสิทธิ์ `.ssh` ต้อง 700 และ `authorized_keys` ต้อง 600 |
| `restorecon -Rv ~/.ssh` | คืน SELinux Context ของ `.ssh` |
| `sudo journalctl -u sshd -n 20` | Log ของ sshd ใช้ดูสาเหตุที่ Login ไม่ผ่าน |
| `sudo ss -tlnp \| grep sshd` | sshd ฟังพอร์ตใดอยู่ |

ตัวอย่าง `~/.ssh/config` บน Host PC ที่ทำให้ `ssh server` ใช้ได้

```
Host server
    HostName 192.168.56.10
    Port 2222
    User admin
    IdentityFile ~/.ssh/id_ed25519
```

> ⚠️ ก่อน `sudo systemctl restart sshd` หลังแก้พอร์ตหรือปิด Password ให้ทำสามอย่างครบก่อน คือ `sudo sshd -t` ผ่าน, เปิดพอร์ตใหม่ใน firewalld และ `semanage port` แล้ว จากนั้นเปิด Session เดิมค้างไว้จนทดสอบ Session ใหม่ผ่าน

## Firewall ด้วย firewalld

ตารางที่ ก-15 คำสั่ง firewall-cmd

| คำสั่ง | ใช้ทำอะไร |
|---|---|
| `sudo firewall-cmd --state` | firewalld ทำงานหรือไม่ |
| `sudo firewall-cmd --get-active-zones` | การ์ดใดอยู่ zone ใด |
| `sudo firewall-cmd --list-all` | กฎทั้งหมดของ zone ค่าเริ่มต้น (public) |
| `sudo firewall-cmd --list-services` | เฉพาะ Service ที่เปิด |
| `sudo firewall-cmd --list-ports` | เฉพาะพอร์ตที่เปิด |
| `sudo firewall-cmd --permanent --list-all` | กฎที่บันทึกไว้ จะมีผลหลัง reload |
| `sudo firewall-cmd --permanent --add-service=http` | เปิด Service ถาวร |
| `sudo firewall-cmd --permanent --add-port=2222/tcp` | เปิดพอร์ตถาวร |
| `sudo firewall-cmd --reload` | ใช้กฎ permanent ทั้งหมด |
| `firewall-cmd --get-services` | ชื่อ Service ที่ firewalld รู้จัก |
| `firewall-cmd --info-service=http` | Service นี้เปิดพอร์ตใด |
| `sudo firewall-cmd --add-port=8080/tcp` | เปิดชั่วคราว หายเมื่อ reload หรือ reboot ใช้ทดสอบ |
| `sudo firewall-cmd --runtime-to-permanent` | บันทึกกฎชั่วคราวที่ทดสอบผ่านแล้วเป็นถาวร |

หลักจำคือใส่ `--permanent` แล้วตามด้วย `--reload` ทุกครั้ง ถ้าลืม `--permanent` กฎหายตอน reboot ถ้าลืม `--reload` กฎยังไม่มีผล

> ⚠️ คำสั่งปิดพอร์ตอาจตัดตัวเองออกจากเครื่อง

- `sudo firewall-cmd --permanent --remove-service=ssh` ปิดพอร์ต 22 ทำหลังจากเข้า 2222 ได้แล้วเท่านั้น
- `sudo firewall-cmd --permanent --remove-port=พอร์ต/tcp` ตรวจว่าไม่ใช่พอร์ต SSH ที่ใช้อยู่
- `sudo systemctl stop firewalld` เปิดทุกพอร์ตสู่ภายนอก ห้ามใช้บนเครื่องที่ต่ออินเทอร์เน็ต
- `sudo firewall-cmd --panic-on` ตัดทุก Connection รวม SSH ใช้เมื่อมี Console เท่านั้น ยกเลิกด้วย `--panic-off`

## SELinux

ตารางที่ ก-16 คำสั่ง SELinux

| คำสั่ง | ใช้ทำอะไร |
|---|---|
| `getenforce` | Mode ปัจจุบัน ต้องเป็น Enforcing |
| `sestatus` | สถานะละเอียด รวม Mode ใน Config |
| `ls -Z ไฟล์` | ดู Context ของไฟล์ |
| `ps -eZ \| grep sshd` | ดู Context ของ Process |
| `sudo semanage port -l \| grep ssh_port_t` | พอร์ตที่ sshd ใช้ได้ |
| `sudo semanage port -a -t ssh_port_t -p tcp 2222` | อนุญาตให้ sshd ใช้พอร์ต 2222 |
| `sudo semanage port -m -t http_port_t -p tcp 8080` | แก้ป้ายของพอร์ตที่มีอยู่แล้ว |
| `sudo semanage fcontext -a -t httpd_sys_content_t "/data/web(/.*)?"` | กำหนด Context ถาวรให้ Directory ใหม่ |
| `sudo restorecon -Rv /data/web/` | ใช้ Context ตามที่กำหนด |
| `getsebool -a \| grep httpd` | ดูค่า Boolean |
| `sudo setsebool -P httpd_can_network_connect on` | เปิด Boolean ถาวร |
| `sudo ausearch -m avc -ts recent` | เหตุการณ์ที่ SELinux ปฏิเสธในช่วงล่าสุด |
| `sudo sealert -a /var/log/audit/audit.log` | อ่านคำอธิบายและวิธีแก้ (ติดตั้ง `setroubleshoot-server` ก่อน) |

ถ้าไม่พบคำสั่ง `semanage` ให้ติดตั้ง `policycoreutils-python-utils`

> ⚠️ `sudo setenforce 0` ปิดการบังคับของ SELinux ชั่วคราวจนกว่าจะ reboot ใช้เพื่อยืนยันว่า SELinux เป็นสาเหตุเท่านั้น แล้วต้อง `sudo setenforce 1` ทันที ห้ามแก้ `/etc/selinux/config` เป็น disabled เพราะการเปิดกลับต้อง relabel ทั้งเครื่อง

## Backup

ตารางที่ ก-17 คำสั่งสำรองและกู้คืน

| คำสั่ง | ใช้ทำอะไร |
|---|---|
| `sudo cp -a ไฟล์ ไฟล์.bak.$(date +%Y%m%d-%H%M)` | สำรองไฟล์ Config ก่อนแก้ทุกครั้ง |
| `sudo mkdir -p /backup && sudo chmod 700 /backup` | เตรียม Directory เก็บ Backup |
| `sudo tar czf /backup/etc-backup-$(date +%Y%m%d).tar.gz /etc` | สำรองทั้ง Directory เป็น tar.gz |
| `sudo tar tzf /backup/ไฟล์.tar.gz \| head` | ดูรายการไฟล์ใน Backup โดยไม่แตก |
| `sudo tar xzf /backup/ไฟล์.tar.gz -C /tmp/restore etc/ssh/sshd_config` | แตกไฟล์เดียวไปที่ปลอดภัยก่อน |
| `diff /tmp/restore/etc/ssh/sshd_config /etc/ssh/sshd_config` | เทียบไฟล์ใน Backup กับไฟล์ปัจจุบัน |
| `sudo /usr/local/bin/backup-configs.sh` | รัน Backup Script ของบทที่ 6 |
| `sudo crontab -l` | ดู Cron Job ของ root |
| `sha256sum ไฟล์.tar.gz` | ค่า SHA256 ฝั่ง server |
| `Get-FileHash ไฟล์.tar.gz -Algorithm SHA256` | ค่า SHA256 ฝั่ง Windows ใน PowerShell ต้องตรงกับ server |
| `sudo install -m 600 -o admin -g admin /backup/ไฟล์ /home/admin/` | คัดลอก Backup ให้ admin ดึงออกไป Host PC ได้ |

> ⚠️ `sudo tar xzf /backup/ไฟล์.tar.gz -C /` เขียนทับไฟล์ในระบบจริงทุกไฟล์ที่อยู่ใน Backup โดยไม่ถาม ให้แตกไปที่ `/tmp/restore` และตรวจด้วย `diff` ก่อน แล้วคืนเฉพาะไฟล์ที่ต้องการ

## VirtualBox ด้วย VBoxManage

คำสั่งหมวดนี้รันบน Host PC ใน Command Prompt หรือ PowerShell ถ้าระบบไม่รู้จัก `VBoxManage` ให้เพิ่ม `C:\Program Files\Oracle\VirtualBox` เข้า PATH หรือเรียกด้วย path เต็ม

ตารางที่ ก-18 คำสั่ง VBoxManage

| คำสั่ง | ใช้ทำอะไร |
|---|---|
| `VBoxManage --version` | รุ่นของ VirtualBox |
| `VBoxManage list vms` | VM ทั้งหมด |
| `VBoxManage list runningvms` | VM ที่เปิดอยู่ |
| `VBoxManage startvm server --type headless` | เปิด VM แบบไม่มีหน้าต่าง แล้วใช้ SSH เข้า |
| `VBoxManage controlvm server acpipowerbutton` | กดปุ่ม Power ให้ OS ปิดตัวเองอย่างปลอดภัย |
| `VBoxManage showvminfo server \| findstr /C:"State:"` | สถานะ VM เปิดหรือปิด |
| `VBoxManage showvminfo server --machinereadable \| findstr /b "nic1= nic2= hostonlyadapter2="` | ตรวจการตั้งค่า Adapter ทั้งสอง |
| `VBoxManage list hostonlyifs` | การ์ด Host-only บน Host PC ต้อง Up และ IP 192.168.56.1 |
| `VBoxManage list dhcpservers` | DHCP ของวง Host-only |
| `VBoxManage snapshot server list` | รายการ Snapshot |
| `VBoxManage snapshot server take "ch04-start"` | ถ่าย Snapshot หลังปิด VM แล้ว |
| `VBoxManage snapshot server take base-10.2 --description "Rocky 10.2 installed + dnf update"` | ถ่าย Snapshot พร้อมคำอธิบาย |
| `VBoxManage clonevm server --snapshot base-10.2 --options link --name client --register` | สร้าง Linked Clone จาก base-10.2 |
| `VBoxManage controlvm server natpf1 "ssh,tcp,127.0.0.1,2222,,2222"` | Port Forwarding ของ NAT ขณะ VM เปิดอยู่ |
| `VBoxManage modifyvm server --natpf1 "ssh,tcp,127.0.0.1,2222,,2222"` | Port Forwarding แบบเดียวกันขณะ VM ปิด |

ลำดับที่ถูกต้องในการถ่าย Snapshot คือปิดเครื่องก่อนเสมอ

```
C:\> VBoxManage controlvm server acpipowerbutton
C:\> VBoxManage showvminfo server | findstr /C:"State:"
C:\> VBoxManage snapshot server take "ch05-start"
```

บรรทัดที่สองต้องแสดง `State: powered off` ก่อนสั่งบรรทัดที่สาม ถ้ายังเป็น running ให้รอสักครู่แล้วตรวจใหม่

> ⚠️ คำสั่งต่อไปนี้ทำให้ข้อมูลหรือสถานะของ VM หายถาวร

- `VBoxManage controlvm server poweroff` เหมือนถอดปลั๊ก ข้อมูลที่ยังไม่ได้เขียนลงดิสก์หาย ใช้เมื่อ VM ค้างเท่านั้น
- `VBoxManage snapshot server restore "ch04-start"` ทิ้งทุกการเปลี่ยนแปลงหลัง Snapshot นั้น
- `VBoxManage snapshot server delete "ชื่อ"` ลบ Snapshot ห้ามลบ `base-10.2` เพราะ Linked Clone ของเล่มอื่นใช้ดิสก์ฐานนี้
- `VBoxManage unregistervm ชื่อ --delete` ลบ VM พร้อมไฟล์ดิสก์
- ห้ามถ่าย Snapshot ขณะ VM เปิดอยู่ ซีรีส์นี้ใช้ Snapshot แบบปิดเครื่องเท่านั้น
