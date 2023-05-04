#!/usr/bin/bash

URL_TO_MIRROR=$1
EMAIL_TO_ALERT=$2

# Create mirror_temp dir
mkdir -p /var/lib/nginx/mirror_temp

# Perform inital mirroring of site
if [[ -d /var/lib/nginx/mirror_temp ]]; then
	httrack --mirror 'https://$URL_TO_MIRROR' -"*?*" -O /var/lib/nginx/mirror_temp && \
	rsync -azP -q  /var/lib/nginx/mirror_temp/$URL_TO_MIRROR/ /var/www/webroot/ROOT/
fi

# Copy static mirror script and set up cronjob
if [[ -d /var/lib/nginx/mirror_temp/$URL_TO_MIRROR ]]; then
	curl https://raw.githubusercontent.com/cblanke2/static-mirror-jps/main/static_mirror.sh > /var/lib/nginx/static_mirror.sh && \
	crontab -l > /var/lib/nginx/new_cron && \
	echo "@daily /usr/bin/bash /var/lib/nginx/static_mirror.sh '$URL_TO_MIRROR' '$EMAIL_TO_ALERT'" >> /var/lib/nginx/new_cron && \
	echo "" >> /var/lib/nginx/new_cron && \
	crontab  /var/lib/nginx/new_cron && \
	rm /var/lib/nginx/new_cron && \
fi 
