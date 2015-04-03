# FreePBX on Docker

### Image includes

 * phusion/baseimage (Ubuntu 14.04)
 * LAMP stack (apache2, mysql, php)
 * Certified Asterisk 13.1
 * FreePBX 12
 
### Run your FreePBX image
```bash
docker run --net=host -d -t jmar71n/freepbx
```

Test it out by visiting your hosts ip address in a browser.

### My to do list

 * Add Fail2Ban
 * Reduce number of image layers