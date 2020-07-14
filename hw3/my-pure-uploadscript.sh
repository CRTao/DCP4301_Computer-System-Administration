#!/bin/sh
# Put this file in /usr/local/bin/my-pure-uploadscript.sh
echo `date`: [$UPLOAD_VUSER] has uploaded ["$1"][$UPLOAD_SIZE] >> /var/log/uploadscript.log
