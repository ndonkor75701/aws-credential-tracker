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

def CheckCertificatesForUser(client, user, periodInDays):
    #print("Retrieving certificates to disable")
    certsToDisable = []
    certList = client.list_signing_certificates(UserName=user)["Certificates"]
    #print("certList: {0}".format(certList))

    for cert in certList:
        #print("cert: {0}".format(cert))

        #createdDate = dateutil.parser.parse(key["CreateDate"])
        dateDiff = datetime.now().date() - cert["UploadDate"].date()

        if(dateDiff.days > int(periodInDays) and cert["Status"] == "Active"):
            certsToDisable.append(cert["CertificateId"])

    return certsToDisable


def lambda_handler(event, context):
    stateObject = event
    #print("Received stateObject: " + json.dumps(stateObject, indent=2))

    iam = boto3.client('iam')
    certsToDisable = []
    certsDisabled = []

    try:
        usersToRemediate = stateObject["users"]

        for userToRemediate in usersToRemediate:
            #print("user: {0}".format(userToRemediate))
            certsToDisable = CheckCertificatesForUser(
                client = iam,
                user = userToRemediate,
                periodInDays = os.environ["periodInDays"])

            for cert in certsToDisable:
                certificateId = cert
                #print("CertificateId: {0}".format(certificateId))
                response = iam.update_signing_certificate(
                    UserName=userToRemediate,
                    CertificateId=certificateId,
                    Status="Inactive")

                disabledCert = {userToRemediate : certificateId}
                certsDisabled.append(disabledCert)

        disabledCerts = {"certsDisabled" : certsDisabled}
        stateObject.update(certsDisabled)

        stateObject["taskStatus"] = "OK"
        stateObject["lastErrorMessage"] = None

        return stateObject
    except Exception as e:
        stateObject["taskStatus"] = "FAILED"
        stateObject["lastErrorMessage"] = "remediate-findings: Please review CloudWatch logs for further details"
        print("remediate-findings: {0}".format(e))
        return stateObject
