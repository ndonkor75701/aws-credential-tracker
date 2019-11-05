import json
import boto3
import datetime
import os

#print('Loading function')

# Generate a new credentials report
def generate_credential_report():
    iam = boto3.client('iam')
    response = iam.generate_credential_report()
    return response

def lambda_handler(event, context):
    stateObject = {
        "requestedDate" : str(datetime.datetime.now()),
        "taskStatus" : None, # the status of the last task used for manipulating choice states in the Step Function workflow
        "lastErrorMessage" : None,
        "generateWaitTime" : os.environ["generateWaitTime"]
    }

    try:
        response = generate_credential_report()
        # print(response)

        status = response["State"]
        print("Credentials report is in the status of {0}".format(status))

        stateObject["taskStatus"] = "OK"

        return stateObject
    except Exception as e:
        stateObject["taskStatus"] = "FAILED"
        stateObject["lastErrorMessage"] = "Generate-report: Failed to generate credential report"
        print("generate-report: {0}".format(e))
        return stateObject
