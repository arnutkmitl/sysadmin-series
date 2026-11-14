# ไฟล์ประกอบหนังสือ Proxmox VE: สร้าง Virtual Lab ใน 1 วัน

SysAdmin Pocket Series M11 โดย ดร.อาณัติ รัตนถิรกุล (อ.หมวกแดง) สำนักพิมพ์ SysAdmin Knowledge Press
ดาวน์โหลดได้ที่ https://github.com/arnutkmitl/sysadmin-series โฟลเดอร์ `M11-Proxmox-VE-Virtualization`

## โฟลเดอร์

| โฟลเดอร์ | เนื้อหา |
|---|---|
| `scripts/build-lab.sh` | สร้าง Lab หนึ่งห้อง: pool, VM ของผู้เรียนจาก template, ผู้ใช้, สิทธิ์, snapshot และ backup ทุกคืน (หัวข้อ 5.3) |
| `scripts/check-lab.sh` | ตรวจ Lab ว่าทุกเครื่องมี snapshot และเจ้าของ มี backup job และ thin pool ไม่เกิน 80% (หัวข้อ 5.4) |
| `scripts/reset-lab.sh` | คืนทุกเครื่องใน pool กลับ snapshot lab-clean (หัวข้อ 4.5) |
| `scripts/remove-lab.sh` | ลบ Lab ทั้งชุด (หัวข้อ 5.5) |
| `configs/dnsmasq-lab.conf` | DNS ของวง Lab ใน container infra (หัวข้อ 5.2) |
| `configs/pve-interfaces` | /etc/network/interfaces ของ pve หลังบทที่ 3: vmbr0, vmbr1 และ NAT ของทั้งสองวง |
| `commands/chNN.sh` | คำสั่งที่พิมพ์ใน terminal ของแต่ละบท รวม 171 คำสั่ง ไม่ใช่สคริปต์ ให้คัดลอกทีละคำสั่ง |

## เริ่มใช้

คัดลอก scripts/*.sh ไปไว้ที่ /usr/local/sbin บน Proxmox แล้ว `chmod 755` จากนั้น

```
build-lab.sh linux101 9000 10 401 111    # ผู้เรียน 10 คนจาก template 9000
check-lab.sh linux101
reset-lab.sh linux101                    # ⚠️ งานของผู้เรียนหลัง snapshot หายทั้งหมด
remove-lab.sh linux101                   # ⚠️ ลบเครื่องของผู้เรียนทิ้งถาวร
```

## ก่อนใช้งาน

- script ทั้งหมดรันบน Proxmox VE ในนาม root ต้องมี template แบบ Cloud-Init ตามบทที่ 2 และ vmbr1 วง 10.10.10.0/24 ตามบทที่ 1
- build-lab.sh เขียนรหัสผ่านของผู้เรียนลง /root/<pool>-accounts.csv แจกเสร็จแล้วให้ลบไฟล์
- pve-interfaces ใช้ชื่อการ์ด nic0/nic1 และ IP ของ Lab ในเล่ม แก้ให้ตรงกับเครื่องของคุณก่อนใช้
- ชุดนี้ไม่มี private key หรือรหัสผ่านของเครื่องทดสอบ

ทดสอบบน Proxmox VE 9.2 (pve-manager 9.2.26, kernel 7.0.14-28-pve) ใน VirtualBox 7.2.6 เมื่อ 14 พฤศจิกายน 2569
เครื่องทดสอบไม่มี KVM ส่วนที่ต้อง boot VM ในบทที่ 2 และ 5 จึงทดสอบไม่ครบ ดูกรอบเตือนต้นบทที่ 2
