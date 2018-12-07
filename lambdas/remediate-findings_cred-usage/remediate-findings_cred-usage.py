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


def lambda_handler(event, context):
    stateObject = event
    #print("Received stateObject: " + json.dumps(stateObject, indent=2))

    iam = boto3.client('iam')
    certsDisabled = []
    try:
        usersToRemediate = stateObject["users"]

        for userToRemediate in usersToRemediate:
            #print("user: {0}".format(userToRemediate))
            disabledConsoleUser = iam.delete_login_profile(
                UserName=userToRemediate
                )
            #print("DeleteLoginProfileResponse: {0}".format(disabledConsoleUser))

        stateObject["taskStatus"] = "OK"
        stateObject["lastErrorMessage"] = None

        return stateObject
    except Exception as e:
        stateObject["taskStatus"] = "FAILED"
        stateObject["lastErrorMessage"] = "remediate-findings: Please review CloudWatch logs for further details"
        print("remediate-findings: {0}".format(e))
        return stateObject
