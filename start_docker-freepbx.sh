#!/bin/bash

# Credit -> https://github.com/BetterVoice/freeswitch-container

CID=$(sudo docker run -d -p 5060-5061:5060-5061/udp -p 8080:80/tcp -t jmar71n/freepbx)

CIP=$(sudo docker inspect --format='{{.NetworkSettings.IPAddress}}' $CID)

sudo iptables -A DOCKER -t nat -p udp -m udp ! -i docker0 --dport 10000:20000 -j DNAT --to-destination $CIP:10000-20000
sudo iptables -A DOCKER -p udp -m udp -d $CIP/32 ! -i docker0 -o docker0 --dport 10000:20000 -j ACCEPT
sudo iptables -A POSTROUTING -t nat -p udp -m udp -s $CIP/32 -d $CIP/32 --dport 10000:20000 -j MASQUERADE
