#!/bin/bash
while /bin/true; do
  sleep 86400
  echo "Running backup and storing to /backup/new.tgz..."
  fwconsole bu --backup aadcce81-6b19-4d59-8321-057a716f3a83
  if [ "$?" != "0" ]; then
    echo "Error creating automatic backup"
  else
    mv /backup/new.tar.gz /backup/old.tar.gz
    mv 2* new.tar.gz
    echo "Backup saved to /backup/new.tar.gz"
  fi
done
