#!/usr/bin/bash

URL_TO_MIRROR=$1
EMAIL_TO_ALERT=$2

# Create mirror_temp dir
mkdir -p /root/mirror_temp

# Perform inital mirroring of site
if [[ -d /root/mirror_temp ]]; then
	httrack --mirror "https://$URL_TO_MIRROR" -"*?*" -O /root/mirror_temp && \
	rsync -azPI -q  /root/mirror_temp/$URL_TO_MIRROR/ /usr/share/nginx/html/
fi

# Copy static mirror script and set up cronjob
if [[ -d /root/mirror_temp/$URL_TO_MIRROR ]]; then
	curl https://raw.githubusercontent.com/cblanke2/static-mirror-jps/main/static_mirror.sh > /root/static_mirror.sh && \
	crontab -l > /root/new_cron && \
	echo "@daily /usr/bin/bash /root/static_mirror.sh '$URL_TO_MIRROR' '$EMAIL_TO_ALERT'" >> /root/new_cron && \
	echo "" >> /root/new_cron && \
	crontab  /root/new_cron && \
	rm /root/new_cron && \
fi 

# Restart Nginx
systemctl restart nginx
