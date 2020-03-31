#!/bin/bash

set -e

#https://docs.docker.com/engine/admin/multi-service_container/

echo "Setting RTP port range at /etc/rtp_custom.conf..."
envsubst < /rtp_custom.conf.tmpl > /etc/rtp_custom.conf
cat /etc/rtp_custom.conf

echo "Starting MySQL..."
/etc/init.d/mysql start
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start mysql: $status"
  exit $status
fi


echo "Starting FreePBX..."
fwconsole start
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start fwconsole: $status"
  exit $status
fi


#restore backup if exists
if [ -f /backup/new.tgz ]; then
  echo "Restoring backup from /backup/new.tgz"
  php /var/www/html/admin/modules/backup/bin/restore.php --items=all --restore=/backup/new.tgz
  echo "Done"
fi
#restart freepbx to load everything fine after restoring backup
fwconsole stop
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to stop fwconsole: $status"
  exit $status
fi
fwconsole start
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start fwconsole: $status"
  exit $status
fi


echo "Starting Apache..."
/etc/init.d/apache2 start
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start apache2: $status"
  exit $status
fi

echo "Starting automatic backups..."
/backup.sh &
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start backup.sh: $status"
  exit $status
fi

echo "Starting automatic deletion of old recordings..."
/delete-old-recordings.sh &
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start delete-old-recordings: $status"
  exit $status
fi

# chmod 777 -R /etc/freepbx.conf
# chmod 777 -R /var/lib/php/sessions/
# chmod 777 -R /var/log/asterisk

echo "STARTUP COMPLETED"

while /bin/true; do
  ps aux |grep mysqld |grep -q -v grep
  MYSQL_STATUS=$?
  ps aux |grep asterisk |grep -q -v grep
  ASTERISK_STATUS=$?
  ps aux |grep '/backup.sh' |grep -q -v grep
  BACKUPSCRIPT_STATUS=$?

  if [ $ASTERISK_STATUS -ne 0 -o $BACKUPSCRIPT_STATUS -ne 0 -o $MYSQL_STATUS -ne 0 ]; then
    echo "One of the processes has exited."
    exit 1
  fi
  sleep 60
done