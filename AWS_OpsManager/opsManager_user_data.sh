#!/bin/sh -xe
publicHostname=$(curl http://169.254.169.254/latest/meta-data/public-hostname)
privateHostname=$(curl http://169.254.169.254/latest/meta-data/hostname)
echo "Creating repo file for MongoDB installation"
sudo echo -e "[mongodb-org-5.0]  \nname=MongoDB Repository \nbaseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/5.0/x86_64/ \ngpgcheck=1 \nenabled=1 \ngpgkey=https://www.mongodb.org/static/pgp/server-5.0.asc" >> /etc/yum.repos.d/mongodb-org-5.0.repo
sudo yum install -y mongodb-org

sudo mkdir -p /data/appdb
sudo mkdir /headdb
sudo mkdir /backup
sudo mkdir /certs

sudo chown -R mongod:mongod /data
sudo tee /etc/mongod.conf <<EOF
systemLog: 
  destination: file 
  path: /data/appdb/mongodb.log 
  logAppend: true 
storage: 
  dbPath: /data/appdb 
  journal: 
    enabled: true
  wiredTiger:
    engineConfig:
      cacheSizeGB: 1
processManagement:
  fork: true
  timeZoneInfo: /usr/share/zoneinfo
  pidFilePath: /var/run/mongodb/mongod.pid
net:
  bindIp: 127.0.0.1
  port: 27017
setParameter:
  enableLocalhostAuthBypass: false
EOF

sudo -u mongod mongod -f /etc/mongod.conf > /home/ec2-user/mongod.log

# create CA Certificate
mkdir /home/ec2-user/certs
echo -e "# NOT FOR PRODUCTION USE. OpenSSL configuration file for testing. \n# For the CA policy \n[ policy_match ] \ncountryName = match \nstateOrProvinceName = match \norganizationName = match \norganizationalUnitName = optional \ncommonName = supplied \nemailAddress = optional \n[ req ] \ndefault_bits = 4096 \ndefault_keyfile = myTestCertificateKey.pem    ## The default private key file name. \ndefault_md = sha256                           ## Use SHA-256 for Signatures \ndistinguished_name = req_dn \nreq_extensions = v3_req \nx509_extensions = v3_ca # The extentions to add to the self signed cert \n[ v3_req ] \nsubjectKeyIdentifier  = hash \nbasicConstraints = CA:FALSE \nkeyUsage = critical, digitalSignature, keyEncipherment \nnsComment = "OpenSSL Generated Certificate for TESTING only.  NOT FOR PRODUCTION USE." \nextendedKeyUsage  = serverAuth, clientAuth \n[ req_dn ] \ncountryName = DE \ncountryName_default = DE \ncountryName_min = 2 \ncountryName_max = 2 \nstateOrProvinceName = TestCertificateStateName \nstateOrProvinceName_default = TestCertificateStateName \nstateOrProvinceName_max = 64 \nlocalityName = TestCertificateLocalityName \nlocalityName_default = TestCertificateLocalityName \nlocalityName_max = 64 \norganizationName = TestCertificateOrgName \norganizationName_default = TestCertificateOrgName \norganizationName_max = 64 \norganizationalUnitName = Organizational Unit Name (eg, section) \norganizationalUnitName_default = TestCertificateOrgUnitName \norganizationalUnitName_max = 64 \ncommonName = TestCertificateCommonName \ncommonName_max = 64 \n[ v3_ca ] \n# Extensions for a typical CA \nsubjectKeyIdentifier=hash \nbasicConstraints = critical,CA:true \nauthorityKeyIdentifier=keyid:always,issuer:always \n" > certs/openssl-test-ca.cnf
openssl genrsa -out certs/mongodb-test-ca.key 4096
openssl req -new -x509 -days 1826 -key certs/mongodb-test-ca.key -out certs/mongodb-test-ca.crt -config certs/openssl-test-ca.cnf -subj "/C=. /ST=. /L=. /O=. /OU=. /CN=." 
openssl genrsa -out certs/mongodb-test-ia.key 4096
openssl req -new -key certs/mongodb-test-ia.key -out certs/mongodb-test-ia.csr -config certs/openssl-test-ca.cnf -subj "/C=. /ST=. /L=. /O=. /OU=. /CN=."
openssl x509 -sha256 -req -days 730 -in certs/mongodb-test-ia.csr -CA certs/mongodb-test-ca.crt -CAkey certs/mongodb-test-ca.key -set_serial 01 -out certs/mongodb-test-ia.crt -extfile certs/openssl-test-ca.cnf -extensions v3_ca
cat certs/mongodb-test-ca.crt certs/mongodb-test-ca.key  > certs/test-ca.pem

# copy HTTPS PEM file
#sudo mv certs/test-ca.pem /certs/test-ca.pem

curl -OL https://downloads.mongodb.com/on-prem-mms/rpm/mongodb-mms-5.0.1.97.20210805T0614Z-1.x86_64.rpm
sudo rpm -ivh mongodb-mms-5.0.1.97.20210805T0614Z-1.x86_64.rpm
sudo chown -R mongodb-mms:mongodb-mms /headdb
sudo chown -R mongodb-mms:mongodb-mms /backup
sudo chown -R mongodb-mms:mongodb-mms /certs
sudo tee /opt/mongodb/mms/conf/conf-mms.properties <<EOF
mongo.mongoUri=mongodb://127.0.0.1:27017/?maxPoolSize=150&retryWrites=false&retryReads=false
mongo.ssl=false
mms.ignoreInitialUiSetup=true
automation.versions.source=remote
mms.adminEmailAddr=cloud-manager-support@mongodb.com
mms.fromEmailAddr=cloud-manager-support@mongodb.com
mms.mail.hostname=email-smtp.us-east-1.amazonaws.com
mms.mail.port=465
mms.mail.ssl=false
mms.mail.transport=smtp
mms.minimumTLSVersion=TLSv1.2
mms.replyToEmailAddr=cloud-manager-support@mongodb.com
mms.centralUrl=http://$${publicHostname}:8080
mms.https.dualConnectors = true
mms.https.PEMKeyFile = /certs/test-ca.pem
mms.mongoDbUsage.ui.enabled=true
mms.publicApi.whitelistEnabled = false
EOF
sudo service mongodb-mms start > /home/ec2-user/opsmanager.log