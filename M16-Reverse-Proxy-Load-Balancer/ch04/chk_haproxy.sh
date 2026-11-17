#!/bin/sh
# /usr/libexec/keepalived/chk_haproxy.sh
# keepalived เรียกทุก 2 วินาที: ออกด้วย 0 เมื่อ HAProxy ทำงาน ไม่ใช่ 0 เมื่อหยุด
# ต้องอยู่ใน /usr/libexec/keepalived ซึ่ง SELinux ให้ป้าย keepalived_unconfined_script_exec_t
exec /usr/bin/systemctl is-active --quiet haproxy
