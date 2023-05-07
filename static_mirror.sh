#!/usr/bin/env bash

# User/Server/Script-specific variables
TIMESTAMP=$(/bin/date +%s)
WORKING_DIR="/root/mirror_temp"
TARGET_DIR="/usr/share/nginx/html"
TARGET_SITE=$1
THIS_HOST=$(/bin/hostname)
THIS_USER=$(/usr/bin/whoami)
ALERT_EMAIL=$2

# Paths to binaries for portability
CURL_PATH=$(/usr/bin/which curl)
HTTRACK_PATH=$(/usr/bin/which httrack)
TOUCH_PATH=$(/usr/bin/which touch)
RSYNC_PATH=$(/usr/bin/which rsync)
ECHO_PATH=$(/usr/bin/which echo)
CAT_PATH=$(/usr/bin/which cat)
SENDMAIL_PATH=$(/usr/bin/which sendmail)
RM_PATH=$(/usr/bin/which rm)

# Get status code of target site
STATUS_CODE=$($CURL_PATH -o /dev/null -s -w "%{http_code}\n" https://$TARGET_SITE)
STATIC_FLAG=$($CURL_PATH -o /dev/null -s -w "%{http_code}\n" https://$TARGET_SITE/static_flag.html)

# Check if main site is returning status code "200" and the static flag is a "404"
if [[ $STATUS_CODE == "200" && $STATIC_FLAG == "404" ]]; then
	# And that the various dirs exist
	if [[ -d $WORKING_DIR && -d $TARGET_DIR ]]; then
		# Then update the mirror of the site with `httrack`	
		$HTTRACK_PATH --update "https://$TARGET_SITE" -%q0 -O $WORKING_DIR
		# Touch the static flag
		$TOUCH_PATH $WORKING_DIR/$TARGET_SITE/static_flag.html
		# And move the files to the target directory
		$RSYNC_PATH -azPI --delete-during -q $WORKING_DIR/$TARGET_SITE/ $TARGET_DIR/
	fi
else
	$TOUCH_PATH $WORKING_DIR/EMAIL_$TIMESTAMP.log
	$ECHO_PATH "Subject: Static Mirror Failed" >> $WORKING_DIR/EMAIL_$TIMESTAMP.log
	$ECHO_PATH "From: $THIS_HOST <$THIS_USER@$THIS_HOST>" >> $WORKING_DIR/EMAIL_$TIMESTAMP.log
	$ECHO_PATH "To: $ALERT_EMAIL <$ALERT_EMAIL>" >> $WORKING_DIR/EMAIL_$TIMESTAMP.log
	$ECHO_PATH "" >> $WORKING_DIR/EMAIL_$TIMESTAMP.log
	$ECHO_PATH "Static Mirroring For $TARGET_SITE Failed" >> $WORKING_DIR/EMAIL_$TIMESTAMP.log
	$ECHO_PATH "Status Code: $STATUS_CODE" >> $WORKING_DIR/EMAIL_$TIMESTAMP.log
	$ECHO_PATH "Static Flag: $STATIC_FLAG" >> $WORKING_DIR/EMAIL_$TIMESTAMP.log
	$CAT_PATH $WORKING_DIR/EMAIL_$TIMESTAMP.log | $SENDMAIL_PATH $ALERT_EMAIL
	$RM_PATH -f $WORKING_DIR/EMAIL_$TIMESTAMP.log
fi
