<?php
// /var/www/roundcube/config/config.inc.php  Roundcube 1.6.20 จาก tarball บน Ubuntu 26.04
$config = [];
$config['db_dsnw'] = 'sqlite:////var/lib/roundcube-db/roundcube.db?mode=0640';
$config['imap_host'] = 'ssl://localhost:993';
$config['smtp_host'] = 'tls://localhost:587';
$config['smtp_user'] = '%u';
$config['smtp_pass'] = '%p';
$config['username_domain'] = 'example.com';
$config['product_name'] = 'Webmail example.com';
$config['des_key'] = 'DES_KEY_PLACEHOLDER';
$config['plugins'] = ['archive', 'zipdownload', 'markasjunk'];
$config['language'] = 'th_TH';
$config['enable_installer'] = false;
// Lab เท่านั้น: certificate snakeoil ไม่มีใครรับรอง บน server จริงลบสองบรรทัดนี้
$config['imap_conn_options'] = ['ssl' => ['verify_peer' => false, 'verify_peer_name' => false]];
$config['smtp_conn_options'] = ['ssl' => ['verify_peer' => false, 'verify_peer_name' => false]];
