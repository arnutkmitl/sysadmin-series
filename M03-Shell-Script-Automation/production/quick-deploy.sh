#!/usr/bin/env bash
# quick-deploy.sh  ดึงโค้ดจาก Git, build, restart service, ตรวจสุขภาพ และย้อนกลับถ้าพัง
# ใช้: sudo ./quick-deploy.sh staging   หรือ   sudo ./quick-deploy.sh production
# ---- ตัวแปรที่ต้องแก้ ----
case ${1:-} in
  staging)    APP_DIR=/opt/myapp-staging; BRANCH=develop; SERVICE=myapp-staging
              HEALTH_URL=http://127.0.0.1:8081/health ;;
  production) APP_DIR=/opt/myapp;         BRANCH=main;    SERVICE=myapp
              HEALTH_URL=http://127.0.0.1:8080/health ;;
  *)          echo "Usage: $0 staging|production"; exit 2 ;;
esac
BUILD_CMD=""                               # เช่น "npm ci && npm run build" ว่าง = ไม่ build
# shellcheck source=/usr/local/lib/sysadmin/lib.sh
source /usr/local/lib/sysadmin/lib.sh
need_root; lock; need_cmd git curl

healthy() {
  for _ in 1 2 3 4 5; do
    curl -fs -o /dev/null --max-time 3 "$HEALTH_URL" && return 0
    sleep 2
  done
  return 1
}

old=$(git -C "$APP_DIR" rev-parse --short HEAD)
git -C "$APP_DIR" fetch --quiet origin
git -C "$APP_DIR" checkout --quiet "$BRANCH"
git -C "$APP_DIR" merge --ff-only --quiet "origin/$BRANCH"
new=$(git -C "$APP_DIR" rev-parse --short HEAD)
if [[ $old == "$new" ]]; then ok "$1 เป็นรุ่นล่าสุดอยู่แล้ว ($new)"; exit 0; fi
log "deploy $1: $old -> $new"

if [[ -n $BUILD_CMD ]]; then
  (cd "$APP_DIR" && bash -c "$BUILD_CMD") >> "$LOG_FILE" 2>&1 || die "build ล้ม"
fi
systemctl restart "$SERVICE"
if healthy; then ok "deploy $1 สำเร็จ รุ่น $new"; exit 0; fi

warn "health check ไม่ผ่าน ย้อนกลับไปรุ่น $old"
git -C "$APP_DIR" reset --hard --quiet "$old"
systemctl restart "$SERVICE"
if healthy; then die "ย้อนกลับเป็น $old แล้ว รุ่น $new ใช้ไม่ได้"; fi
die "ย้อนกลับแล้วแต่ยังไม่ผ่าน health check ต้องแก้ด้วยมือ"
