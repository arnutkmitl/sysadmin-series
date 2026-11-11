# Script และคำสั่งประกอบหนังสือ Python for SysAdmin

SysAdmin Pocket Series M04 โดย ดร.อาณัติ รัตนถิรกุล (อ.หมวกแดง) สำนักพิมพ์ SysAdmin Knowledge Press
ดาวน์โหลดได้ที่ https://github.com/arnutkmitl/sysadmin-series โฟลเดอร์ `M04-Python-for-SysAdmin`

## โฟลเดอร์

| โฟลเดอร์ | เนื้อหา |
|---|---|
| `production/` | Python Admin Toolkit จากบทที่ 6 และ 7: `scripts/` (adminlib.py, notify.py และ Script สำเร็จรูป 5 ตัว), `configs/`, acceptance.py, ruff.toml, requirements.txt และ crontab.txt |
| `labs/chNN/` | Script และไฟล์ YAML ของ Lab แต่ละบท รวม 14 ไฟล์ |
| `commands/chNN.sh` | คำสั่งที่พิมพ์ใน terminal ของแต่ละบท รวม 54 คำสั่ง ไฟล์เหล่านี้ไม่ใช่สคริปต์ ให้คัดลอกทีละคำสั่ง |
| `snippets/chNN.py` | ตัวอย่างที่พิมพ์ใน Python interactive (>>>) รวม 22 ชุด ตัด prompt และผลลัพธ์ออกแล้ว |

## ติดตั้งชุด production

```
mkdir -p ~/python-admin/{scripts,configs,logs,reports}
cp production/scripts/*.py ~/python-admin/scripts/
cp production/configs/*.yaml production/ruff.toml production/requirements.txt ~/python-admin/
mv ~/python-admin/*.yaml ~/python-admin/configs/
python3 -m venv ~/python-admin/.venv
~/python-admin/.venv/bin/pip install -r ~/python-admin/requirements.txt
cp ~/python-admin/configs/alert-config.example.yaml ~/python-admin/configs/alert-config.yaml
chmod 600 ~/python-admin/configs/alert-config.yaml
```

แก้ servers.yaml, endpoints.yaml, monitor-config.yaml และ alert-config.yaml ให้ตรงกับเครื่องก่อนรัน
แล้วตั้ง cron ตาม crontab.txt บน Ubuntu ต้องติดตั้ง python3-venv ก่อน และเปลี่ยนชื่อ service ใน
monitor-config.yaml เป็น ssh, cron, chrony ตามบทที่ 6

## ก่อนใช้งาน

- อย่า commit alert-config.yaml ที่มี token จริงเข้า Git และอย่าใช้ sudo pip install
- ทดสอบบน VM ที่ถ่าย snapshot ไว้ก่อนใช้กับ server จริง
- อ่านคำเตือน ⚠️ ในเล่มก่อนรัน Script ที่ลบไฟล์หรือ restart service (py-backup.py, watchdog.py)

ทดสอบบน Rocky Linux 10.2 (Python 3.12) และ Ubuntu 26.04 (Python 3.14) เมื่อ 11 พฤศจิกายน 2569
