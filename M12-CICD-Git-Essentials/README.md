# ไฟล์ประกอบหนังสือ CI/CD & Git Essentials: Deploy อัตโนมัติใน 1 วัน

SysAdmin Pocket Series M12 โดย ดร.อาณัติ รัตนถิรกุล (อ.หมวกแดง) สำนักพิมพ์ SysAdmin Knowledge Press
ดาวน์โหลดได้ที่ https://github.com/arnutkmitl/sysadmin-series โฟลเดอร์ `M12-CICD-Git-Essentials`

## โฟลเดอร์

| โฟลเดอร์ | เนื้อหา |
|---|---|
| `m12-lab/app/` | แอปตัวอย่างตามหัวข้อ 1.3: index.html, Dockerfile และ tests/test.sh |
| `m12-lab/.github/workflows/` | workflow ของบทที่ 2 และ 4: hello, pipeline, deploy, site, ansible, backup, matrix, secret-scan |
| `m12-lab/.gitlab-ci.yml` | pipeline ของ GitLab ตามหัวข้อ 3.5 |
| `m12-lab/deploy/compose.yaml` | ไฟล์ Compose ที่ pipeline คัดลอกไปไว้ที่ /srv/m12-app บน stg และ prod |
| `m12-lab/ansible/` | inventory.ini และ check.yml ของหัวข้อ 2.5 |
| `capstone/check-cicd.sh` | ตรวจโปรเจกต์จบเล่ม 15 ข้อจากเครื่อง ci (หัวข้อ 5.2) |
| `commands/chNN.sh` | คำสั่งที่พิมพ์ใน terminal ของแต่ละบท รวม 315 คำสั่ง ไม่ใช่สคริปต์ ให้คัดลอกทีละคำสั่ง |

## ก่อนใช้งาน

- โฟลเดอร์ m12-lab คือหน้าตาของ repository เมื่อทำครบทั้งเล่ม ยกเว้น app/ ซึ่งเป็นรุ่นเริ่มต้นของหัวข้อ 1.3 ระหว่างอ่านให้สร้างไฟล์ตามลำดับในเล่ม เพราะแต่ละบทอธิบายทีละไฟล์
- workflow และ .gitlab-ci.yml ใช้ IP และชื่อเครื่องของ Lab ในเล่ม (registry 192.168.56.30:5000, stg.lab.test, prod.lab.test) แก้ให้ตรงกับเครื่องของคุณก่อนใช้
- secret และ CI/CD variables ต้องสร้างเองตามหัวข้อ 2.4 และ 3.4 ชุดนี้ไม่มี private key, token หรือรหัสผ่านของเครื่องทดสอบ
- secret-scan.yml มีรูปแบบของ secret อยู่ในไฟล์ pre-commit hook จากหัวข้อ 1.8 จะไม่ยอมให้ commit ไฟล์นี้ ให้ commit ด้วย --no-verify ตามหัวข้อ 4.2

ทดสอบบน Rocky Linux 10.2, Docker 29.9.3, GitHub Actions (self-hosted runner บน ci), GitLab CE 19.5.4 และ GitLab Runner 19.5.3 เมื่อ 14-15 พฤศจิกายน 2569
