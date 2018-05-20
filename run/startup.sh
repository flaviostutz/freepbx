#!/bin/bash -x

#https://docs.docker.com/engine/admin/multi-service_container/

/etc/init.d/mysql start
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start mysql: $status"
  exit $status
fi

fwconsole start
if [ $status -ne 0 ]; then
  echo "Failed to start fwconsole: $status"
  exit $status
fi

/etc/init.d/apache2 start
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start apache2: $status"
  exit $status
fi

/run/backup.sh &
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start backup.sh: $status"
  exit $status
fi

/run/delete-old-recordings.sh &
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start delete-old-recordings: $status"
  exit $status
fi

while /bin/true; do
  ps aux |grep mysqld |grep -q -v grep
  MYSQL_STATUS=$?
  ps aux |grep asterisk |grep -q -v grep
  ASTERISK_STATUS=$?
  ps aux |grep '/run/backup.sh' |grep -q -v grep
  BACKUPSCRIPT_STATUS=$?

  if [ $MYSQL_STATUS -ne 0 -o $ASTERISK_STATUS -ne 0 -o $BACKUPSCRIPT_STATUS -ne 0 ]; then
    echo "One of the processes has already exited."
    exit -1
  fi
  sleep 60
done