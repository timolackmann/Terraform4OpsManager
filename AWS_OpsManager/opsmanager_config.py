import requests
import sys
import json
from requests.auth import HTTPDigestAuth
import logging
import time
import socket
import operator
import os


def checkOpsManager(host):
    a_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    location = (host, 8080)
    result_of_check = a_socket.connect_ex(location)

    if result_of_check == 0:
        logging.debug("Port is open")
        a_socket.close()
        return True
    else:
        logging.debug("Port is not open")
        a_socket.close()
        return False


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

    jsonInfo = json.loads(response.text)
    global privateKey
    privateKey = jsonInfo['programmaticApiKey']['privateKey']
    global publicKey
    publicKey = jsonInfo['programmaticApiKey']['publicKey']


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

    jsonInfo = json.loads(response.text)
    global mmsGroupId
    mmsGroupId = jsonInfo['id']
    global mmsApiKey
    mmsApiKey = jsonInfo['agentApiKey']

    file = open("agentConfig.json", "w")
    file.write(json.dumps({'mmsGroupId': mmsGroupId, 'mmsApiKey': mmsApiKey}))
    file.close


def setHeadDirectory(host, internalDNS):
    url = "http://{}:8080/api/public/v1.0/admin/backup/daemon/configs/{}".format(
        host, internalDNS)

    payload = json.dumps({
        "configured": True,
        "machine": {
            "machine": internalDNS,
            "headRootDirectory": "/headdb/"
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

# Check if Ops Manager is up and available
    while operator.not_(checkOpsManager(host)):
        time.sleep(90)

    if (os.path.isfile("agentConfig.json")):
        json_file = open("agentConfig.json")
        agentParameters = json.load(json_file)
        json_file.close()

        mmsGroupId = agentParameters["mmsGroupId"]
        mmsApiKey = agentParameters["mmsApiKey"]
        sys.stdout.write(json.dumps(
            {'mmsGroupId': str(mmsGroupId), 'mmsApiKey': str(mmsApiKey)}))
    else:
        createUser(host, username, password, firstname, lastname)
        createProject(host)
        time.sleep(10)
        setHeadDirectory(host, internalDNS)
        setFileStore(host)
        setOplogStore(host)
        sys.stdout.write(json.dumps(
            {'mmsGroupId': str(mmsGroupId), 'mmsApiKey': str(mmsApiKey)}))
