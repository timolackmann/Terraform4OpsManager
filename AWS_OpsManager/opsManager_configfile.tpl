#
# Ops Manager Configuration File
#

# #####################################
# Ops Manager MongoDB storage settings
#
# The following MongoURI parameters are for configuring the MongoDB storage
# that backs the Ops Manager server's functionality. By default. the Ops Manager server is
# configured to expect a local standalone instance of MongoDB running on
# the default port 27017.
#
# For more advanced configurations of the backing MongoDB store, such as
# running with replication or authentication, please refer to the
# documentation at https://docs.opsmanager.mongodb.com/current/tutorial/prepare-backing-mongodb-instances/
# ####################################
mongo.mongoUri=mongodb://127.0.0.1:27017/?maxPoolSize=150&retryWrites=false&retryReads=false
mongo.ssl=false

# #####################################
# MongoDB SSL Settings (Optional)
# The following parameters are for configuring the SSL certificates to be
# used by the Ops Manager server to connect to its MongoDB backing stores. These
# settings are only applied to the mongoUri connection above when
# `mongo.ssl` is set to true.
# CAFile - the certificate of the CA that issued the MongoDB server certificate(s)
# PEMKeyFile - a client certificate containing a certificate and private key
#             (needed when MongoDB is running with --sslCAFile)
# PEMKeyFilePassword - required if the `PEMKeyFile` contains an encrypted private key
# ####################################
mongodb.ssl.CAFile=
mongodb.ssl.PEMKeyFile=
mongodb.ssl.PEMKeyFilePassword=

# #####################################
# Kerberos Module (Optional)
#
# The following parameters are for configuring Ops Manager to use Kerberos to connection
# to its MongoDB backing stores.
#
# jvm.java.security.krb5.conf: This should be the path to the Kerberos conf file. The value will be set to JVM's
# java.security.krb5.conf.
#
# jvm.java.security.krb5.kdc: This should be the IP/FQDN of the KDC server. The value will be set to JVM's
# java.security.krb5.kdc.
#
# jvm.java.security.krb5.realm: This is the default REALM for Kerberos. It is being used for JVM's
# java.security.krb5.realm.
#
# mms.kerberos.principal: The principal we used to authenticate with MongoDB. This should be the exact same user
# on the mongoUri above.
#
# mms.kerberos.keyTab: The absolute path to the keytab file for the principal.
#
# mms.kerberos.debug: The debug flag to output more information on Kerberos authentication process.
#
# Please note, all the parameters are required for Kerberos authentication, except jvm.java.security.krb5.conf and
# mms.kerberos.debug. The mechanism will not be functioning if any of the setting value is missing.
#
# Assume your kdc server FQDN is kdc.example.com, your Kerberos default realm is: EXAMPLE.COM,
# the host running Ops Manager is mmsweb.example.com, the Kerberos for Ops Manager is mms/mmsweb.example.com@EXAMPLE.com,
# And you have a keytab file for mms/mmsweb.example.com@EXAMPLE.COM located at /path/to/mms.keytab, then the
# configurations would be:
#       jvm.java.security.krb5.kdc=kdc.example.com
#       jvm.java.security.krb5.realm=EXAMPLE.COM
#       mms.kerberos.principal=mms/mmsweb.example.com@EXAMPLE.COM
#       mms.kerberos.keyTab=/path/to/mms.keytab
#       mms.kerberos.debug=false
#
# ####################################
jvm.java.security.krb5.conf=
jvm.java.security.krb5.kdc=
jvm.java.security.krb5.realm=
mms.kerberos.principal=
mms.kerberos.keyTab=
mms.kerberos.debug=

# #####################################
# Instance Parameter Overrides
#
# In this section include any parameters to be used on this instance
# of Ops Manager. These parameters will override any global configuration
# stored in the Ops Manager database.
#
# See https://docs.opsmanager.mongodb.com/current/reference/configuration/
# for additional information
#
# #####################################
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
mms.centralUrl=${OpsManagerUrl}
mms.https.PEMKeyFile = /certs/test-ca.pem
mms.https.dualConnectors = true
mms.mongoDbUsage.ui.enabled=true
mms.publicApi.whitelistEnabled = false