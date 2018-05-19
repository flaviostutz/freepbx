#!/bin/bash

### Set Defaults
DB_PORT=${DB_PORT:-3306}
RTP_START=${RTP_START:-18000}
RTP_FINISH=${RTP_FINISH:-20000}
WEBROOT=${WEBROOT:-"/var/www/html"}

echo "Preparing mariadb local database..."
mkdir -p /var/lib/mysql
cp -R /assets/config/var/lib/mysql/* /var/lib/mysql
chown -R mysql:mysql /var/lib/mysql 
service mysql start
mysql asterisk --execute="SET PASSWORD FOR 'freepbxuser'@'localhost' = PASSWORD('ae426497afd46b1c24608399459ea129');"

if [ ! -f /data/.installed ]; then
  echo '** [freepbx] Creating Default Configuration Files'
  mkdir -p /data/
	cp -R /assets/config/* /data/
fi

echo '** [freepbx] Setting File Permissions'
mkdir -p /data/etc/asterisk
mkdir -p /data/var/lib/asterisk/{agi-bin,bin,playback}
mkdir -p /data/var/spool/asterisk/{dictate,meetme,monitor,recording,system,tmp,voicemail}
mkdir -p /data/var/run/asterisk
chown -R asterisk:asterisk /data

### Install FreePBX
echo '** [freepbx] Please wait while we fetch FreePBX - Will take 3 to 30 minutes...'

if [ "$WEBROOT" != "/var/www/html" ]; then
  echo '** [freepbx] Custom Installation Webroot Defined: '$WEBROOT
fi

sudo -u asterisk gpg --refresh-keys --keyserver pgp.mit.edu >/dev/null 2>&1
sudo -u asterisk gpg --keyserver pgp.mit.edu --recv-key 9F9169F4B33B4659 >/dev/null 2>&1
sudo -u asterisk gpg --keyserver pgp.mit.edu --recv-key 3DDB2122FE6D84F7 >/dev/null 2>&1
sudo -u asterisk gpg --keyserver pgp.mit.edu --recv-key 86CE877469D2EAD9 >/dev/null 2>&1
cd /usr/src
git clone --depth=1 -b release/14.0 --single-branch https://github.com/FreePBX/framework.git freepbx >/dev/null 2>&1
cd /usr/src/freepbx
cp -R /etc/odbc.ini /usr/src/freepbx/installlib/files/odbc.ini
./start_asterisk start 

if [ ! -f "/var/run/asterisk/asterisk.pid" ]; then
  echo "** [freepbx] Can't seen to start Asterisk. Exiting"
  exit 1
fi

echo '** [freepbx] Installing FreePBX'

./install -n --webroot=$WEBROOT

if [ ! -f "/usr/sbin/fwconsole" ]; then
  echo "** [freepbx] Can't seem to locate /usr/sbin/fwconsole.. Exitting"
  exit 1
fi

echo '** [freepbx] Enabling Default Modules'
fwconsole ma downloadinstall framework core cdr voicemail sipsettings infoservices featurecodeadmin logfiles callrecording dashboard music conferences restapi timeconditions ivr backup cel --edge
fwconsole ma downloadinstall certman userman --edge
fwconsole chown 
fwconsole reload 
fwconsole ma downloadinstall ucp --edge
fwconsole chown 
fwconsole reload 
fwconsole restart
fwconsole stop

cd / 
rm -rf /usr/src/freepbx
touch /data/.installed

### Data Persistence Workaround
  if [ ! -f /usr/sbin/fwconsole ]; then
  	   ln -s /var/lib/asterisk/bin/fwconsole /usr/sbin/fwconsole
  fi

  if [ ! -f /usr/sbin/amportal ]; then
  	   ln -s /var/lib/asterisk/bin/amportal /usr/sbin/amportal
  fi
  
  if [ ! -f /data/etc/amportal.conf ]; then
  		mkdir -p /data/etc/
	  	cp -R /etc/amportal.conf /data/etc/
	  	rm -rf /etc/amportal.conf
	  	touch /data/etc/amportal.conf
	  	chown asterisk:asterisk /data/etc/amportal.conf
	  	ln -s /data/etc/amportal.conf /etc/amportal.conf
  else
	  	ln -s /data/etc/amportal.conf /etc/amportal.conf
	  	touch /data/etc/amportal.conf
  fi

  if [ ! -f /data/etc/freepbx.conf ]; then
      mkdir -p /data/etc/
      cp -R /etc/freepbx.conf /data/etc/
      rm -rf /etc/freepbx.conf
      touch /data/etc/freepbx.conf
      chown asterisk:asterisk /data/etc/freepbx.conf
      ln -s /data/etc/freepbx.conf /etc/freepbx.conf
  else
      ln -s /data/etc/freepbx.conf /etc/freepbx.conf
      touch /data/etc/freepbx.conf
  fi

if [ ! -f /etc/asterisk/cdr_adaptive_odbc.conf ]; then
	cat <<EOF > /etc/asterisk/cdr_adaptive_odbc.conf
[first]
connection=asteriskcdrdb
table=cdr
alias start => calldate
EOF
fi

chown asterisk:asterisk /etc/freepbx.conf

echo '** [freepbx] Starting Asterisk'

if [ ! -f "/usr/sbin/fwconsole" ]; then
  echo "** [freepbx] Can't seem to locate /usr/sbin/fwconsole.. Exitting"
  exit 1
fi

fwconsole chown > /dev/null 2>&1
fwconsole start > /dev/null 2>&1
fwconsole reload > /dev/null 2>&1
chown -R asterisk /etc/asterisk/*
chown -R asterisk:asterisk /etc/amportal.conf

### Custom File Support
  if [ -d /assets/custom ] ; then
     echo "** [freepbx] Custom Files Found, Copying over top of Master.."
     cp -R /assets/custom/* /var/www/html/
     chown -R asterisk: /var/www/html/
  fi

### Apache Setup
cat >> /etc/apache2/conf-available/allowoverride.conf << EOF 
<Directory $WEBROOT>
    AllowOverride All
    </Directory>
EOF

cat > /etc/apache2/sites-enabled/000-default.conf << EOF 
Listen 73

ExtendedStatus On

<VirtualHost *:73>
CustomLog /dev/null common
ErrorLog /dev/null

<Location /server-status>
    SetHandler server-status
    Order deny,allow
    Deny from all
    Allow from localhost
</Location>
</VirtualHost>

<VirtualHost *:80>
  DocumentRoot /var/www/html
  ErrorLog /var/log/apache2/error.log
  CustomLog /var/log/apache2/access.log common
  <Location /server-status>
    SetHandler server-status
    Order deny,allow
    Deny from all
 </Location>
</VirtualHost>
EOF

a2enconf allowoverride >/dev/null

sed -i 's/\(APACHE_RUN_USER=\)\(.*\)/\1asterisk/g' /etc/apache2/envvars
sed -i 's/\(APACHE_RUN_GROUP=\)\(.*\)/\1asterisk/g' /etc/apache2/envvars
mkdir -p /var/log/apache2
chown -R root:adm /var/log/apache2
chown asterisk. /run/lock/apache2

### Disable Indexes if outside of regular webroot
if [ "$WEBROOT" != "/var/www/html" ]; then
  a2dismod autoindex -f
fi

chown -R asterisk /etc/asterisk/*
chown -R asterisk:asterisk /etc/amportal.conf
