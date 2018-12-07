import json
import boto3
import sys
import os
import time
import dateutil.parser
from datetime import datetime

#print('Loading function')

# Incoming stateObject structure
"""
stateObject = {
    "generatedDate" : {
        "year" : datetime.date.today().year,
        "month" : datetime.date.today().month,
        "day" : datetime.date.today().day
    },
    "taskStatus" : None, # the status of the last task used for manipulating choice states in the Step Function workflow
    "lastErrorMessage" : None,
    "generateWaitTime" : os.environ['generateWaitTime'],
    "queryExecutionId" : from previous state
}
"""

def CheckAccessKeysForUser(client, user, periodInDays):
    #print("Retrieving access keys to disable")
    accessKeysToDisable = []
    keyList = client.list_access_keys(UserName=user)["AccessKeyMetadata"]
    #print("keyList: {0}".format(keyList))

    for key in keyList:
        #print("key: {0}".format(key))

        keyLastUsed = client.get_access_key_last_used(AccessKeyId = key["AccessKeyId"])
        #print("keyLastUsed: {0}".format(keyLastUsed))
        #createdDate = dateutil.parser.parse(key["CreateDate"])
        dateDiff = datetime.now().date() - keyLastUsed["AccessKeyLastUsed"]["LastUsedDate"].date()

        if(dateDiff.days > int(periodInDays) and key["Status"] == "Active"):
            accessKeysToDisable.append(key["AccessKeyId"])

    return accessKeysToDisable


def lambda_handler(event, context):
    stateObject = event
    #print("Received stateObject: " + json.dumps(stateObject, indent=2))
    
    iam = boto3.client('iam')
    accessKeysDisabled = []
    try:
        usersToRemediate = stateObject["users"]

        for userToRemediate in usersToRemediate:
            #print("user: {0}".format(userToRemediate))
            accessKeysToDisable = CheckAccessKeysForUser(
                client = iam,
                user = userToRemediate,
                periodInDays = os.environ["periodInDays"])

            for accessKey in accessKeysToDisable:
                #print("accessKey: {0}".format(accessKey))
                response = iam.update_access_key(
                    UserName=userToRemediate,
                    AccessKeyId = accessKey,
                    Status = "Inactive")

                disabledKey = {userToRemediate : accessKey}
                accessKeysDisabled.append(disabledKey)

        disabledKeys = {"accessKeysDisabled" : accessKeysDisabled}
        stateObject.update(disabledKeys)

        stateObject["taskStatus"] = "OK"
        stateObject["lastErrorMessage"] = None

        return stateObject
    except Exception as e:
        stateObject["taskStatus"] = "FAILED"
        stateObject["lastErrorMessage"] = "remediate-findings: Please review CloudWatch logs for further details"
        print("remediate-findings: {0}".format(e))
        return stateObject
