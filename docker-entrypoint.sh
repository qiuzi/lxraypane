#! /bin/bash -eu

cp config/appprofile.example.php config/appprofile.php
mv db/migrations/20000101000000_init_database.php.new db/migrations/20000101000000_init_database.php

if [ "$CONFIG_FILE" != "" ]; then
  echo "[INFO] Config Panel from CONFIG_BASE64 env"
  echo $CONFIG_FILE | base64 -d > config/.config.php
  echo "[INFO] Config Panel from CONFIG_BASE64 completed"
fi
if [ "$DATABASE" = "yes" ]; then
 vendor/bin/phinx migrate && \
 php xcat Tool importAllSettings
 php xcat Tool createAdmin <<EOF
 $ADMINEMAIL
 $ADMINPASSWD
 Y
EOF
 php xcat ClientDownload
 bash update.sh
fi
if [ "$PORT" = "" ]; then
  PORT=80
fi
envsubst '$PORT' < /nginx.conf.template > /etc/nginx/nginx.conf

supervisord -c /supervisord.conf
