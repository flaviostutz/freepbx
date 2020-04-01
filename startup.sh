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

  echo "Applying initial configurations..."
  /apply-initial-configs.sh

  touch /init
fi



if [ "$ENABLE_AUTO_RESTORE" == "true" ]; then
  #restore backup if exists
  if [ -f /backup/new.tgz ]; then
    echo "Restoring backup from /backup/new.tgz"
    fwconsole backup --restore /backup/new.tgz
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

