#!/usr/bin/env bash
# บทที่ 4 Virtual Lab สำหรับการสอน
# SysAdmin Pocket Series M11 Proxmox VE: สร้าง Virtual Lab ใน 1 วัน
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# บรรทัดที่มี [PowerShell] รันใน PowerShell ของ Windows, [Git Bash] รันใน Git Bash, ที่เหลือรันบน pve ในนาม root
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 4.1 รูปแบบของ Lab ───────────────────────────────────────
for i in 1 2; do
  id=$((300+i))
  pct clone 200 $id --hostname stu0$i
  pct set $id -net0 name=eth0,bridge=vmbr1,ip=10.10.10.$((100+i))/24,gw=10.10.10.1
done

# ── 4.2 pool รวมเครื่องของ Lab ──────────────────────────────
pvesh create /pools --poolid class101 --comment "Linux Admin 101"
pvesh set /pools/class101 --vms 301,302
pvesh get /pools/class101 --output-format json-pretty | grep -E '"(id|type|vmid)"'

# ── 4.3 ผู้ใช้และสิทธิ์รายเครื่อง ───────────────────────────
pveum user add student01@pve --comment "Student 01"
pveum user add student02@pve --comment "Student 02"
pveum passwd student01@pve
pveum passwd student02@pve
pveum acl modify /vms/301 --users student01@pve --roles PVEVMUser
pveum acl modify /vms/302 --users student02@pve --roles PVEVMUser
pveum acl list

# ── ทดสอบในนามผู้เรียน ──────────────────────────────────────
# [Git Bash]
A=https://192.168.56.60:8006/api2/json
# [Git Bash]
R=$(curl -sk -d username=student01@pve --data-urlencode "password=$P1" $A/access/ticket)
# [Git Bash]
T=$(echo "$R" | python -c "import sys,json;print(json.load(sys.stdin)['data']['ticket'])")
# [Git Bash]
C=$(echo "$R" | python -c "import sys,json;print(json.load(sys.stdin)['data']['CSRFPreventionToken'])")
# [Git Bash]
curl -sk -b "PVEAuthCookie=$T" "$A/cluster/resources?type=vm"
# [Git Bash]
curl -sk -b "PVEAuthCookie=$T" -H "CSRFPreventionToken: $C" -X POST $A/nodes/pve/lxc/301/status/start
# [Git Bash]
curl -sk -b "PVEAuthCookie=$T" -H "CSRFPreventionToken: $C" -X POST $A/nodes/pve/lxc/302/status/start
# [Git Bash]
curl -sk -b "PVEAuthCookie=$T" -H "CSRFPreventionToken: $C" -X DELETE $A/nodes/pve/lxc/301

# ── 4.4 จำกัดทรัพยากรและเฝ้าดูพื้นที่ ───────────────────────
pct set 301 --cpulimit 0.5 --memory 256 --swap 0
pct exec 301 -- free -m | sed -n 2p

# ── overcommit ของดิสก์ ─────────────────────────────────────
pct snapshot 301 lab-clean
lvs -o lv_name,lv_size,data_percent,metadata_percent pve/data
systemctl is-active ksmtuned; cat /sys/kernel/mm/ksm/run

# ── 4.5 reset Lab ด้วยคำสั่งเดียว ───────────────────────────
for id in 301 302; do pct snapshot $id lab-clean --description "clean state for class101"; done
pct listsnapshot 301
pct exec 301 -- bash -c 'dnf remove -y nginx; echo broken > /root/student-work.txt'
pct exec 301 -- rpm -q nginx
chmod 755 /usr/local/sbin/reset-lab.sh
reset-lab.sh class101
pct exec 301 -- rpm -q nginx
pct exec 301 -- cat /root/student-work.txt
pvesh set /pools/class101 --vms 101
qm snapshot 101 lab-clean --description "clean state for class101"
reset-lab.sh class101 2>&1 | grep -v 'Logical volume'
