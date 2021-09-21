#!/bin/sh
sudo mv repo_file /etc/yum.repos.d/mongodb-org-4.4.repo
sudo yum install -y mongodb-org
sudo mkdir -p /data/appdb
sudo mkdir /headdb
sudo chown -R mongod:mongod /data
sudo mv config_file /etc/mongod.conf
sudo -u mongod mongod -f /etc/mongod.conf
curl -OL https://downloads.mongodb.com/on-prem-mms/rpm/mongodb-mms-5.0.1.97.20210805T0614Z-1.x86_64.rpm
sudo rpm -ivh mongodb-mms-5.0.1.97.20210805T0614Z-1.x86_64.rpm
sudo chown -R mongodb-mms:mongodb-mms /headdb
sudo mv opsmanager_config /opt/mongodb/mms/conf/conf-mms.properties
sudo service mongodb-mms start
