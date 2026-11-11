#!/bin/sh
# /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh
# รันหลัง certbot ต่ออายุสำเร็จทุกครั้ง ให้ Nginx โหลดใบรับรองใหม่
systemctl reload nginx
