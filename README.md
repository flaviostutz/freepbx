# FreePBX on Docker

Working but not yet finished...

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

 * Add volume for freepbx backup/restore
 * Add volume for logs
 * ~~Reduce memory usage of apache and mysql~~
 * Add Fail2Ban
 * Move mysql into its own containter
 * Reduce number of image layers
 
