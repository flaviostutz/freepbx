#!/bin/bash
while /bin/true; do
  sleep 86400
  echo "Deleting recordings older than 60 days..."
  find /var/spool/asterisk/monitor/* -name "*.wav" -mtime 60 -delete
  echo "Done."
done

