# FreePBX on Docker

[<img src="https://img.shields.io/docker/pulls/flaviostutz/freepbx"/>](https://hub.docker.com/r/flaviostutz/freepbx)
[<img src="https://img.shields.io/docker/automated/flaviostutz/freepbx"/>](https://hub.docker.com/r/flaviostutz/freepbx)

FreePBX container image for running a complete Asterisk server.

With this container you can create a telephony system in your office or house with integration among various office branches and integration to external VOIP providers with features such as call recording and IVR (interactive voice response) Menus.

If "Apply" is taking too long, disable "Module signature check" (if you know what you're doing).

Security considerations:

* Turn off SIP Guest on Settings -> Sip settings

* Enable fail2ban with ENV FAIL2BAN_ENABLE=true (you have to run this container in privileged mode for this to work)

Thanks to https://github.com/tiredofit/docker-freepbx for various insights on the new Asterisk 15 installation.

This image is used in production deployments.

## Image includes

* Asterisk 16
* FreePBX 15
* Modules: IVR, Time Conditions, Backup, Recording
* Automatic backup script


## Usage

* Create docker-compose.yml

```yml
version: '3.3'
services:
  freepbx:
    image: flaviostutz/freepbx
    ports:
      - 8080:80
      - 5060:5060/udp
      - 5160:5160/udp
      - 3306:3306
      - 18000-18100:18000-18100/udp
    restart: always
    environment:
      - ADMIN_PASSWORD=admin123
    volumes:
      - backup:/backup
      - recordings:/var/spool/asterisk/monitor

volumes:
  backup:
  recordings:
```

* Run ```docker-compose up -d```

* Open admin panel at http://localhost:8080/admin/

## Sample host preparation

* Install Ubuntu 18.04

* Install Docker + Docker Compose

* Configure network

  * edit /etc/netplan/50-cloud-init.yaml

```yml
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

## ENVs

* **ADMIN_PASSWORD** - GUI password for user 'admin'. required
* **RTP_START** - port range from for RTP. defaults to 18000
* **RTP_FINISH** - port range to for RTP. defaults to 18100
* **SIP_NAT_IP** - SIP NAT Public IP for calls. defaults to ip got from "curl ifconfig.me"
* **USE_CHAN_SIP** - if true, disables pjsip and enables legacy chan_sip engine. defaults to false, meaning it will use pjsip engine by default
* **ENABLE_AUTO_RESTORE** - if true, when a new container instance is run, it will try to restore an existing backup from /backup/[FreePBX ver]/new.tar.gz. This backup is created each one hour automatically. This is useful when creating a new container instance (all MYSQL and other data is lost), so that your configurations are kept. defaults to true
* **ENABLE_DELETE_OLD_RECORDINGS** - Delete all recordings older than 60 days if enabled. defaults to true

* **FAIL2BAN_ENABLE** - enable fail2ban on asterisk logs. If set, this container needs to run in "privileged" mode because it needs to change iptables configurations. defaults to 'false'
* **FAIL2BAN_FINDTIME** - Time window in which failed retries will be evaluated. Defaults to '600' seconds
* **FAIL2BAN_MAXRETRY** - Number of failed attempts inside "findtime" window. Defaults to '15' retries
* **FAIL2BAN_BANTIME** - Time a specific IP will be banned after too many failed retries. Defaults to '259200' seconds.
* **FAIL2BAN_IGNOREIPS** - Comma/space separated list of IPs to be ignored on fail2ban (will never ban)

* **DISABLE_SIGNATURE_CHECK** - Disables module signature checks so that configuration reloads are way faster. Disable if you know what module signing protection means. defaults to false
* **CERTIFICATE_DOMAIN** - certificate domain name when generating site certs with let's encrypt. this is used to locate certificated by name in /etc/asterisk/keys/ and configure Apache to use it automatically. defaults to ''

## Fail2Ban

* Enter freepbx container with `docker exec -it [containerid] bash`
* For unbanning
  * Run `fail2ban-client set sshd unbanip 192.168.1.69` OR
  * Run `fail2ban-client unban --all`
* For listing all banned ips:
  * Run `fail2ban-client status asterisk-iptables`

## Volumes

* **/backup** - keeps new.tar.gz and old.tar.gz automatic backups. Default backup job stores backup there too. Backups are store inside a directory with freepbx version. Backup restore between different versions is not supported by Freepbx.
* **/var/spool/asterisk/monitor** - call recording storage location

* **/etc/asterisk/keys** - Let's Encrypt and self signed certificates pub/private keys generated in pbxadmin

