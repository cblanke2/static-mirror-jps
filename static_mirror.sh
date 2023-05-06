#!/usr/bin/env bash

TIMESTAMP=$(date +%s)
WORKING_DIR="/root/mirror_temp"
TARGET_DIR="/usr/share/nginx/html"
TARGET_SITE=$1
THIS_HOST=$(hostname)
THIS_USER=$(whoami)
ALERT_EMAIL=$2

# Initial Mirror
# httrack --mirror "https://$TARGET_SITE" -"*?*" -O /root/mirror_temp

# Get status code of target site
STATUS_CODE=$(/usr/bin/curl -o /dev/null -s -w "%{http_code}\n" https://$TARGET_SITE)
STATIC_FLAG=$(/usr/bin/curl -o /dev/null -s -w "%{http_code}\n" https://$TARGET_SITE/static_flag.html)

# Check if main site is returning status code "200" and the static flag is a "404"
if [[ $STATUS_CODE == "200" && $STATIC_FLAG == "404" ]]; then
	# And that the various dirs exist
	if [[ -d $WORKING_DIR && -d $TARGET_DIR ]]; then
		# Then update the mirror of the site with `httrack`	
		/usr/bin/cd $WORKING_DIR && \
		/usr/bin/httrack --update "https://$TARGET_SITE" -%q0 -O $WORKING_DIR && \
		/usr/bin/cd -
		# Touch the static flag
		/usr/bin/touch $WORKING_DIR/$TARGET_SITE/static_flag.html
		# And move the files to the target directory
		/usr/bin/rsync -azPI --delete-during -q $WORKING_DIR/$TARGET_SITE/ $TARGET_DIR/
	fi
else
	/usr/bin/touch $WORKING_DIR/EMAIL_$TIMESTAMP.log
	/usr/bin/echo "Subject: Static Mirror Failed" >> $WORKING_DIR/EMAIL_$TIMESTAMP.log
	/usr/bin/echo "From: $THIS_HOST <$THIS_USER@$THIS_HOST>" >> $WORKING_DIR/EMAIL_$TIMESTAMP.log
	/usr/bin/echo "To: $ALERT_EMAIL <$ALERT_EMAIL>" >> $WORKING_DIR/EMAIL_$TIMESTAMP.log
	/usr/bin/echo "" >> $WORKING_DIR/EMAIL_$TIMESTAMP.log
	/usr/bin/echo "Static Mirroring For $TARGET_SITE Failed" >> $WORKING_DIR/EMAIL_$TIMESTAMP.log
	/usr/bin/echo "Status Code: $STATUS_CODE" >> $WORKING_DIR/EMAIL_$TIMESTAMP.log
	/usr/bin/echo "Static Flag: $STATIC_FLAG" >> $WORKING_DIR/EMAIL_$TIMESTAMP.log
	/usr/bin/cat $WORKING_DIR/EMAIL_$TIMESTAMP.log | /usr/sbin/sendmail $ALERT_EMAIL
	/usr/bin/rm -f $WORKING_DIR/EMAIL_$TIMESTAMP.log
fi
