#!/bin/bash

if [[ ! -d /var/lib/mysql/asterisk ]]; then
    echo "=> An empty or uninitialized MySQL volume is detected"
    echo "=> Installing MySQL ..."
    mysql_install_db > /dev/null 2>&1
    echo "=> Done!"
    newdb=true
fi


exec mysqld_safe

if [ "$newdb" = true ] ; then
	mysqladmin -u root create asterisk
	mysqladmin -u root create asteriskcdrdb
	mysql -u root -e "GRANT ALL PRIVILEGES ON asterisk.* TO $ASTERISKUSER@localhost IDENTIFIED BY '$ASTERISK_DB_PW';"
	mysql -u root -e "GRANT ALL PRIVILEGES ON asteriskcdrdb.* TO $ASTERISKUSER@localhost IDENTIFIED BY '$ASTERISK_DB_PW';"
	mysql -u root -e "flush privileges;"
fi
