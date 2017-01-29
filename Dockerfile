FROM phusion/baseimage:0.9.18
MAINTAINER Jason Martin <jason@greenpx.co.uk>

# Set environment variables
ENV DEBIAN_FRONTEND noninteractive
ENV ASTERISKUSER asterisk

CMD ["/sbin/my_init"]

# Setup services
COPY start-apache2.sh /etc/service/apache2/run
RUN chmod +x /etc/service/apache2/run

COPY start-mysqld.sh /etc/service/mysqld/run
RUN chmod +x /etc/service/mysqld/run

COPY start-asterisk.sh /etc/service/asterisk/run
RUN chmod +x /etc/service/asterisk/run

COPY start-amportal.sh /etc/my_init.d/start-amportal.sh

# *Loosely* Following steps on FreePBX wiki
# http://wiki.freepbx.org/display/FOP/Installing+FreePBX+13+on+Ubuntu+Server+14.04.2+LTS

# Install Required Dependencies
RUN apt-get update \
	&& apt-get upgrade -y \
	&& apt-get install -y \
	  wget
		apache2 \
		autoconf \
		automake \
		bison \
		build-essential \
		curl \
		flex \
		git \
		libasound2-dev \
		libcurl4-openssl-dev \
		libical-dev \
		libmyodbc \
		libmysqlclient-dev \
		libncurses5-dev \
		libneon27-dev \
		libnewt-dev \
		libodbc1 \
		libogg-dev \
		libspandsp-dev \
		libsqlite3-dev \
		libsrtp0-dev \
		libssl-dev \
		libtool \
		libvorbis-dev \
		libxml2-dev \
		mpg123 \
		mysql-client \
		mysql-server \
		openssh-server \
		php-pear \
		php5 \
		php5-cli \
		php5-curl \
		php5-gd \
		php5-mysql \
		pkg-config \
		sox \
		subversion \
		sqlite3 \
		unixodbc-dev \
		uuid \
		uuid-dev \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# Replace default conf files to reduce memory usage
COPY conf/my-small.cnf /etc/mysql/my.cnf
COPY conf/mpm_prefork.conf /etc/apache2/mods-available/mpm_prefork.conf

# Install Legacy pear requirements
RUN pear install Console_Getopt

# Compile and install pjproject
WORKDIR /usr/src
RUN curl -sf -o pjproject.tar.bz2 -L http://www.pjsip.org/release/2.4/pjproject-2.4.tar.bz2 \
	&& tar -xjvf pjproject.tar.bz2 \
	&& rm -f pjproject.tar.bz2 \
	&& cd pjproject-2.4 \
	&& CFLAGS='-DPJ_HAS_IPV6=1' ./configure --enable-shared --disable-sound --disable-resample --disable-video --disable-opencore-amr \
	&& make dep \
	&& make \
	&& make install \
	&& rm -r /usr/src/pjproject-2.4

# Compile and Install jansson
WORKDIR /usr/src
RUN curl -sf -o jansson.tar.gz -L http://www.digip.org/jansson/releases/jansson-2.7.tar.gz \
	&& mkdir jansson \
	&& tar -xzf jansson.tar.gz -C jansson --strip-components=1 \
	&& rm jansson.tar.gz \
	&& cd jansson \
	&& autoreconf -i \
	&& ./configure \
	&& make \
	&& make install \
	&& rm -r /usr/src/jansson

# Compile and Install Asterisk
WORKDIR /usr/src
RUN curl -sf -o asterisk.tar.gz -L http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-13-current.tar.gz \
	&& mkdir asterisk \
	&& tar -xzf /usr/src/asterisk.tar.gz -C /usr/src/asterisk --strip-components=1 \
	&& rm asterisk.tar.gz \
	&& cd asterisk \
	&& ./configure \
	&& contrib/scripts/get_mp3_source.sh \
	&& make menuselect.makeopts \
	&& sed -i "s/format_mp3//" menuselect.makeopts \
	&& sed -i "s/BUILD_NATIVE//" menuselect.makeopts \
	&& make \
	&& make install \
	&& make config \
	&& ldconfig \
	&& update-rc.d -f asterisk remove \
	&& rm -r /usr/src/asterisk
COPY conf/asterisk.conf /etc/asterisk/asterisk.conf

# Download extra sounds
WORKDIR /var/lib/asterisk/sounds
RUN curl -sf -o asterisk-core-sounds-en-wav-current.tar.gz -L http://downloads.asterisk.org/pub/telephony/sounds/asterisk-core-sounds-en-wav-current.tar.gz \
	&& tar -xzf asterisk-core-sounds-en-wav-current.tar.gz \
	&& rm -f asterisk-core-sounds-en-wav-current.tar.gz \
	&& curl -sf -o asterisk-extra-sounds-en-wav-current.tar.gz -L http://downloads.asterisk.org/pub/telephony/sounds/asterisk-extra-sounds-en-wav-current.tar.gz \
	&& tar -xzf asterisk-extra-sounds-en-wav-current.tar.gz \
	&& rm -f asterisk-extra-sounds-en-wav-current.tar.gz \
	&& curl -sf -o asterisk-core-sounds-en-g722-current.tar.gz -L http://downloads.asterisk.org/pub/telephony/sounds/asterisk-core-sounds-en-g722-current.tar.gz \
	&& tar -xzf asterisk-core-sounds-en-g722-current.tar.gz \
	&& rm -f asterisk-core-sounds-en-g722-current.tar.gz \
	&& curl -sf -o asterisk-extra-sounds-en-g722-current.tar.gz -L http://downloads.asterisk.org/pub/telephony/sounds/asterisk-extra-sounds-en-g722-current.tar.gz \
	&& tar -xzf asterisk-extra-sounds-en-g722-current.tar.gz \
	&& rm -f asterisk-extra-sounds-en-g722-current.tar.gz

# Add Asterisk user
RUN useradd -m $ASTERISKUSER \
	&& chown $ASTERISKUSER. /var/run/asterisk \
	&& chown -R $ASTERISKUSER. /etc/asterisk \
	&& chown -R $ASTERISKUSER. /var/lib/asterisk \
	&& chown -R $ASTERISKUSER. /var/log/asterisk \
	&& chown -R $ASTERISKUSER. /var/spool/asterisk \
	&& chown -R $ASTERISKUSER. /usr/lib/asterisk \
	&& chown -R $ASTERISKUSER. /var/www/ \
	&& chown -R $ASTERISKUSER. /var/www/* \
	&& rm -rf /var/www/html

# Configure apache
RUN sed -i 's/\(^upload_max_filesize = \).*/\120M/' /etc/php5/apache2/php.ini \
	&& cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf_orig \
	&& sed -i 's/^\(User\|Group\).*/\1 asterisk/' /etc/apache2/apache2.conf \
	&& sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf \
        && a2enmod rewrite

# Configure Asterisk database in MYSQL
RUN /etc/init.d/mysql start \
	&& mysqladmin -u root create asterisk \
	&& mysqladmin -u root create asteriskcdrdb \
	&& mysql -u root -e "GRANT ALL PRIVILEGES ON asterisk.* TO $ASTERISKUSER@localhost IDENTIFIED BY '';" \
	&& mysql -u root -e "GRANT ALL PRIVILEGES ON asteriskcdrdb.* TO $ASTERISKUSER@localhost IDENTIFIED BY '';" \
	&& mysql -u root -e "flush privileges;"

#Make CDRs work
COPY conf/cdr/odbc.ini /etc/odbc.ini
COPY conf/cdr/odbcinst.ini /etc/odbcinst.ini
COPY conf/cdr/cdr_adaptive_odbc.conf /etc/asterisk/cdr_adaptive_odbc.conf
RUN chown asterisk:asterisk /etc/asterisk/cdr_adaptive_odbc.conf \
	&& chmod 775 /etc/asterisk/cdr_adaptive_odbc.conf

# Download and install FreePBX
WORKDIR /usr/src
RUN curl -sf -o freepbx.tgz -L http://mirror.freepbx.org/modules/packages/freepbx/freepbx-13.0-latest.tgz \
	&& tar xfz freepbx.tgz \
	&& rm freepbx.tgz \
	&& cd /usr/src/freepbx \
	&& /etc/init.d/mysql start \
	&& mkdir /var/www/html \
	&& /etc/init.d/apache2 start \
	&& /usr/sbin/asterisk \
	&& sleep 5 \
	&& ./install -n \
	&& fwconsole restart \
        && fwconsole moduleadmin downloadinstall backup \
        && fwconsole moduleadmin downloadinstall ivr \
				&& fwconsole moduleadmin downloadinstall asterisk-cli \
				&& fwconsole moduleadmin downloadinstall asteriskinfo \
				&& fwconsole moduleadmin downloadinstall timeconditions \
	&& rm -r /usr/src/freepbx

#Install codec g729 (if you have a license)
#RUN cd /usr/lib/asterisk/modules &&
#    wget http://asterisk.hosting.lv/bin/codec_g729-ast130-gcc4-glibc-x86_64-core2.so &&
#		mv codec_g729-ast130-gcc4-glibc-x86_64-core2.so codec_g729.so &&
#	  chown asterisk:asterisk codec_g729.so &&
#		chmod +x codec_g729.so

# Install pt-br language
#RUN mkdir /var/lib/asterisk/sounds/pt-br &&
#    cd /var/lib/asterisk/sounds/pt-br &&
#    wget -O core.zip https://www.asterisksounds.org/pt-br/download/asterisk-sounds-core-pt-BR-sln16.zip &&
#		wget -O extra.zip https://www.asterisksounds.org/pt-br/download/asterisk-sounds-extra-pt-BR-sln16.zip &&
#    unzip -o core.zip &&
#    unzip -o extra.zip &&
#    chown -R asterisk:asterisk /var/lib/asterisk/sounds/pt-br &&
#    find /var/lib/asterisk/sounds/pt-br -type d -exec chmod 0775 {} \;

#RUN for a in $(find . -name '*.sln16'); do\
#      sox -t raw -e signed-integer -b 16 -c 1 -r 16k $a -t gsm -r 8k `echo $a|sed "s/.sln16/.gsm/"`;\
#      sox -t raw -e signed-integer -b 16 -c 1 -r 16k $a -t raw -r 8k -e a-law `echo $a|sed "s/.sln16/.alaw/"`;\
#      sox -t raw -e signed-integer -b 16 -c 1 -r 16k $a -t raw -r 8k -e mu-law `echo $a|sed "s/.sln16/.ulaw/"`;\
#    done

WORKDIR /
