# FreePBX

Working but not yet finished...

### Image includes

 * phusion/baseimage
 * LAMP stack (apache2, mysql, php)
 * Asterisk 13
 * FreePBX
 
### Run your FreePBX image
```bash
docker run --net=host -d -t jmar71n/freepbx
```

Test it out by visiting your hosts ip address.

### My to do list

 * Add volumes for freepbx backup/restore
 * Move mysql into its own containter
 