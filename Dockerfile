FROM tiredofit/freepbx:latest

#Delete old recordings to avoid wasting disk
COPY freepbx-delete-old-recordings /etc/cron.daily
RUN chmod +x /etc/cron.daily/freepbx-delete-old-recordings

ENV DB_EMBEDDED=false
ENV DB_HOST=mysql
ENV DB_NAME=freepbx
ENV DB_PORT=3306
ENV DB_USER=freepbx
ENV DB_PASS=freepbx
ENV ENABLE_FAIL2BAN=false

ADD 80-install-modules /etc/cont-init.d/

VOLUME [ "/data" ]

#recordings data
VOLUME [ "/var/spool/asterisk/monitor/" ]