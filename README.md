# FreePBX

Working but not yet finished...

### Image includes

 * phusion/baseimage
 * LAMP stack (apache2, mysql, php)
 * Certified Asterisk 13.1
 * FreePBX
 
### Run your FreePBX image
```bash
docker run --net=host -d -t jmar71n/freepbx
```

Test it out by visiting your hosts ip address.

### My to do list

 * Add volumes for freepbx backup/restore
 * Add volumes for logs
 * Reduce memory usage of apache and mysql
 * Add Fail2Ban
 * Move mysql into its own containter
 
