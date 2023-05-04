#!/usr/bin/bash

URL_TO_MIRROR=$1
EMAIL_TO_ALERT=$2

# Install httrack
yum install httrack -y

# Perform inital mirroring of site
screen -dm bash -c "httrack --mirror 'https://$URL_TO_MIRROR' -\"*?*\" -O /var/lib/nginx/mirror_temp && rsync /usr/bin/rsync -azP -q  /var/lib/nginx/mirror_temp/$URL_TO_MIRROR /var/www/webroot/ROOT/"

# Copy static mirror script
curl https://raw.githubusercontent.com/cblanke2/static-mirror-jps/main/static_mirror.sh > /var/lib/nginx/static_mirror.sh

# Set up cronjob for repeated syncs
crontab -l > mycron
echo "@daily /usr/bin/bash /var/lib/nginx/static_mirror.sh '$URL_TO_MIRROR' '$EMAIL_TO_ALERT'" >> mycron
crontab mycron
rm mycron
