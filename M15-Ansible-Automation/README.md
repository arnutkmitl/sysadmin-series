# ไฟล์ประกอบหนังสือ Ansible Automation

SysAdmin Pocket Series M15 โดย ดร.อาณัติ รัตนถิรกุล (อ.หมวกแดง) สำนักพิมพ์ SysAdmin Knowledge Press
ดาวน์โหลดได้ที่ https://github.com/arnutkmitl/sysadmin-series โฟลเดอร์ `M15-Ansible-Automation`

## โฟลเดอร์

| โฟลเดอร์ | เนื้อหา |
|---|---|
| `ansible-lab/` | โปรเจกต์ ~/ansible-lab ของเครื่อง ctl ฉบับจบเล่ม: ansible.cfg, inventory.yml, group_vars, host_vars, roles/common, playbooks (รวม ready/01-08), site.yml, semaphore.yml, .ansible-lint และปลายทางจำลองของ LINE |
| `ch00/` | bootstrap-ansible-user.sh สร้างผู้ใช้ ansible บนทุกเครื่อง |
| `extras/` | semaphore_setup.py สร้าง Project, Key Store, Inventory และ Template ใน Semaphore ผ่าน API (บทที่ 6) |
| `commands/chNN.sh` | คำสั่งที่พิมพ์ใน terminal ของแต่ละบท รวม 185 คำสั่ง ไม่ใช่สคริปต์ ให้คัดลอกทีละคำสั่ง |

## เริ่มใช้

```
cp -r ansible-lab ~/ansible-lab && cd ~/ansible-lab
ansible-galaxy install -r requirements.yml            # collection และ Role ตามรุ่นที่ตรึงไว้
ansible-vault encrypt group_vars/dbservers/vault.yml   # หลังแก้ค่า CHANGE_ME
ansible-vault encrypt group_vars/dockerhosts/vault.yml
ansible-playbook site.yml --check                      # ดูก่อนว่าจะเปลี่ยนอะไร
ansible-playbook site.yml
```

## ก่อนใช้งาน

- เปลี่ยน IP 192.168.56.65 ถึง .68 และ .82 ใน inventory.yml และ group_vars/dbservers/vars.yml ให้ตรงกับเครื่องของคุณ
- ไฟล์ vault.yml ทั้งสองไฟล์เป็นตัวอย่างที่ยังไม่เข้ารหัส แก้ค่า CHANGE_ME แล้วเข้ารหัสก่อน commit เสมอ และตั้ง vault_password_file ใน ansible.cfg ให้ชี้ไปที่ไฟล์รหัสผ่านของคุณ
- common_admin_key ใน group_vars/all.yml ปิดไว้ ให้เปิดและใส่ public key ของคุณเมื่อรันผ่าน Semaphore
- lab-mock/line_mock.py และ vault_line_token ค่าตัวอย่างใช้ใน Lab เท่านั้น
- อ่านคำเตือน ⚠️ ในเล่มก่อนรัน Playbook #8 (Reboot) และคำสั่งที่ทำ drift ในบทที่ 6

ทดสอบด้วย ansible-core 2.16.19 บน Rocky Linux 10.2 กับเครื่องปลายทาง Rocky Linux 10.2 และ Ubuntu Server 26.04
พร้อม ansible.posix 2.2.2, community.general 11.4.10, community.docker 4.8.9, ansible.mariadb 6.0.3,
community.crypto 2.26.9, geerlingguy.docker 8.0.1, ansible-lint 26.11.0 และ Semaphore UI v2.20.24 เมื่อ 17 พฤศจิกายน 2569
