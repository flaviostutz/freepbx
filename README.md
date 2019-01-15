# FreePBX on Docker

### Image includes

 * Asterisk 14
 * FreePBX 14


### Run FreePBX image

docker-compose.yml
```
version: '3.3'
services:
  freepbx:
    image: flaviostutz/freepbx:14.0
    network_mode: host
    restart: always
    volumes:
      - freepbx-backup:/backup
      - freepbx-recordings:/var/spool/asterisk/monitor

volumes:
  freepbx-backup:
  freepbx-recordings:
```

* Run ```docker-compose up -d```

* Open admin panel at http://localhost/

### Sample host preparation

* Install Ubuntu 18.04

* Install Docker + Docker Compose

* Configure network

  * edit /etc/netplan/50-cloud-init.yaml

```
network:
    ethernets:
        eno1:
            addresses:
               - 10.1.2.5/22
               - 10.223.49.234/29
            nameservers:
               addresses: [10.1.1.254,8.8.8.8]
            gateway4: 10.1.1.254
            routes:
               - to: 10.128.0.0/9
                 via: 10.223.49.233
    version: 2
```

  * run ```netplan apply```

  * In this example suppose you have a VOIP provider in another network (10.223.x.x) connected to the Asterisk host. You can skip routes and the secondary address if not needed

  * Run this container

  

