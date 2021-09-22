import requests
import sys
import requests
import json
from requests.auth import HTTPDigestAuth
import logging
import time


def createUser(host, username, password, firstname, lastname):
    url = "http://{}:8080/api/public/v1.0/unauth/users".format(host)

    payload = json.dumps({
        "username": username,
        "password": password,
        "firstName": firstname,
        "lastName": lastname
    })
    headers = {
        'Content-Type': 'application/json'
    }

    response = requests.request("POST", url, headers=headers, data=payload)
    # print(response.text)
    # text = '{"programmaticApiKey":{"desc":"Automatically generated Global API key","id":"6149e4700ad4f05225d6d855","links":[{"href":"http://ec2-18-184-79-224.eu-central-1.compute.amazonaws.com:8080/api/public/v1.0/orgs/null/apiKeys/6149e4700ad4f05225d6d855","rel":"self"}],"privateKey":"4f82f471-3e75-4104-a480-45d996b74f00","publicKey":"dsnslhgt","roles":[{"roleName":"GLOBAL_OWNER"}]},"user":{"emailAddress":"timo.lackmann@example.com","firstName":"Timo","id":"6149e4700ad4f05225d6d853","lastName":"Lackmann","links":[{"href":"http://ec2-18-184-79-224.eu-central-1.compute.amazonaws.com:8080/api/public/v1.0/users/6149e4700ad4f05225d6d853","rel":"self"},{"href":"http://ec2-18-184-79-224.eu-central-1.compute.amazonaws.com:8080/api/public/v1.0/users/6149e4700ad4f05225d6d853/whitelist","rel":"http://cloud.mongodb.com/whitelist"},{"href":"http://ec2-18-184-79-224.eu-central-1.compute.amazonaws.com:8080/api/public/v1.0/users/6149e4700ad4f05225d6d853/accessList","rel":"http://cloud.mongodb.com/accessList"}],"roles":[{"roleName":"GLOBAL_OWNER"}],"teamIds":[],"username":"timo.lackmann@example.com"}}'

    jsonInfo = json.loads(response.text)
    global privateKey
    privateKey = jsonInfo['programmaticApiKey']['privateKey']
    global publicKey
    publicKey = jsonInfo['programmaticApiKey']['publicKey']
#    print(privateKey)
#    print(publicKey)


def createProject(host):
    url = "http://{}:8080/api/public/v1.0/groups".format(host)

    payload = json.dumps({
        "name": "Demo"
    })
    headers = {
        'Content-Type': 'application/json'
    }

    response = requests.request("POST", url, headers=headers,
                                data=payload, auth=HTTPDigestAuth(publicKey, privateKey))
    # print(response.text)

    # text = '{"activeAgentCount":0,"agentApiKey":"6149f6960ad4f05225d6d95256748b3a168d95dd0c7706e813512466","hostCounts":{"arbiter":0,"config":0,"master":0,"mongos":0,"primary":0,"secondary":0,"slave":0},"id":"6149f6960ad4f05225d6d943","links":[{"href":"http://ec2-18-184-79-224.eu-central-1.compute.amazonaws.com:8080/api/public/v1.0/groups/6149f6960ad4f05225d6d943","rel":"self"},{"href":"http://ec2-18-184-79-224.eu-central-1.compute.amazonaws.com:8080/api/public/v1.0/groups/6149f6960ad4f05225d6d943/hosts","rel":"http://cloud.mongodb.com/hosts"},{"href":"http://ec2-18-184-79-224.eu-central-1.compute.amazonaws.com:8080/api/public/v1.0/groups/6149f6960ad4f05225d6d943/users","rel":"http://cloud.mongodb.com/users"},{"href":"http://ec2-18-184-79-224.eu-central-1.compute.amazonaws.com:8080/api/public/v1.0/groups/6149f6960ad4f05225d6d943/clusters","rel":"http://cloud.mongodb.com/clusters"},{"href":"http://ec2-18-184-79-224.eu-central-1.compute.amazonaws.com:8080/api/public/v1.0/groups/6149f6960ad4f05225d6d943/alertConfigs","rel":"http://cloud.mongodb.com/alertConfigs"},{"href":"http://ec2-18-184-79-224.eu-central-1.compute.amazonaws.com:8080/api/public/v1.0/groups/6149f6960ad4f05225d6d943/alerts","rel":"http://cloud.mongodb.com/alerts"},{"href":"http://ec2-18-184-79-224.eu-central-1.compute.amazonaws.com:8080/api/public/v1.0/groups/6149f6960ad4f05225d6d943/backupConfigs","rel":"http://cloud.mongodb.com/backupConfigs"},{"href":"http://ec2-18-184-79-224.eu-central-1.compute.amazonaws.com:8080/api/public/v1.0/groups/6149f6960ad4f05225d6d943/agents","rel":"http://cloud.mongodb.com/agents"}],"name":"Demo","orgId":"6149f6960ad4f05225d6d944","publicApiEnabled":true,"replicaSetCount":0,"shardCount":0,"tags":[]}'
    jsonInfo = json.loads(response.text)
    global mmsGroupId
    mmsGroupId = jsonInfo['id']
    global mmsApiKey
    mmsApiKey = jsonInfo['agentApiKey']


def setHeadDirectory(host, internalDNS):
    url = "http://{}:8080/api/public/v1.0/admin/backup/daemon/configs/{}".format(
        host, internalDNS)

    payload = json.dumps({
        "configured": True,
        "machine": {
            "machine": internalDNS,
            "headRootDirectory": "/headdb"
        }
    })
    headers = {
        'Content-Type': 'application/json'
    }

    response = requests.request("PUT", url, headers=headers,
                                data=payload, auth=HTTPDigestAuth(publicKey, privateKey))

    logging.debug("url: {} /n payload: {} /n response: {}".format(url,
                                                                  payload, response.text))


def setFileStore(host):
    url = "http://{}:8080/api/public/v1.0/admin/backup/snapshot/fileSystemConfigs".format(
        host)
    payload = json.dumps({
        "assignmentEnabled": True,
        "id": "SnapshotStorage",
        "storePath": "/backup",
        "mmapv1CompressionSetting": "GZIP",
        "wtCompressionSetting": "GZIP"
    })
    headers = {
        'Content-Type': 'application/json'
    }

    response = requests.request("POST", url, headers=headers,
                                data=payload, auth=HTTPDigestAuth(publicKey, privateKey))


def setOplogStore(host):
    url = "http://{}:8080/api/public/v1.0/admin/backup/oplog/mongoConfigs".format(
        host)
    payload = json.dumps({
        "assignmentEnabled": True,
        "id": "OplogStore",
        "uri": "mongodb://localhost:27017"
    })
    headers = {
        'Content-Type': 'application/json'
    }

    response = requests.request("POST", url, headers=headers,
                                data=payload, auth=HTTPDigestAuth(publicKey, privateKey))


if __name__ == "__main__":

    logging.basicConfig(filename='logs.log', level=logging.DEBUG)
    privateKey = ''
    publicKey = ''
    mmsGroupId = ''
    mmsApiKey = ''
    input_json = sys.stdin.read()
    input_dict = json.loads(input_json)
    host = input_dict.get('host')
    internalDNS = input_dict.get('internalDns')
    username = input_dict.get('username')
    password = input_dict.get('password')
    firstname = input_dict.get('firstname')
    lastname = input_dict.get('lastname')

    logging.debug("inputJson: {}".format(
        input_json))
    logging.debug("inputDic: {}".format(
        input_dict))
    logging.debug("host:{}".format(
        host))
    logging.debug("internalDNS: {}".format(
        internalDNS))

    createUser(host, username, password, firstname, lastname)
    createProject(host)
    time.sleep(10)
    setHeadDirectory(host, internalDNS)
    setFileStore(host)
    setOplogStore(host)
    sys.stdout.write(json.dumps(
        {'mmsGroupId': str(mmsGroupId), 'mmsApiKey': str(mmsApiKey)}))
