import json
import boto3
import sys
import os
import datetime
import dateutil
import botocore

# print('Loading function')

# Incoming stateObject structure
"""
stateObject = {
    "requestedDate" : {
        "year" : datetime.date.today().year,
        "month" : datetime.date.today().month,
        "day" : datetime.date.today().day
    },
    "taskStatus" : None, # the status of the last task used for manipulating choice states in the Step Function workflow
    "lastErrorMessage" : None
    "generateWaitTime" : os.environ['generateWaitTime']
}
"""

# Get the credentials report
def get_credential_report():
    iam = boto3.client('iam')
    response = iam.get_credential_report()
    return response

# Check the status of the report generation
def generate_credential_report():
    iam = boto3.client('iam')
    response = iam.generate_credential_report()
    return response

def lambda_handler(event, context):
    stateObject = event
    # print("Received stateObject: " + json.dumps(stateObject, indent=2))

    try:
        generateResponse = generate_credential_report()
        reportStatus = generateResponse["State"]
        # print("Report status: {0}".format(reportStatus))

        if (reportStatus == "COMPLETE"):

            getResponse = get_credential_report()

            if (getResponse != None or getResponse != {}):

                content = getResponse["Content"]
                # print("content: {0}".format(content))

                generatedDate = getResponse["GeneratedTime"]
                # print("generatedDate: {0}".format(generatedDate))

                year = generatedDate.year
                month = generatedDate.month
                day = generatedDate.day
                time = "{0:02}{1:02}{2:02}".format(generatedDate.hour, generatedDate.minute, generatedDate.second)

                # Check if a new report was generated
                requested_generated = generatedDate.replace(tzinfo=None) - dateutil.parser.parse(stateObject["requestedDate"])
                # print("generated: {0} - requested: {1} - reportDateDiff: {2}".format(generatedDate, dateutil.parser.parse(stateObject["requestedDate"]), requested_generated.seconds))

                key = "{0}year={1}/month={2}/day={3}/time={4}/{5}".format(os.environ['prefix'], year, month, day, time, os.environ['fileName'])
                # print("Key: {0}".format(key))

                s3 = boto3.client('s3')
                previouslyDownloaded = None

                try:
                    object = s3.head_object(Bucket=os.environ['bucketName'], Key=key)
                    if(object != "" or object != {} ):
                        # print("objectMetadata: {0}".format(json.dumps(object)))
                        previouslyDownloaded = True
                except botocore.exceptions.ClientError as e:
                    if e.response['Error']['Code'] == "404":
                        previouslyDownloaded = False
                    if e.response['Error']['Code'] == "403":
                        previouslyDownloaded = False
                    else:
                        raise

                # print("previouslyDownloaded: {0}".format(previouslyDownloaded))
                if (requested_generated.seconds >= 0 and not previouslyDownloaded):
                    comment = "New report was generated on this run - The report has been downloaded and saved to S3"
                    # print(comment)

                    # Upload report to S3
                    response = s3.put_object(Bucket=os.environ['bucketName'], Key=key, Body=content)
                    # print("S3 Response: {0}".format(response))

                    dateGenerated = {
                        "generatedDate":str(generatedDate),
                        "comment" : comment
                        }

                    stateObject.update(dateGenerated)

                else:
                    comment = "A new report was not generate on this run. Results will be based on the report generated at {0}".format(generatedDate)
                    # print(comment)

                    dateGenerated = {
                        "generatedDate":str(generatedDate),
                        "comment" : comment
                        }

                    stateObject.update(dateGenerated)

                stateObject["taskStatus"] = "OK"
                stateObject["lastErrorMessage"] = None

            else:
                stateObject["taskStatus"] = "FAILED"
                stateObject["lastErrorMessage"] = "download-report: Failed to download report because no content was returned"

        else:
            stateObject["taskStatus"] = "WAIT"
            stateObject["lastErrorMessage"] = None

        return stateObject

    except Exception as e:
        stateObject["taskStatus"] = "FAILED"
        stateObject["lastErrorMessage"] = "download-report: Failed to download report.  Please review CloudWatch logs for further details"
        print("download-report: {0}".format(e))
        return stateObject
