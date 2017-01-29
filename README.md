# FreePBX on Docker

### Image includes

 * phusion/baseimage (Ubuntu 14.04)
 * LAMP stack (apache2, mysql, php)
 * Asterisk 13
 * FreePBX 13


### Run your FreePBX image
```bash
docker run --net=host -d -t flaviostutz/freepbx (preferred method due to NAT traversal challenges)
OR
docker run -d -p 5060-5061:5060-5061/udp -p 10000-10100:10000-10100/udp -p 6060:80/tcp -t flaviostutz/freepbx (expect a lot of trouble with NAT traversal - not yet fully solved)
```

Test it out by visiting your hosts ip address in a browser.

### Tips

This image comes with pt-br sounds. To use it, open, at configuration portal, "Settings -> Asterisk SIP Settings -> Chan SIP Settings" and set "language=pt_br" at "Other SIP Settings"


### Fork ME
This is originally a fork of https://bitbucket.org/jmar71n/docker-freepbx.git
Fell free to contribute back!
