#!/bin/bash
VER="15.0"
while /bin/true; do
  echo "Waiting $BACKUP_TIMER seconds for the next automatic backup..."
  sleep $BACKUP_TIMER
  echo "Running backup and storing to /backup/$VER/new.tgz..."
  mkdir -p /backup/$VER
  cd /backup
  fwconsole bu --backup aadcce81-6b19-4d59-8321-057a716f3a83
  if [ "$?" != "0" ]; then
    echo "Error creating automatic backup"
  else
    if [ -f $VER/new.tar.gz ]; then 
      mv $VER/new.tar.gz $VER/old.tar.gz
    fi
    ls *.tar.gz -tr | tail -n 1 | xargs -I{} mv {} $VER/new.tar.gz
    echo "Backup saved to /backup/$VER/new.tar.gz"
  fi
done
