#!/bin/bash
while /bin/true; do
  echo "Waiting 1h for the next automatic backup..."
  sleep 3600
  echo "Running backup and storing to /backup/new.tgz..."
  cd /backup
  fwconsole bu --backup aadcce81-6b19-4d59-8321-057a716f3a83
  if [ "$?" != "0" ]; then
    echo "Error creating automatic backup"
  else
    mv /backup/new.tar.gz /backup/old.tar.gz
    mv 2* new.tar.gz
    echo "Backup saved to /backup/new.tar.gz"
  fi
done
