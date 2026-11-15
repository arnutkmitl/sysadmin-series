<?php
// /etc/roundcubemail/config.inc.php  ค่าของเล่ม M13 ค่าอื่นใช้จาก defaults.inc.php
$config = [];

// ฐานข้อมูล SQLite ไฟล์เดียว เก็บ session, สมุดที่อยู่ และค่าที่ผู้ใช้ตั้ง
$config['db_dsnw'] = 'sqlite:////var/lib/roundcubemail/roundcube.db?mode=0640';

// อ่านอีเมลผ่าน IMAPS และส่งผ่าน submission ด้วยชื่อและรหัสผ่านที่ผู้ใช้ login
$config['imap_host'] = 'ssl://mail.example.com:993';
$config['smtp_host'] = 'tls://mail.example.com:587';
$config['smtp_user'] = '%u';
$config['smtp_pass'] = '%p';

// ผู้ใช้พิมพ์แค่ชื่อ เช่น somchai แล้วเติม @example.com ให้
$config['username_domain'] = 'example.com';

$config['product_name'] = 'Webmail example.com';
$config['support_url'] = 'mailto:admin@example.com';
$config['des_key'] = 'DES_KEY_PLACEHOLDER';
$config['plugins'] = ['archive', 'zipdownload', 'markasjunk'];
$config['skin'] = 'elastic';
$config['language'] = 'th_TH';
$config['ip_check'] = true;
