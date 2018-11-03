#!/bin/bash -x
while /bin/true; do
#  sleep 1800
  sleep 10
  php /var/www/html/admin/modules/backup/bin/backup.php --id=1
  mkdir -p /backup/
  rm /backup/old.tgz
  mv /backup/new.tgz /backup/old.tgz
  mv /var/spool/asterisk/backup/Default_backup/"$(ls -t /var/spool/asterisk/backup/Default_backup | head -1)" /backup/new.tgz
done