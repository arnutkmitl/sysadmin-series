# ไฟล์ประกอบหนังสือ Monitoring with Grafana & Prometheus

SysAdmin Pocket Series M14 โดย ดร.อาณัติ รัตนถิรกุล (อ.หมวกแดง) สำนักพิมพ์ SysAdmin Knowledge Press
ดาวน์โหลดได้ที่ https://github.com/arnutkmitl/sysadmin-series โฟลเดอร์ `M14-Monitoring-Grafana-Prometheus`

## โฟลเดอร์

| โฟลเดอร์ | เนื้อหา |
|---|---|
| `monitoring/` | โฟลเดอร์ ~/monitoring ของเครื่อง mon ฉบับจบเล่ม: docker-compose.yml, prometheus/, alertmanager/, grafana/ (Dashboard 5 ชุด), blackbox/, pushgateway/, line-bridge/, lab-mock-api/ และ check-monitoring.sh |
| `app/` | ไฟล์ของเครื่อง app: unit ของ node_exporter, nginx_exporter, mysqld_exporter, stub_status.conf, exporter-user.sql, แอป shop และ backup-with-metrics.sh |
| `commands/chNN.sh` | คำสั่งที่พิมพ์ใน terminal ของแต่ละบท รวม 205 คำสั่ง ไม่ใช่สคริปต์ ให้คัดลอกทีละคำสั่ง |

## เริ่มใช้

```
cd monitoring
cp .env.example .env                 # ใส่ User ID ของ LINE
mkdir -m 700 secrets                 # สร้างไฟล์ตาม secrets/README.md
docker compose up -d                 # ใช้ Token จริง
docker compose -f docker-compose.yml -f lab-mock-api/docker-compose.lab.yml up -d   # ทดสอบด้วยปลายทางจำลอง
./check-monitoring.sh                # ตรวจสุขภาพทั้ง stack
python3 make_dashboards.py           # สร้าง Dashboard JSON ใหม่หลังแก้ Query
```

## ก่อนใช้งาน

- เปลี่ยน IP 192.168.56.55 (mon) และ 192.168.56.56 (app) ให้ตรงกับเครื่องของคุณ ใน prometheus.yml, docker-compose.yml, backup-with-metrics.sh และ alertmanager.yml
- แก้ chat_id 123456789 ใน alertmanager.yml เป็น chat_id ของคุณ
- ชุดนี้ไม่มีรหัสผ่าน Token และ bcrypt hash ใด ๆ ให้สร้างใหม่ตาม secrets/README.md
- หลังสร้าง volume pushgateway-data ครั้งแรก ให้เปลี่ยนเจ้าของเป็น 65534 ตามหัวข้อ 6.2 ไม่เช่นนั้นผล backup หายทุกครั้งที่ Restart
- alertmanager.lab.yml และ lab-mock-api/ ใช้ใน Lab เท่านั้น
- อ่านคำเตือน ⚠️ ในเล่มก่อนรันคำสั่งที่หยุดบริการหรือ `docker compose down -v`

ทดสอบบน Rocky Linux 10.2 กับ Docker CE 29.10.0, Compose v5.7.1, Prometheus 3.16.0, Alertmanager 0.35.0, Grafana 13.3.1,
node_exporter 1.12.1, cAdvisor 0.61.0, nginx-prometheus-exporter 1.5.3, mysqld_exporter 0.21.0, blackbox_exporter 0.29.1,
Pushgateway 1.11.4 และ prometheus_client 0.26.0 เมื่อ 17 พฤศจิกายน 2569
