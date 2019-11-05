import json
import boto3
import sys
import os
import time

print('Loading function')

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

# This function initialises the report by making sure the table exists and reloading the partitions before generating findings
def lambda_handler(event, context):
    stateObject = event
    print("Received stateObject: " + json.dumps(stateObject, indent=2))

    athena = boto3.client('athena')
    createTableResponse = {}

    try:
        #get the named queries
        createTableQuery = athena.get_named_query(NamedQueryId=os.environ["credentialsReport"])

        print("createTableQuery: {0}".format(json.dumps(createTableQuery)))

        if(createTableQuery != None or createTableQuery != {}):
            # Run the create table query
            if(os.environ["encryptionOption"] == "NONE"):
                createTableResponse = athena.start_query_execution(
                    QueryString = createTableQuery["NamedQuery"]["QueryString"],
                    QueryExecutionContext={
                        "Database": createTableQuery["NamedQuery"]["Database"]
                    },
                    ResultConfiguration={
                        "OutputLocation": "s3://{0}/{1}".format(os.environ["bucketName"], os.environ["credentialsReportOutputPath"])
                    }
                )
            else:
                # Apply encryption if specified
                createTableResponse = athena.start_query_execution(
                    QueryString = createTableQuery["NamedQuery"]["QueryString"],
                    QueryExecutionContext={
                        "Database": createTableQuery["NamedQuery"]["Database"]
                    },
                    ResultConfiguration={
                        "OutputLocation": "s3://{0}/{1}".format(os.environ["bucketName"], os.environ["credentialsReportOutputPath"]),
                        "EncryptionConfiguration": {
                            "EncryptionOption": os.environ["encryptionOption"], # 'SSE_S3'|'SSE_KMS'|'CSE_KMS'
                            "KmsKey": os.environ["kmsKey"]
                        }
                    }
                )

            print("createTableResponse: {0}".format(json.dumps(createTableResponse)))

            if(createTableResponse != None or createTableResponse != {}):
                response = athena.get_query_execution(
                    QueryExecutionId = createTableResponse["QueryExecutionId"]
                )

                state = response["QueryExecution"]["Status"]["State"]

                # Re-check state of create table execution
                while(state == "QUEUED" or state == "RUNNING"):
                    time.sleep(5)

                    response = athena.get_query_execution(
                        QueryExecutionId = createTableResponse["QueryExecutionId"]
                    )

                    state = response["QueryExecution"]["Status"]["State"]
                    print("State: {0}".format(state))

                if(state != "SUCCEEDED"):
                    raise Exception("Create table execution returned a failure status of {0}".format(state))

                # Get the table repair named query
                repairTableQuery = athena.get_named_query(NamedQueryId=os.environ["repairCredentialReport"])

                print("repairTableQuery: {0}".format(json.dumps(repairTableQuery)))

                # Run the table repair query to load new partitions
                if(os.environ["encryptionOption"] == "NONE"):
                    repairTableResponse = athena.start_query_execution(
                        QueryString = repairTableQuery["NamedQuery"]["QueryString"],
                        QueryExecutionContext={
                            "Database": repairTableQuery["NamedQuery"]["Database"]
                        },
                        ResultConfiguration={
                            "OutputLocation": "s3://{0}/{1}".format(os.environ["bucketName"], os.environ["credentialsReportOutputPath"])
                        }
                    )
                else:
                    # Apply encryption if specified
                    repairTableResponse = athena.start_query_execution(
                        QueryString = repairTableQuery["NamedQuery"]["QueryString"],
                        QueryExecutionContext={
                            "Database": repairTableQuery["NamedQuery"]["Database"]
                        },
                        ResultConfiguration={
                            "OutputLocation": "s3://{0}/{1}".format(os.environ["bucketName"], os.environ["credentialsReportOutputPath"]),
                            "EncryptionConfiguration": {
                                "EncryptionOption": os.environ["encryptionOption"], # 'SSE_S3'|'SSE_KMS'|'CSE_KMS'
                                "KmsKey": os.environ["kmsKey"]
                            }
                        }
                    )

                print("repairTableResponse: {0}".format(json.dumps(repairTableResponse)))

                if(repairTableResponse != None or repairTableResponse != {}):
                    response = athena.get_query_execution(
                        QueryExecutionId = repairTableResponse["QueryExecutionId"]
                    )

                    state = response["QueryExecution"]["Status"]["State"]

                    # Re-check state of create table execution
                    while(state == "QUEUED" or state == "RUNNING"):
                        time.sleep(5)

                        response = athena.get_query_execution(
                            QueryExecutionId = repairTableResponse["QueryExecutionId"]
                        )

                        state = response["QueryExecution"]["Status"]["State"]
                        print("State: {0}".format(state))

                    if(state != "SUCCEEDED"):
                        raise Exception("Repair table execution returned a failure status of {0}".format(state))

                    stateObject["taskStatus"] = "OK"
                    stateObject["lastErrorMessage"] = None
                else:
                    stateObject["taskStatus"] = "FAILED"
                    stateObject["lastErrorMessage"] = "initialise-report: Failed to start repairTable query execution"
            else:
                stateObject["taskStatus"] = "FAILED"
                stateObject["lastErrorMessage"] = "initialise-report: Failed to start createTable query execution"
        else:
            stateObject["taskStatus"] = "FAILED"
            stateObject["lastErrorMessage"] = "initialise-report: Failed to get createTable query execution"

        return stateObject
    except Exception as e:
        stateObject["taskStatus"] = "FAILED"
        stateObject["lastErrorMessage"] = "initialise-report: Failed to initialise report.  Please review CloudWatch logs for further details"
        print("initialise-report: {0}".format(e))
        return stateObject
