#!/usr/bin/env bash
# ก่อนเริ่ม: วิธีใช้หนังสือและเตรียมเครื่อง
# SysAdmin Pocket Series M10 SSL & Security Hardening
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── ติดตั้งแพ็กเกจบน sec1 ───────────────────────────────────
sudo dnf install -y epel-release
sudo dnf install -y nginx php-fpm bind bind-utils openssl
rpm -q nginx php-fpm bind

# ── DNS ของวง lab.test ──────────────────────────────────────
sudo tee /var/named/dynamic/lab.test.zone > /dev/null <<'EOF'
$TTL 300
@        IN SOA  sec1.lab.test. admin.lab.test. (1 3600 900 604800 300)
         IN NS   sec1.lab.test.
sec1     IN A    192.168.56.80
site     IN A    192.168.56.80
www      IN A    192.168.56.80
app      IN A    192.168.56.80
attacker IN A    192.168.56.81
EOF
sudo chown named:named /var/named/dynamic/lab.test.zone
sudo tee -a /etc/named.conf > /dev/null <<'EOF'

zone "lab.test" IN {
        type master;
        file "dynamic/lab.test.zone";
};
EOF
sudo named-checkconf && sudo named-checkzone lab.test /var/named/dynamic/lab.test.zone
sudo systemctl enable --now named
sudo nmcli con mod enp0s3 ipv4.ignore-auto-dns yes ipv4.dns 127.0.0.1 ipv6.ignore-auto-dns yes
sudo nmcli con up enp0s3
dig +short site.lab.test
dig +short rockylinux.org

# ── เว็บ site.lab.test ──────────────────────────────────────
sudo mkdir -p /usr/share/nginx/site
echo '<?php echo "site.lab.test บน " . gethostname() . " PHP " . PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION . "\n";' | sudo tee /usr/share/nginx/site/index.php > /dev/null
sudo nginx -t
sudo systemctl enable --now php-fpm nginx
sudo firewall-cmd --permanent --add-service={http,https}
sudo firewall-cmd --reload
curl -s http://site.lab.test/

# ── certbot และ Pebble ──────────────────────────────────────
sudo dnf install -y certbot
sudo python3 -m venv /opt/certbot
sudo /opt/certbot/bin/pip install --upgrade pip
sudo /opt/certbot/bin/pip install certbot certbot-nginx certbot-dns-rfc2136
sudo ln -s /opt/certbot/bin/certbot /usr/bin/certbot
certbot --version
sudo ./setup-pebble.sh
sudo ss -ltnp | grep pebble

# ── เตรียมเครื่อง attacker ──────────────────────────────────
# บนเครื่อง attacker
sudo dnf install -y openssl bind-utils
# บนเครื่อง attacker
echo "192.168.56.80 sec1.lab.test site.lab.test www.lab.test app.lab.test" | sudo tee -a /etc/hosts
# บนเครื่อง attacker
ssh-keygen -t ed25519 -C admin@attacker
# บนเครื่อง attacker
ssh-copy-id -p 2222 admin@sec1.lab.test
# บนเครื่อง attacker
scp -P 2222 admin@sec1.lab.test:/opt/pebble/certs/lab-root.pem .
# บนเครื่อง attacker
sudo cp lab-root.pem /etc/pki/ca-trust/source/anchors/
# บนเครื่อง attacker
sudo update-ca-trust
# บนเครื่อง attacker
curl -s http://site.lab.test/

# ── วัดคะแนนก่อนเริ่ม ───────────────────────────────────────
sudo ./security-audit.sh
sudo ./security-audit.sh -v | grep -A1 "18 "
