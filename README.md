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
    ports:
      - "8080:80"
      - "3306:3306"
      - "5060:5060"
      - "5160:5160"
      - "5061:5061"
      - "5161:5161"
      - "10000-10100:10000-10100/udp"
    network_mode: bridge
    volumes:
      - freepbx-backup:/backup
      - freepbx-recordings:/var/spool/asterisk/monitor
      - freepbx-mysql:/var/lib/mysql
    restart: always

volumes:
  freepbx-backup:
  freepbx-mysql:
  freepbx-recordings:
```

* Run ```docker-compose up -d```

* Open admin panel at http://localhost:8080/
