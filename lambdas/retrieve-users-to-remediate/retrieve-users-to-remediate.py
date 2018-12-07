import json
import boto3
import sys
import os
import time

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

    athena = boto3.client('athena')

    try:
        response = athena.get_query_execution(
            QueryExecutionId = stateObject["queryExecutionId"]
        )

        state = response["QueryExecution"]["Status"]["State"]

        # Re-check state of query execution
        while(state == "QUEUED" or state == "RUNNING"):
            time.sleep(5)

            response = athena.get_query_execution(
                QueryExecutionId = stateObject["queryExecutionId"]
            )

            state = response["QueryExecution"]["Status"]["State"]
            #print("State: {0}".format(state))

        if(state != "SUCCEEDED"):
            raise Exception("Create table execution returned a failure status of {0}".format(state))

        # Get the query results
        namedQueryResults = athena.get_query_results(QueryExecutionId = stateObject["queryExecutionId"])

        if(namedQueryResults != "" or namedQueryResults != {}):
            #print("namedQueryResults: {0}".format(json.dumps(namedQueryResults)))
            userList = []

            userColumnIndex = namedQueryResults["ResultSet"]["Rows"][0]["Data"].index({"VarCharValue": "user"})
            #print("userColumnIndex: {0}".format(userColumnIndex))

            for rows in namedQueryResults["ResultSet"]["Rows"]:
                #print("user: {0}".format(rows["Data"][userColumnIndex]["VarCharValue"]))
                user = rows["Data"][1]["VarCharValue"]
                if(user != "user"):
                    userList.append(user)

            if(len(userList) == 0):
                #print("No users to remediate")
                stateObject["taskStatus"] = "NONE"
                stateObject["lastErrorMessage"] = None
            else:
                #print("usersList: {0}".format(json.dumps(userList)))
                users = {"users" : userList}
                stateObject.update(users)
                stateObject["taskStatus"] = "OK"
                stateObject["lastErrorMessage"] = None
        else:
            stateObject["taskStatus"] = "FAILED"
            stateObject["lastErrorMessage"] = "retrieve-users: Failed to get named query result for QueryExecutionID {0}".format(stateObject["queryExecutionId"])
        return stateObject
    except Exception as e:
        stateObject["taskStatus"] = "FAILED"
        stateObject["lastErrorMessage"] = "retrieve-users: Please review CloudWatch logs for further details"
        print("remediate-findings: {0}".format(e))
        return stateObject
