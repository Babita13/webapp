#!/bin/bash
#mount secondary disk to store logs
mkfs -t ext3 /dev/xvdb
mount /dev/xvdb /var/log
# install httpd
apt-get update
apt-get -y install apache2
service apache start


