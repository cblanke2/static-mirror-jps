#!/usr/bin/bash

URL_TO_MIRROR=$1
EMAIL_TO_ALERT=$2

# Create mirror_temp dir
mkdir -p /root/mirror_temp

# Perform inital mirroring of site
httrack --mirror "https://$URL_TO_MIRROR" -%q0 -s0 -O /root/mirror_temp
rsync -azPI -q  /root/mirror_temp/$URL_TO_MIRROR/ /usr/share/nginx/html/

# Copy static mirror script and set up cronjob
curl https://raw.githubusercontent.com/cblanke2/static-mirror-jps/main/static_mirror.sh > /root/static_mirror.sh
crontab -l > /root/new_cron
echo "@daily /bin/bash /root/static_mirror.sh '$URL_TO_MIRROR' '$EMAIL_TO_ALERT'" >> /root/new_cron
echo "" >> /root/new_cron
crontab  /root/new_cron
rm /root/new_cron

# Restart Nginx
systemctl restart nginx

# Set up SSL
mkdir -p /root/ssl
yes "  " | openssl req -newkey rsa:4096 -x509 -sha256 -days 7300 -nodes -out /root/ssl/selfsigned.crt -keyout /root/ssl/selfsigned.key 2>/dev/null 1>&2
touch /etc/nginx/conf.d/ssl.conf
echo "server {" >> /etc/nginx/conf.d/ssl.conf
echo "    listen              443 ssl;" >> /etc/nginx/conf.d/ssl.conf
echo "    server_name         localhost;" >> /etc/nginx/conf.d/ssl.conf
echo "    ssl_certificate     /root/ssl/selfsigned.crt;" >> /etc/nginx/conf.d/ssl.conf
echo "    ssl_certificate_key /root/ssl/selfsigned.key;" >> /etc/nginx/conf.d/ssl.conf
echo "    ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;" >> /etc/nginx/conf.d/ssl.conf
echo "    ssl_ciphers         HIGH:!aNULL:!MD5;" >> /etc/nginx/conf.d/ssl.conf
echo "    " >> /etc/nginx/conf.d/ssl.conf
echo "    location / {" >> /etc/nginx/conf.d/ssl.conf
echo "        root   /usr/share/nginx/html;" >> /etc/nginx/conf.d/ssl.conf
echo "        index  index.html index.htm;" >> /etc/nginx/conf.d/ssl.conf
echo "    }" >> /etc/nginx/conf.d/ssl.conf
echo "}" >> /etc/nginx/conf.d/ssl.conf
