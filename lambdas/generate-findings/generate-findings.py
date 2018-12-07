import json
import boto3
import sys
import os
import datetime
import dateutil

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
    "lastErrorMessage" : None
    "generateWaitTime" : os.environ['generateWaitTime']
}
"""

def lambda_handler(event, context):
    stateObject = event
    #print("Received stateObject: " + json.dumps(stateObject, indent=2))
    athena = boto3.client('athena')
    namedQueryResponse = {}
    generatedDate = dateutil.parser.parse(stateObject["generatedDate"])
    year = generatedDate.year
    month = generatedDate.month
    day = generatedDate.day
    time = "{0:02}{1:02}{2:02}".format(generatedDate.hour, generatedDate.minute, generatedDate.second)
    periodInDays = os.environ["periodInDays"]
    ##print("event: {0}".format(json.dumps(event)))

    try:
        findingsOutputPath = os.environ["{0}OutputPath".format(os.environ["namedQuery"])]
        namedQuery_name = os.environ["namedQuery"]
        namedQueryId = os.environ[namedQuery_name]

        #print("namedQueryId:{0} findingsOutputPath:{1}".format(namedQueryId, findingsOutputPath))

        namedQuery = athena.get_named_query(NamedQueryId=namedQueryId)
        #print("namedQuery: {0}".format(namedQuery))

        queryString = namedQuery["NamedQuery"]["QueryString"].format(periodInDays, year, month, day, time)
        #print("queryString: {0}".format(queryString))

        if(namedQuery != "" or namedQuery != {}):
            #Execute the query
            if(os.environ["encryptionOption"] == "NONE"):
                namedQueryResponse = athena.start_query_execution(
                    QueryString = queryString,
                    QueryExecutionContext = {
                        "Database": namedQuery["NamedQuery"]["Database"]
                    },
                    ResultConfiguration = {
                        "OutputLocation": "s3://{0}/{1}".format(os.environ["bucketName"], findingsOutputPath)
                    }
                )
            else:
                # Apply encryption if specified
                namedQueryResponse = athena.start_query_execution(
                    QueryString = queryString,
                    QueryExecutionContext = {
                        "Database": namedQuery["NamedQuery"]["Database"]
                    },
                    ResultConfiguration = {
                        "OutputLocation": "s3://{0}/{1}".format(os.environ["bucketName"], findingsOutputPath),
                        "EncryptionConfiguration": {
                            "EncryptionOption": os.environ["encryptionOption"], # 'SSE_S3'|'SSE_KMS'|'CSE_KMS'
                            "KmsKey": os.environ["kmsKey"]
                        }
                    }
                )

            #print("namedQueryResponse: {0}".format(json.dumps(namedQueryResponse)))

            if(namedQueryResponse != "" or namedQueryResponse != {}):

                #Update state object with query execution details
                queryExecutionId = {"queryExecutionId" : namedQueryResponse["QueryExecutionId"]}

                stateObject.update(queryExecutionId)

                stateObject["taskStatus"] = "OK"
                stateObject["lastErrorMessage"] = None
            else:
                stateObject["taskStatus"] = "FAILED"
                stateObject["lastErrorMessage"] = "generate-findings: Failed to get named query response for {0}".format(os.environ["namedQuery"])
        else:
            stateObject["taskStatus"] = "FAILED"
            stateObject["lastErrorMessage"] = "generate-findings: Failed to get named query ID for {0}".format(os.environ["namedQuery"])

        return stateObject
    except Exception as e:
        stateObject["taskStatus"] = "FAILED"
        stateObject["lastErrorMessage"] = "generate-findings: Please review CloudWatch logs for further details"
        print("generate-findings: {0}".format(e))
        return stateObject
