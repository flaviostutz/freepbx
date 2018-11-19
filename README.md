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
    build: .
    image: flaviostutz/freepbx:14.0
    network_mode: host
    volumes:
      - freepbx-backup:/backup
      - freepbx-recordings:/var/spool/asterisk/monitor

volumes:
  freepbx-backup:
  freepbx-recordings:
```

* Run ```docker-compose up -d```

* Open admin panel at http://localhost/
