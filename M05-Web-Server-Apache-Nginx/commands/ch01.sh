#!/usr/bin/env bash
# Apache HTTP Server: หลายเว็บและ PHP บนเครื่องเดียว
# SysAdmin Pocket Series M05 Web Server: Apache & Nginx
# ไฟล์รวมคำสั่งตามลำดับในเล่ม ไม่ใช่สคริปต์ ให้คัดลอกไปรันทีละคำสั่งพร้อมอ่านคำอธิบายในเล่ม
echo "ไฟล์รวมคำสั่ง ห้ามรันทั้งไฟล์ ให้คัดลอกทีละคำสั่ง" >&2
exit 1

# ── 1.1 ติดตั้ง Apache ──────────────────────────────────────
sudo dnf install -y httpd
httpd -v
sudo systemctl enable --now httpd
systemctl is-active httpd
sudo ss -tlnp | grep httpd
curl -sI http://localhost | head -3

# ── 1.2 โครงสร้างไฟล์ตั้งค่า ────────────────────────────────
grep -nE '^(ServerRoot|Listen|DocumentRoot|User|Group|IncludeOptional|Include) ' /etc/httpd/conf/httpd.conf
ls /etc/httpd/conf.d

# ── 1.3 Virtual Host หลายเว็บในเครื่องเดียว ─────────────────
sudo mkdir -p /var/www/site1 /var/www/site2
echo '<h1>site1.lab.test</h1>' | sudo tee /var/www/site1/index.html
echo '<h1>site2.lab.test</h1>' | sudo tee /var/www/site2/index.html
sed 's/site1/site2/g' /etc/httpd/conf.d/site1.conf | sudo tee /etc/httpd/conf.d/site2.conf > /dev/null
sudo apachectl configtest
sudo systemctl reload httpd
curl -s http://site1.lab.test
curl -s http://site2.lab.test
curl -s -H 'Host: other.lab.test' http://192.168.56.20
sudo httpd -S 2>&1 | sed -n 2,5p
echo 'ServerName web.lab.test' | sudo tee /etc/httpd/conf.d/00-servername.conf
sudo mkdir -p /var/www/default
echo 'ไม่มีเว็บชื่อนี้บน server' | sudo tee /var/www/default/index.html
sudo apachectl configtest
sudo systemctl reload httpd
curl -s -H 'Host: other.lab.test' http://192.168.56.20
sudo httpd -S 2>&1 | sed -n 1,6p

# ── 1.4 PHP-FPM กับ Apache ──────────────────────────────────
sudo dnf install -y php-fpm php-mysqlnd php-gd php-xml php-mbstring php-intl
rpm -q php-fpm
grep -E '^(listen|listen.acl_users|user|group) ' /etc/php-fpm.d/www.conf
sudo systemctl enable --now php-fpm
sudo systemctl restart httpd
echo '<?php echo "PHP " . PHP_VERSION . " via " . PHP_SAPI . "\n";' | sudo tee /var/www/site1/info.php
curl -s http://site1.lab.test/info.php
sudo rm /var/www/site1/info.php

# ── Lab 1.3 ติดตั้ง WordPress บน Apache ─────────────────────
sudo dnf install -y mariadb-server php-cli
sudo systemctl enable --now mariadb
sudo mysql -e "CREATE DATABASE wordpress CHARACTER SET utf8mb4; CREATE USER 'wpuser'@'localhost' IDENTIFIED BY 'Lab-WP-2569!'; GRANT ALL ON wordpress.* TO 'wpuser'@'localhost';"
sudo mysql -e "SHOW GRANTS FOR 'wpuser'@'localhost'"
cd /tmp && curl -sO https://wordpress.org/latest.tar.gz
sudo tar xzf latest.tar.gz -C /var/www/
grep "wp_version =" /var/www/wordpress/wp-includes/version.php
sudo cp /var/www/wordpress/wp-config-sample.php /var/www/wordpress/wp-config.php
sudo sed -i -e "s/database_name_here/wordpress/" -e "s/username_here/wpuser/" -e "s/password_here/Lab-WP-2569!/" /var/www/wordpress/wp-config.php
sudo chown -R root:root /var/www/wordpress
sudo chown -R apache:apache /var/www/wordpress/wp-content
sudo semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/wordpress/wp-content(/.*)?'
sudo restorecon -R /var/www/wordpress/wp-content
sudo chown root:apache /var/www/wordpress/wp-config.php
sudo chmod 640 /var/www/wordpress/wp-config.php
ls -Zd /var/www/wordpress/wp-content
# ⚠️ อย่าใช้ chown -R apache กับทั้งโฟลเดอร์ WordPress และอย่าใช้ chmod 777 ถ้าปลั๊กอินตัวใดมีช่องโหว่ ผู้โจมตีจะแก้ไฟล์ PHP ทุกไฟล์ในเว็บได้ทันที ให้ apache เขียนได้เฉพาะ wp-content ตามตัวอย่าง
sudo apachectl configtest && sudo systemctl reload httpd
curl -s http://wp.lab.test/wp-admin/install.php | grep -o '<title>[^<]*'
curl -sL -o /tmp/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
sudo install -m 755 /tmp/wp /usr/local/bin/wp
wp --version
cd /var/www/wordpress
sudo -u apache /usr/local/bin/wp core install --url=http://wp.lab.test --title="Lab WordPress" --admin_user=wpadmin --admin_password='Lab-Admin-2569!' --admin_email=admin@lab.test --skip-email
sudo -u apache /usr/local/bin/wp rewrite structure '/%postname%/'
sudo -u apache /usr/local/bin/wp post create --post_title="Hello Apache" --post_name=hello-apache --post_status=publish --porcelain
curl -s -o /dev/null -w '%{http_code}\n' http://wp.lab.test/hello-apache/
curl -s -o /dev/null -w '%{http_code} %{redirect_url}\n' -b 'wordpress_test_cookie=WP%20Cookie%20check' -d 'log=wpadmin&pwd=Lab-Admin-2569!&wp-submit=Log+In&testcookie=1' http://wp.lab.test/wp-login.php

# ── 1.5 Module และ .htaccess ────────────────────────────────
httpd -M 2>/dev/null | wc -l
httpd -M 2>/dev/null | grep -E 'rewrite|ssl|proxy_module|headers|status'
grep -n "rewrite\|headers" /etc/httpd/conf.modules.d/00-base.conf
echo 'Redirect /old /new' | sudo tee /var/www/site1/.htaccess
curl -s -o /dev/null -w 'site1 /old -> %{http_code}\n' http://site1.lab.test/old
sudo rm /var/www/site1/.htaccess
sudo sed -i 's/AllowOverride All/AllowOverride None/' /etc/httpd/conf.d/wp.conf && sudo systemctl reload httpd
curl -s -o /dev/null -w 'AllowOverride None -> %{http_code}\n' http://wp.lab.test/hello-apache/
sudo sed -i 's/AllowOverride None/AllowOverride All/' /etc/httpd/conf.d/wp.conf && sudo systemctl reload httpd
curl -s -o /dev/null -w 'AllowOverride All -> %{http_code}\n' http://wp.lab.test/hello-apache/

# ── 1.6 Log และการตรวจค่าตั้ง ───────────────────────────────
sudo tail -2 /var/log/httpd/wp-access.log
sudo sed -i 's|DocumentRoot /var/www/site2|DocumentRot /var/www/site2|' /etc/httpd/conf.d/site2.conf
sudo apachectl configtest; echo "rc=$?"
sudo sed -i 's|DocumentRot /var/www/site2|DocumentRoot /var/www/site2|' /etc/httpd/conf.d/site2.conf
sudo apachectl configtest

# ── กล่อง Ubuntu ────────────────────────────────────────────
sudo a2ensite site1
sudo a2dissite 000-default
ls -l /etc/apache2/sites-enabled/
