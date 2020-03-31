# FROM flaviostutz/asterisk
FROM flaviostutz/asterisk:16.9.0.0

ENV RTP_START '18000'
ENV RTP_FINISH '18100'

ARG FREEPBX_VERSION=15.0-latest
ARG MARIAODBC_VERSION=2.0.19

# Pin libxml2 packages to Debian repositories
RUN echo "Package: libxml2*" > /etc/apt/preferences.d/libxml2 && \
    echo "Pin: release o=Debian,n=buster" >> /etc/apt/preferences.d/libxml2 && \
    echo "Pin-Priority: 501" >> /etc/apt/preferences.d/libxml2

# PHP 5.6
RUN apt-get update && \
    apt-get install -y curl wget sox lsb-release && \
    curl https://packages.sury.org/php/apt.gpg | apt-key add - && \
    echo "deb https://packages.sury.org/php/ buster main" > /etc/apt/sources.list.d/deb.sury.org.list && \
    apt-get update && \
    apt-get install -y php5.6 php5.6-curl php5.6-cli php5.6-mysql php-pear php5.6-gd \
                       php5.6-xml && \
    apt-get update  && \
    apt-get -o Dpkg::Options::="--force-confold" upgrade -y

RUN apt-get install -y build-essential apache2 mariadb-server mariadb-client bison flex

# MariaDB ODBC connector
RUN cd /usr/src && \
    mkdir -p mariadb-connector && \
    curl -sSL  https://downloads.mariadb.com/Connectors/odbc/connector-odbc-${MARIAODBC_VERSION}/mariadb-connector-odbc-${MARIAODBC_VERSION}-ga-debian-x86_64.tar.gz | tar xvfz - -C /usr/src/mariadb-connector && \
    mkdir -p /usr/lib/x86_64-linux-gnu/odbc/ && \
    cp mariadb-connector/lib/libmaodbc.so /usr/lib/x86_64-linux-gnu/odbc/ && \
    rm -rf mariadb-connector

# FreePBX
RUN cd /usr/src && \
	wget http://mirror.freepbx.org/modules/packages/freepbx/freepbx-$FREEPBX_VERSION.tgz && \
	tar xfz freepbx-$FREEPBX_VERSION.tgz && \
	rm -f freepbx-$FREEPBX_VERSION.tgz

ADD odbc.ini /etc/
ADD odbcinst.ini /etc/

# Needed for Asterisk to work properly (FROM image should have this already)
RUN chown -R asterisk:asterisk /var/run/asterisk && \
	chown -R asterisk:asterisk /etc/asterisk && \
    chown -R asterisk:asterisk /var/lib/asterisk && \
	chown -R asterisk:asterisk /var/log/asterisk && \
	chown -R asterisk:asterisk /var/spool/asterisk && \
	chown -R asterisk:asterisk /var/run/asterisk && \
	chown -R asterisk:asterisk /usr/lib/asterisk && \
    touch /etc/asterisk/modules.conf && \
    touch /etc/asterisk/cdr.conf

# FreePBX Hacks
RUN    sed -i -e "s/memory_limit = 128M/memory_limit = 256M/g" /etc/php/5.6/apache2/php.ini && \
    sed -i 's/\(^upload_max_filesize = \).*/\120M/' /etc/php/5.6/apache2/php.ini && \
    a2disconf other-vhosts-access-log.conf && \
    a2enmod rewrite && \
    a2enmod headers && \
    rm -rf /var/log/* && \
    mkdir -p /var/log/asterisk && \
    mkdir -p /var/log/apache2 && \
    mkdir -p /var/log/httpd

# Install FreePBX dependencies
RUN curl --silent https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
    echo 'deb https://deb.nodesource.com/node_10.x buster main' > /etc/apt/sources.list.d/nodesource.list && \
    echo 'deb-src https://deb.nodesource.com/node_10.x buster main' >> /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -y nodejs yarn cron gettext

# Install FreePBX
RUN /etc/init.d/mysql start && \
    cd /usr/src/freepbx && \
    echo "Starting Asterisk..." && \
    cp /etc/odbc.ini /usr/src/freepbx/installlib/files/odbc.ini && \
    ./start_asterisk start && \
    sleep 3 && \
    echo "Installing FreePBX..." && \
    ./install -n && \
    echo "Updating FreePBX modules..." && \
    fwconsole chown && \
    fwconsole ma upgradeall && \
    fwconsole ma downloadinstall backup bulkhandler ringgroups timeconditions ivr restapi cel configedit asteriskinfo && \
    # mysqldump -uroot -d -A -B --skip-add-drop-table > /mysql-freepbx.sql && \
    /etc/init.d/mysql stop && \
    gpg --refresh-keys --keyserver hkp://keyserver.ubuntu.com:80 && \
    gpg --import /var/www/html/admin/libraries/BMO/9F9169F4B33B4659.key && \
    gpg --import /var/www/html/admin/libraries/BMO/3DDB2122FE6D84F7.key && \
    gpg --import /var/www/html/admin/libraries/BMO/86CE877469D2EAD9.key && \
	rm -rf /usr/src/freepbx*

# Cleanup
RUN apt-get clean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

RUN sed -i 's/www-data/asterisk/g' /etc/apache2/envvars
RUN usermod -a -G root asterisk && usermod -a -G root www-data

### Setup for Data Persistence
# RUN    mkdir -p /assets/config/var/lib/ /assets/config/home/ && \
#     mv /home/asterisk /assets/config/home/ && \
#     ln -s /data/home/asterisk /home/asterisk && \
#     mv /var/lib/asterisk /assets/config/var/lib/ && \
#     ln -s /data/var/lib/asterisk /var/lib/asterisk && \
#     ln -s /data/usr/local/fop2 /usr/local/fop2 && \
#     mkdir -p /assets/config/var/run/ && \
#     mv /var/run/asterisk /assets/config/var/run/ && \
#     mv /var/lib/mysql /assets/config/var/lib/ && \
#     mkdir -p /assets/config/var/spool && \
#     mv /var/spool/cron /assets/config/var/spool/ && \
#     ln -s /data/var/spool/cron /var/spool/cron && \
#     mkdir -p /var/run/mongodb && \
#     rm -rf /var/lib/mongodb && \
#     ln -s /data/var/lib/mongodb /var/lib/mongodb && \
#     ln -s /data/var/run/asterisk /var/run/asterisk && \
#     rm -rf /var/spool/asterisk && \
#     ln -s /data/var/spool/asterisk /var/spool/asterisk && \
#     rm -rf /etc/asterisk && \
#     ln -s /data/etc/asterisk /etc/asterisk


#Install optional tools
# RUN apt-get install --no-install-recommends -y tcpdump tcpflow whois sipsak sngrep

# RUN    apt-get install --no-install-recommends -y \
#                     g++ \
#                     iptables \
#                     lame \
#                     libiodbc2 \
#                     libicu63 \
#                     libicu-dev \
#                     libsrtp2-1 \
#                     locales \
#                     locales-all \
#                     mpg123 \
#                     php5.6 \
#                     php5.6-cli \
#                     php5.6-curl \
#                     php5.6-gd \
#                     php5.6-ldap \
#                     php5.6-mbstring \
#                     php5.6-mysql \
#                     php5.6-sqlite \
#                     php5.6-xml \
#                     php5.6-zip \
#                     php5.6-intl \
#                     php-pear \
#                     pkg-config \
#                     sox \
#                     sqlite3 \
#                     unixodbc \
#                     uuid \
#                     xmlstarlet
                  #   mariadb-client \
                  #   mariadb-server \
                  #   mongodb-org \
                  #   apache2 \
                  #   composer \
                  #   fail2ban \
                  #   flite \
                  #   ffmpeg \
                  #   git \

ADD startup.sh /
ADD backup.sh /
ADD delete-old-recordings.sh /
ADD rtp_custom.conf.tmpl /

CMD [ "/startup.sh" ]

EXPOSE 80 3306 5060/udp 5160/udp 10000-20000/udp

#recordings data
VOLUME [ "/var/spool/asterisk/monitor" ]

#automatic backup
VOLUME [ "/backup" ]
