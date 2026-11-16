#!/bin/bash
# handover-check.sh  ตรวจ server ตาม Series Baseline ของ M01 ก่อนส่งมอบ
# ใช้: sudo /usr/local/bin/handover-check.sh   (exit code = จำนวนข้อที่ FAIL)

if [ "$(id -u)" -ne 0 ]; then
    echo "ต้องรันด้วย sudo" >&2
    exit 255
fi

N=0
FAIL=0
SSHD=$(sshd -T 2>/dev/null)

# check "คำอธิบาย" 'คำสั่งตรวจ'  คำสั่งตรวจคืนค่า 0 = PASS
check() {
    N=$((N + 1))
    if eval "$2" > /dev/null 2>&1; then
        printf '[%02d] PASS  %s\n' "$N" "$1"
    else
        printf '[%02d] FAIL  %s\n' "$N" "$1"
        FAIL=$((FAIL + 1))
    fi
}

# sshd_is "port 2222"  ค่าที่ sshd ใช้จริงของคีย์นั้นต้องมีบรรทัดเดียวและตรงทุกตัวอักษร
sshd_is() { [ "$(printf '%s\n' "$SSHD" | grep "^${1%% *} ")" = "$1" ]; }

# sorted  เรียงคำในบรรทัด เพื่อเทียบรายการโดยไม่สนลำดับ
sorted() { tr ' ' '\n' | sed '/^$/d' | sort | xargs; }

echo "=== M01 Handover Check: $(hostname) $(date '+%F %T') ==="
echo "--- ระบบและเครือข่าย"
check "Rocky Linux 10.2"               'grep -q "release 10.2" /etc/rocky-release'
check "hostname server.lab.local"      '[ "$(hostname)" = "server.lab.local" ]'
check "enp0s8 = 192.168.56.10/24"      'ip -4 -o addr show enp0s8 | grep -q "inet 192.168.56.10/24"'
check "default route via enp0s3 only"  '[ "$(ip route show default | wc -l)" -eq 1 ] && ip route show default | grep -q "dev enp0s3"'
check "no pending updates"             'dnf -q check-update'
check "no reboot required"             'dnf needs-restarting -r'
echo "--- ผู้ใช้"
check "admin in wheel"                 'id -nG admin | grep -qw wheel'
check "root password locked"           'getent shadow root | cut -d: -f2 | grep -q "^[!*]"'
check "admin authorized_keys 600"      '[ -s /home/admin/.ssh/authorized_keys ] && [ "$(stat -c %a /home/admin/.ssh/authorized_keys)" = 600 ]'
echo "--- SSH"
check "sshd port 2222 only"            'sshd_is "port 2222"'
check "PasswordAuthentication no"      'sshd_is "passwordauthentication no"'
check "PermitRootLogin no"             'sshd_is "permitrootlogin no"'
check "AllowUsers admin"               'sshd_is "allowusers admin"'
check "MaxAuthTries 3"                 'sshd_is "maxauthtries 3"'
check "sshd listening on 2222"         'ss -Htln "sport = :2222" | grep -q LISTEN'
echo "--- Firewall และ SELinux"
check "firewalld active"               'systemctl is-active firewalld'
check "ports = 2222/tcp (runtime+perm)" '[ "$(firewall-cmd --list-ports)" = "2222/tcp" ] && [ "$(firewall-cmd --permanent --list-ports)" = "2222/tcp" ]'
check "services = http https"          '[ "$(firewall-cmd --list-services | sorted)" = "http https" ] && [ "$(firewall-cmd --permanent --list-services | sorted)" = "http https" ]'
check "SELinux Enforcing (now+boot)"   '[ "$(getenforce)" = "Enforcing" ] && grep -qx "SELINUX=enforcing" /etc/selinux/config'
check "ssh_port_t includes 2222"       'semanage port -l | grep "^ssh_port_t" | grep -qw 2222'
echo "--- Update และ Backup"
check "dnf-automatic-install.timer"    'systemctl is-enabled dnf-automatic-install.timer && systemctl is-active dnf-automatic-install.timer'
check "crond + backup job"             'systemctl is-active crond && { grep -qs "backup-configs.sh" /etc/cron.d/backup-configs || crontab -l | grep -q "backup-configs.sh"; }'
check "/backup mode 700"               '[ "$(stat -c %a /backup)" = 700 ]'
check "backup < 24h with sshd config"  'f=$(find /backup -maxdepth 1 -name "server-config-*.tar.gz" -mmin -1440 | sort | tail -1); [ -n "$f" ] && tar tzf "$f" | grep -q "etc/ssh/sshd_config.d/10-hardening.conf"'
echo "==="
if [ "$FAIL" -eq 0 ]; then
    echo "RESULT: PASS $N/$N พร้อมถ่าย snapshot m01-done"
else
    echo "RESULT: FAIL $FAIL จาก $N ข้อ แก้ข้อที่ FAIL แล้วรันใหม่"
fi
exit "$FAIL"
