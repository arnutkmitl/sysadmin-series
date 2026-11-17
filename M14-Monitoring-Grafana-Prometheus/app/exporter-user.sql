-- ผู้ใช้สำหรับ mysqld_exporter: อ่านสถานะอย่างเดียว ไม่เห็นข้อมูลในตาราง
CREATE USER IF NOT EXISTS 'exporter'@'localhost' IDENTIFIED BY 'CHANGE-ME' WITH MAX_USER_CONNECTIONS 3;
GRANT PROCESS, REPLICATION CLIENT, SLAVE MONITOR ON *.* TO 'exporter'@'localhost';
GRANT SELECT ON performance_schema.* TO 'exporter'@'localhost';
