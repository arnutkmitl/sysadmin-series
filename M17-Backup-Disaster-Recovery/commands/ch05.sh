#!/usr/bin/env bash
# บทที่ 5 อัตโนมัติ แจ้งเตือน และตรวจสุขภาพ backup
# SysAdmin Pocket Series M17 Backup & Disaster Recovery
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 5.1 systemd timer แทน cron ──────────────────────────────
# บนเครื่อง prod
sudo install -m 750 backup-and-notify.sh /usr/local/sbin/
sudo install -m 644 backup.service backup.timer /etc/systemd/system/
sudo systemctl daemon-reload && sudo systemctl enable --now backup.timer
systemctl list-timers backup.timer --no-pager | head -2

# ── สามรอบแรกล้มเหลวคนละสาเหตุ ──────────────────────────────
# บนเครื่อง prod
sudo systemctl start backup.service
sudo grep -A2 "restic_rest$" /var/log/backup/backup-2026-11-18.log
sudo systemctl start backup.service; systemctl show backup.service -p Result
sudo grep "^===.*exit" /var/log/backup/backup-2026-11-18.log | tail -5

# ── timeout ของแต่ละงาน ─────────────────────────────────────
# บนเครื่อง prod
systemctl show backup.service -p ExecMainStartTimestamp -p ExecMainExitTimestamp

# ── 5.2 แจ้งผลทาง LINE ──────────────────────────────────────
# บนเครื่อง bkp
sudo install -m 755 line_mock.py /usr/local/bin/ && sudo install -m 644 line-mock.service /etc/systemd/system/
sudo systemctl daemon-reload && sudo systemctl enable --now line-mock
sudo firewall-cmd --permanent --add-rich-rule='rule family=ipv4 source address=192.168.56.85 port port=8099 protocol=tcp accept' && sudo firewall-cmd --reload
# บนเครื่อง prod
sudo bash -c 'umask 077; echo U0123456789abcdef0123456789abcdef > /root/.line-target; echo lab-channel-token > /root/.line-token'
# บนเครื่อง bkp
sudo tail -2 /var/log/line-mock.log

# ── 5.3 metric และ Alert ด้วย Prometheus ────────────────────
# บนเครื่อง prod
V=1.12.1; curl -sSLO https://github.com/prometheus/node_exporter/releases/download/v$V/node_exporter-$V.linux-amd64.tar.gz
curl -sSL https://github.com/prometheus/node_exporter/releases/download/v$V/sha256sums.txt | grep linux-amd64.tar.gz | sha256sum -c
tar xzf node_exporter-$V.linux-amd64.tar.gz && sudo install -m 755 node_exporter-$V.linux-amd64/node_exporter /usr/local/bin/
sudo useradd --system --shell /sbin/nologin node_exporter
sudo install -d -m 755 /var/lib/node_exporter/textfile
sudo install -m 644 node_exporter.service /etc/systemd/system/ && sudo systemctl daemon-reload && sudo systemctl enable --now node_exporter
sudo firewall-cmd --permanent --add-rich-rule='rule family=ipv4 source address=192.168.56.86 port port=9100 protocol=tcp accept' && sudo firewall-cmd --reload
curl -s localhost:9100/metrics | grep ^backup_last_status

# ── Prometheus และ Grafana บน bkp ───────────────────────────
# บนเครื่อง bkp
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
sudo dnf -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin && sudo systemctl enable --now docker
sudo tar -C /opt -xf monitoring.tar
sudo bash -c 'umask 077; printf %s "รหัสผ่านของคุณ" > /opt/monitoring/grafana_admin.txt' && sudo chmod 644 /opt/monitoring/grafana_admin.txt
sudo docker compose --project-directory /opt/monitoring up -d
curl -s localhost:9090/api/v1/targets | python3 -c 'import sys,json;[print(t["labels"]["job"],t["health"]) for t in json.load(sys.stdin)["data"]["activeTargets"]]'
# PowerShell บนเครื่อง Windows
VBoxManage controlvm m17bkp acpipowerbutton
VBoxManage modifyvm m17bkp --memory 2560
VBoxManage startvm m17bkp --type headless
# บนเครื่อง bkp
for s in rest-server seaweedfs line-mock; do printf "%-12s %s\n" $s $(systemctl is-active $s); done
# บนเครื่อง prod
sudo cp -a /root/.restic-rest-pass /root/.restic-rest-pass.good
echo wrong-password | sudo tee /root/.restic-rest-pass >/dev/null
time sudo systemctl start backup.service
sudo grep -A2 "restic_rest$" /var/log/backup/backup-2026-11-18.log | tail -3
# บนเครื่อง bkp
curl -s localhost:9090/api/v1/alerts | python3 -c 'import sys,json;[print(a["labels"]["alertname"],a["labels"].get("task"),a["state"]) for a in json.load(sys.stdin)["data"]["alerts"]]'

# ── 5.4 ทดสอบกู้คืนอัตโนมัติรายสัปดาห์ ──────────────────────
# บนเครื่อง prod
sudo install -m 750 restore-test.sh /usr/local/sbin/
sudo install -m 644 restore-test.service restore-test.timer /etc/systemd/system/
sudo systemctl daemon-reload && sudo systemctl enable --now restore-test.timer
time sudo systemctl start restore-test.service
sudo journalctl -u restore-test -o cat | grep -E "PASS|FAIL|no errors|restored and compared"
cat /var/lib/node_exporter/textfile/restore_test.prom

# ── timer บน bkp ────────────────────────────────────────────
# บนเครื่อง bkp
sudo install -m 644 snap-pull.service snap-pull.timer prune-on-bkp.service prune-on-bkp.timer /etc/systemd/system/
sudo systemctl daemon-reload && sudo systemctl enable --now snap-pull.timer prune-on-bkp.timer
sudo systemctl start snap-pull.service prune-on-bkp.service
systemctl list-timers --no-pager | grep -E "snap|prune"
