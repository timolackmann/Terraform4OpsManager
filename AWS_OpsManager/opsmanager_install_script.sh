#!/bin/sh
sudo mv repo_file /etc/yum.repos.d/mongodb-org-4.4.repo
sudo yum install -y mongodb-org
sudo mkdir -p /data/appdb
sudo mkdir /headdb
sudo mkdir /backup
sudo mkdir /certs

mkdir /home/ec2-user/certs
sudo chown -R mongod:mongod /data
sudo mv config_file /etc/mongod.conf

# create CA Certificate
mv openssl-test-ca.cnf certs/openssl-test-ca.cnf
openssl genrsa -out certs/mongodb-test-ca.key 4096
openssl req -new -x509 -days 1826 -key certs/mongodb-test-ca.key -out certs/mongodb-test-ca.crt -config certs/openssl-test-ca.cnf -subj "/C=. /ST=. /L=. /O=. /OU=. /CN=." 
openssl genrsa -out certs/mongodb-test-ia.key 4096
openssl req -new -key certs/mongodb-test-ia.key -out certs/mongodb-test-ia.csr -config certs/openssl-test-ca.cnf -subj "/C=. /ST=. /L=. /O=. /OU=. /CN=."
openssl x509 -sha256 -req -days 730 -in certs/mongodb-test-ia.csr -CA certs/mongodb-test-ca.crt -CAkey certs/mongodb-test-ca.key -set_serial 01 -out certs/mongodb-test-ia.crt -extfile certs/openssl-test-ca.cnf -extensions v3_ca
cat certs/mongodb-test-ca.crt certs/mongodb-test-ca.key  > certs/test-ca.pem

# copy HTTPS PEM file
sudo mv certs/test-ca.pem /certs/test-ca.pem

sudo -u mongod mongod -f /etc/mongod.conf
curl -OL https://downloads.mongodb.com/on-prem-mms/rpm/mongodb-mms-5.0.1.97.20210805T0614Z-1.x86_64.rpm
sudo rpm -ivh mongodb-mms-5.0.1.97.20210805T0614Z-1.x86_64.rpm
sudo chown -R mongodb-mms:mongodb-mms /headdb
sudo chown -R mongodb-mms:mongodb-mms /backup
sudo chown -R mongodb-mms:mongodb-mms /certs
sudo mv opsmanager_config /opt/mongodb/mms/conf/conf-mms.properties
sudo service mongodb-mms start
