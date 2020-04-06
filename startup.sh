#!/bin/bash

set -e

if [ "$ADMIN_PASSWORD" == "" ]; then
  echo "ADMIN_PASSWORD is required"
  exit 1
fi

#https://docs.docker.com/engine/admin/multi-service_container/

chown -R asterisk:asterisk /backup



echo "Starting MySQL..."
/etc/init.d/mysql start
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start mysql: $status"
  exit $status
fi



echo "Starting Apache..."
if [ -f /etc/asterisk/keys/$CERTIFICATE_DOMAIN.pem ]; then
  echo "Found certificate at /etc/asterisk/keys/$CERTIFICATE_DOMAIN.pem (possibly LetsEncrypt cert). Setting Apache to use it."
  sed -i 's|/etc/ssl/certs/ssl-cert-snakeoil.pem|/etc/asterisk/keys/'$CERTIFICATE_DOMAIN'.pem|g' /etc/apache2/sites-enabled/default-ssl.conf
  sed -i 's|/etc/ssl/private/ssl-cert-snakeoil.key|/etc/asterisk/keys/'$CERTIFICATE_DOMAIN'.key|g' /etc/apache2/sites-enabled/default-ssl.conf
fi

/etc/init.d/apache2 start
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start apache2: $status"
  exit $status
fi




echo "Starting FreePBX..."
fwconsole start
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start fwconsole: $status"
  exit $status
fi




# Apply configurations on initial startup
if [ ! -f /init ]; then

  #restore previous backup if exists
  if [ "$ENABLE_AUTO_RESTORE" == "true" ] && [ -f /backup/new.tar.gz ]; then
    echo "Restoring backup from /backup/new.tar.gz"
    fwconsole backup --restore /backup/new.tar.gz
    echo "Done"

  #apply initial configurations
  else
    echo "Applying initial configurations..."
    /apply-initial-configs.sh

  fi

  touch /init
fi




echo "Starting automatic backups..."
/backup.sh &
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start backup.sh: $status"
  exit $status
fi




if [ "$ENABLE_DELETE_OLD_RECORDINGS" == "true" ]; then
  echo "Starting automatic deletion of old recordings..."
  /delete-old-recordings.sh &
  status=$?
  if [ $status -ne 0 ]; then
    echo "Failed to start delete-old-recordings: $status"
    exit $status
  fi
fi




if [ "$MARIADB_REMOTE_ROOT_PASSWORD" != "" ]; then
  echo "Enabling remote access to MySQL. Be aware."
  QUERY="GRANT ALL ON *.* TO 'root'@'%' IDENTIFIED BY '$MARIADB_REMOTE_ROOT_PASSWORD' WITH GRANT OPTION; FLUSH PRIVILEGES;"
  mysql -u root -e "$QUERY"
fi



echo "STARTUP COMPLETED"


#Check if all processes are OK
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

