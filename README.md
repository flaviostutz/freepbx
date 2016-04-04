# FreePBX on Docker

### Image includes

 * phusion/baseimage (Ubuntu 14.04)
 * LAMP stack (apache2, mysql, php)
 * Certified Asterisk 13.1
 * FreePBX 13
 


### Run your FreePBX image
```bash
docker run --net=host -d -t jmar71n/freepbx
```

Test it out by visiting your hosts ip address in a browser.

### Fork ME

Please feel free to fork or contribite this image.
[https://bitbucket.org/jmar71n/docker-freepbx/src/]