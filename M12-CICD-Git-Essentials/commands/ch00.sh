#!/usr/bin/env bash
# ก่อนเริ่ม: วิธีใช้หนังสือและเตรียมเครื่อง
# SysAdmin Pocket Series M12 CI/CD & Git Essentials: Deploy อัตโนมัติใน 1 วัน
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
# แต่ละคำสั่งมีป้ายบอกเครื่อง [ci] [stg] [prod] [docker] [ubu] หรือ [PowerShell] บน Windows
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── ตั้งชื่อเครื่องให้รู้จักกัน ─────────────────────────────
# [ci]
sudo tee -a /etc/hosts > /dev/null <<'EOF'
192.168.56.30  docker.lab.test gitlab.lab.test
192.168.56.35  ci.lab.test ci
192.168.56.36  stg.lab.test stg
192.168.56.37  prod.lab.test prod
EOF
getent hosts gitlab.lab.test stg

# ── ติดตั้ง Docker บน ci, stg และ prod ──────────────────────
# [ci]
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
# [ci]
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null <<'EOF'
{
  "insecure-registries": ["192.168.56.30:5000"],
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" }
}
EOF
python3 -m json.tool /etc/docker/daemon.json > /dev/null && echo "daemon.json OK"
sudo systemctl enable --now docker
docker --version
docker compose version
sudo docker info --format '{{range $k,$v := .RegistryConfig.IndexConfigs}}{{$k}} {{end}}'
