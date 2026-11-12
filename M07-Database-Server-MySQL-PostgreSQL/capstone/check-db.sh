#!/bin/bash
# check-db.sh: ตรวจรับโปรเจกต์จบเล่ม Database Server for Web Application
#   sudo ./check-db.sh primary              รันบน db1
#   sudo ./check-db.sh replica              รันบน db2
#   APP_PASSWORD=... ./check-db.sh app      รันบนเครื่องแอป
set -uo pipefail

PRIMARY=192.168.56.40
REPLICA=192.168.56.41
APP_HOST=192.168.56.20
APP_USER=webapp
APP_DB=webshop
BACKUP_DIR=/backup/mariadb
MAX_LAG=30

pass=0; fail=0
check() {   # check "คำอธิบาย" คำสั่ง...
    local desc=$1; shift
    if "$@" >/dev/null 2>&1; then
        printf 'PASS  %s\n' "$desc"; pass=$((pass + 1))
    else
        printf 'FAIL  %s\n' "$desc"; fail=$((fail + 1))
    fi
}
q()  { mariadb -N -B -e "$1"; }                  # query ในเครื่องด้วย root
eq() { [ "$(q "$1")" = "$2" ]; }                 # ผลของ query ต้องเท่ากับค่าที่กำหนด
slave() {   # ค่าหนึ่งช่องจาก SHOW SLAVE STATUS เช่น slave Slave_IO_Running
    mariadb -e "SHOW SLAVE STATUS\G" | awk -F': ' -v k="$1" '{sub(/^ +/, "", $1)} $1 == k {print $2}'
}

restore_test() {   # restore dump ล่าสุดลง database ชั่วคราว แล้วเทียบจำนวนตาราง
    local dump tmp=restore_check_$$ n_src n_tmp
    dump=$(ls -t "$BACKUP_DIR/$APP_DB"-*.sql.gz 2>/dev/null | head -1) || return 1
    [ -n "$dump" ] || return 1
    q "CREATE DATABASE $tmp" || return 1
    zcat "$dump" | mariadb "$tmp"
    n_src=$(q "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$APP_DB'")
    n_tmp=$(q "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$tmp'")
    q "DROP DATABASE $tmp"
    [ "$n_src" -gt 0 ] && [ "$n_src" = "$n_tmp" ]
}

rich_3306_ok() {   # 3306 เปิดเฉพาะเครื่องแอปและ replica เท่านั้น
    local rules
    rules=$(firewall-cmd --list-rich-rules | grep 'port="3306"')
    echo "$rules" | grep -q "$APP_HOST\"" &&
    echo "$rules" | grep -q "$REPLICA\"" &&
    [ "$(echo "$rules" | grep -vc -e "$APP_HOST\"" -e "$REPLICA\"")" -eq 0 ]
}

case "${1:-}" in
primary)
    check "mariadb ทำงานและเปิดเองตอนบูต" systemctl is-enabled --quiet mariadb
    check "mariadb active" systemctl is-active --quiet mariadb
    check "bind-address เป็น $PRIMARY" eq "SELECT @@bind_address" "$PRIMARY"
    check "firewall ไม่เปิด 3306 ให้ทุกคน" bash -c "! firewall-cmd --list-ports | grep -q 3306 && ! firewall-cmd --list-services | grep -qw mysql"
    check "rich rule 3306 เฉพาะ $APP_HOST และ $REPLICA" rich_3306_ok
    check "root เข้าได้จาก localhost เท่านั้น" eq "SELECT COUNT(*) FROM mysql.user WHERE User='root' AND Host<>'localhost'" 0
    check "ไม่มี anonymous user" eq "SELECT COUNT(*) FROM mysql.user WHERE User=''" 0
    check "ไม่มีบัญชีที่ Host เป็น %" eq "SELECT COUNT(*) FROM mysql.user WHERE Host='%'" 0
    check "$APP_USER ต้องใช้ TLS" eq "SELECT ssl_type FROM mysql.user WHERE User='$APP_USER' AND Host='$APP_HOST'" ANY
    check "$APP_USER ไม่มีสิทธิ์ระดับ server" eq "SELECT GROUP_CONCAT(PRIVILEGE_TYPE) FROM information_schema.USER_PRIVILEGES WHERE GRANTEE=\"'$APP_USER'@'$APP_HOST'\"" USAGE
    check "TLS พร้อมใช้งาน" eq "SELECT @@have_ssl" YES
    check "เปิด binary log" eq "SELECT @@log_bin" 1
    check "ตั้งอายุ binary log" bash -c "[ \"\$(mariadb -N -e 'SELECT @@binlog_expire_logs_seconds')\" -gt 0 ]"
    check "replica $REPLICA ต่ออยู่" bash -c "mariadb -N -e 'SHOW PROCESSLIST' | grep 'Binlog Dump' | grep -q '$REPLICA'"
    check "มี backup รายวันอายุไม่เกิน 26 ชั่วโมง" bash -c "find $BACKUP_DIR -name '$APP_DB-*.sql.gz' -mmin -1560 | grep -q ."
    check "backup รายวันล่าสุด restore ได้" restore_test
    check "มี full backup ที่ prepare แล้ว" bash -c "grep -qs 'backup_type = log-applied' \$(ls -td $BACKUP_DIR/full-*/ | head -1)mariadb_backup_checkpoints"
    check "cron ของ backup ทั้งสองแบบ" bash -c "grep -qs backup-mariadb.sh /etc/cron.d/backup-mariadb && grep -qs backup-mariadb-full.sh /etc/cron.d/backup-mariadb"
    ;;
replica)
    check "mariadb active" systemctl is-active --quiet mariadb
    check "Slave_IO_Running = Yes" test "$(slave Slave_IO_Running)" = Yes
    check "Slave_SQL_Running = Yes" test "$(slave Slave_SQL_Running)" = Yes
    lag=$(slave Seconds_Behind_Master)
    check "ตามหลัง primary ไม่เกิน $MAX_LAG วินาที" bash -c "[ '$lag' != NULL ] && [ '$lag' -le $MAX_LAG ]"
    check "read_only = ON" eq "SELECT @@read_only" 1
    check "server_id ไม่ซ้ำกับ primary" bash -c "[ \"\$(mariadb -N -e 'SELECT @@server_id')\" != 1 ]"
    check "replication ใช้ TLS" test "$(slave Master_SSL_Allowed)" = Yes
    check "มี database $APP_DB บน replica" eq "SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name='$APP_DB'" 1
    ;;
app)
    : "${APP_PASSWORD:?ตั้ง APP_PASSWORD ก่อนรัน}"
    a() { mariadb -h "$PRIMARY" -u "$APP_USER" -p"$APP_PASSWORD" -N -B "$APP_DB" -e "$1"; }
    check "เชื่อมต่อ $PRIMARY ด้วย TLS" bash -c "mariadb -h $PRIMARY -u $APP_USER -p\"\$APP_PASSWORD\" -N -e \"SHOW SESSION STATUS LIKE 'Ssl_cipher'\" | grep -q TLS"
    check "SELECT ได้" a "SELECT COUNT(*) FROM orders"
    check "INSERT และ DELETE ได้" a "INSERT INTO orders (customer, total) VALUES ('check-db', 1); DELETE FROM orders WHERE customer='check-db'"
    check "DROP TABLE ไม่ได้" bash -c "! mariadb -h $PRIMARY -u $APP_USER -p\"\$APP_PASSWORD\" $APP_DB -e 'DROP TABLE orders'"
    check "เชื่อมต่อแบบไม่เข้ารหัสไม่ได้" bash -c "! mariadb -h $PRIMARY -u $APP_USER -p\"\$APP_PASSWORD\" --skip-ssl -e 'SELECT 1'"
    ;;
*)
    echo "ใช้: $0 primary|replica|app" >&2; exit 2 ;;
esac

echo "----"
echo "ผ่าน $pass จาก $((pass + fail)) ข้อ"
[ "$fail" -eq 0 ]
