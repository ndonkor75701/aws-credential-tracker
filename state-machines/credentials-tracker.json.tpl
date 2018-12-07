{
  "Comment": "A state machine that generates and interogates the AWS IAM Credentials report.",
  "StartAt": "Generate Report",
  "States": {
    "Generate Report": {
      "Type": "Task",
      "Resource": "${generate-report-lambda-arn}",
      "ResultPath": "$",
      "Next": "Wait X Seconds",
      "Retry": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "IntervalSeconds": 1,
          "MaxAttempts": 3,
          "BackoffRate": 2
        }
      ]
    },
    "Wait X Seconds": {
      "Type": "Wait",
      "SecondsPath": "$.generateWaitTime",
      "Next": "Download Report"
    },
    "Download Report": {
      "Type": "Task",
      "Resource": "${download-report-lambda-arn}",
      "Next": "Download Complete?",
      "InputPath": "$",
      "ResultPath": "$",
      "Retry": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "IntervalSeconds": 1,
          "MaxAttempts": 3,
          "BackoffRate": 2
        }
      ]
    },
    "Download Complete?": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.taskStatus",
          "StringEquals": "FAILED",
          "Next": "Download Failed"
        },
        {
          "Variable": "$.taskStatus",
          "StringEquals": "OK",
          "Next": "Download Succeeded"
        }
      ],
      "Default": "Wait X Seconds"
    },
    "Download Failed": {
      "Type": "Fail",
      "Cause": "Report download failed",
      "Error": "Report not found"
    },
    "Initialise Report": {
      "Type": "Task",
      "Resource": "${initialise-report-lambda-arn}",
      "InputPath": "$",
      "ResultPath": "$",
      "Next": "Initialisation Complete?",
      "Retry": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "IntervalSeconds": 1,
          "MaxAttempts": 3,
          "BackoffRate": 2
        }
      ]
    },
    "Initialisation Complete?": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.taskStatus",
          "StringEquals": "FAILED",
          "Next": "Initialisation Failed"
        },
        {
          "Variable": "$.taskStatus",
          "StringEquals": "OK",
          "Next": "Initialisation Succeeded"
        }
      ],
      "Default": "Initialisation Failed"
    },
    "Download Succeeded": {
      "Type": "Pass",
      "Next": "Initialise Report"
    },
    "Initialisation Failed": {
      "Type": "Fail",
      "Cause": "Processing report failed",
      "Error": "Report not found"
    },
    "Initialisation Succeeded": {
      "Type": "Pass",
      "Next": "Generate Findings"
    },
    "Generate Findings": {
      "Type": "Parallel",
      "InputPath": "$",
      "ResultPath": "$",
      "Branches": [
        {
         "StartAt": "AK Usage Findings",
         "States": {
           "AK Usage Findings": {
             "Type": "Task",
             "InputPath": "$",
             "ResultPath": "$",
             "Resource": "${generate-findings_ak-usage-period-lambda-arn}",
             "Next": "AK Usage Findings Complete?"
           },
           "AK Usage Findings Complete?": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.taskStatus",
          "StringEquals": "FAILED",
          "Next": "Generate AK Usage Findings Failed"
        },
        {
          "Variable": "$.taskStatus",
          "StringEquals": "OK",
          "Next": "Generate AK Usage Findings Succeeded"
        }
      ]
         },
         "Generate AK Usage Findings Failed": {
      "Type": "Fail",
      "Cause": "Processing report failed",
      "Error": "Report not found"
    },
    "Generate AK Usage Findings Succeeded": {
      "Type": "Pass",
              "Next": "Retrieve AK Usage Users to Remediate"
    },
            "Retrieve AK Usage Users to Remediate": {
             "Type": "Task",
             "InputPath": "$",
             "ResultPath": "$",
             "Resource": "${retrieve-users-to-remediate-lambda-arn}",
             "Next": "AK Usage Users to Remediate Retrieved?"
           },
            "AK Usage Users to Remediate Retrieved?": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.taskStatus",
          "StringEquals": "FAILED",
                  "Next": "Retrieve AK Usage Users to Remediate Failed"
        },
        {
          "Variable": "$.taskStatus",
          "StringEquals": "OK",
                  "Next": "Retrieve AK Usage Users to Remediate Succeeded"
        },
        {
          "Variable": "$.taskStatus",
          "StringEquals": "NONE",
          "Next": "No AK Usage Findings"
        }
      ]
         },
            "Retrieve AK Usage Users to Remediate Failed": {
      "Type": "Fail",
      "Cause": "Processing report failed",
      "Error": "Report not found"
    },
            "Retrieve AK Usage Users to Remediate Succeeded": {
      "Type": "Pass",
              "Next": "Remediate AK Usage Findings"
    },
           "No AK Usage Findings": {
      "Type": "Pass",
      "End": true
            },
            "Remediate AK Usage Findings": {
              "Type": "Task",
              "InputPath": "$",
              "ResultPath": "$",
              "Resource": "${remediate-findings_ak-usage-period-lambda-arn}",
              "Next": "AK Usage Findings Remediated?"
            },
            "AK Usage Findings Remediated?": {
              "Type": "Choice",
              "Choices": [
                {
                  "Variable": "$.taskStatus",
                  "StringEquals": "FAILED",
                  "Next": "Remediate AK Usage Findings Failed"
                },
                {
                  "Variable": "$.taskStatus",
                  "StringEquals": "OK",
                  "Next": "Remediate AK Usage Findings Succeeded"
    }
              ]
            },
            "Remediate AK Usage Findings Failed": {
              "Type": "Fail",
              "Cause": "Processing report failed",
              "Error": "Report not found"
            },
            "Remediate AK Usage Findings Succeeded": {
              "Type": "Pass",
              "End": true
       }
          }
        },
       {
         "StartAt": "AK Rotation Findings",
         "States": {
           "AK Rotation Findings": {
             "Type": "Task",
             "InputPath": "$",
             "ResultPath": "$",
             "Resource": "${generate-findings_ak-rotation-period-lambda-arn}",
             "Next": "AK Rotation Findings Complete?"
           },
           "AK Rotation Findings Complete?": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.taskStatus",
          "StringEquals": "FAILED",
          "Next": "Generate AK Rotation Findings Failed"
        },
        {
          "Variable": "$.taskStatus",
          "StringEquals": "OK",
          "Next": "Generate AK Rotation Findings Succeeded"
        }
      ]
         },
         "Generate AK Rotation Findings Failed": {
      "Type": "Fail",
      "Cause": "Processing report failed",
      "Error": "Report not found"
    },
    "Generate AK Rotation Findings Succeeded": {
      "Type": "Pass",
              "Next": "Retrieve AK Rotation Users to Remediate"
            },
            "Retrieve AK Rotation Users to Remediate": {
              "Type": "Task",
              "InputPath": "$",
              "ResultPath": "$",
              "Resource": "${retrieve-users-to-remediate-lambda-arn}",
              "Next": "AK Rotation Users to Remediate Retrieved?"
            },
            "AK Rotation Users to Remediate Retrieved?": {
              "Type": "Choice",
              "Choices": [
                {
                  "Variable": "$.taskStatus",
                  "StringEquals": "FAILED",
                  "Next": "Retrieve AK Rotation Users to Remediate Failed"
                },
                {
                  "Variable": "$.taskStatus",
                  "StringEquals": "OK",
                  "Next": "Retrieve AK Rotation Users to Remediate Succeeded"
                },
                {
                  "Variable": "$.taskStatus",
                  "StringEquals": "NONE",
                  "Next": "No AK Rotation Findings"
                }
              ]
            },
            "Retrieve AK Rotation Users to Remediate Failed": {
              "Type": "Fail",
              "Cause": "Processing report failed",
              "Error": "Report not found"
            },
            "Retrieve AK Rotation Users to Remediate Succeeded": {
              "Type": "Pass",
      "Next": "Remediate AK Rotation Findings"
    },
            "No AK Rotation Findings": {
              "Type": "Pass",
              "End": true
            },
            "Remediate AK Rotation Findings": {
             "Type": "Task",
             "InputPath": "$",
             "ResultPath": "$",
              "Resource": "${remediate-findings_ak-rotation-period-lambda-arn}",
             "Next": "AK Rotation Findings Remediated?"
           },
           "AK Rotation Findings Remediated?": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.taskStatus",
          "StringEquals": "FAILED",
          "Next": "Remediate AK Rotation Findings Failed"
        },
        {
          "Variable": "$.taskStatus",
          "StringEquals": "OK",
          "Next": "Remediate AK Rotation Findings Succeeded"
        }
      ]
         },
         "Remediate AK Rotation Findings Failed": {
      "Type": "Fail",
      "Cause": "Processing report failed",
      "Error": "Report not found"
    },
           "Remediate AK Rotation Findings Succeeded": {
      "Type": "Pass",
      "End": true
    }
       }
      },
       {
         "StartAt": "Cert Rotation Findings",
         "States": {
           "Cert Rotation Findings": {
             "Type": "Task",
             "InputPath": "$",
             "ResultPath": "$",
             "Resource": "${generate-findings_cert-rotation-period-lambda-arn}",
             "Next": "Cert Rotation Findings Complete?"
           },
           "Cert Rotation Findings Complete?": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.taskStatus",
          "StringEquals": "FAILED",
          "Next": "Generate Cert Rotation Findings Failed"
        },
        {
          "Variable": "$.taskStatus",
          "StringEquals": "OK",
          "Next": "Generate Cert Rotation Findings Succeeded"
        }
      ]
         },
           "Generate Cert Rotation Findings Failed": {
      "Type": "Fail",
      "Cause": "Processing report failed",
      "Error": "Report not found"
    },
    "Generate Cert Rotation Findings Succeeded": {
      "Type": "Pass",
              "Next": "Retrieve Cert Rotation Users to Remediate"
            },
            "Retrieve Cert Rotation Users to Remediate": {
              "Type": "Task",
              "InputPath": "$",
              "ResultPath": "$",
              "Resource": "${retrieve-users-to-remediate-lambda-arn}",
              "Next": "Cert Rotation Users to Remediate Retrieved?"
            },
            "Cert Rotation Users to Remediate Retrieved?": {
              "Type": "Choice",
              "Choices": [
                {
                  "Variable": "$.taskStatus",
                  "StringEquals": "FAILED",
                  "Next": "Retrieve Cert Rotation Users to Remediate Failed"
                },
                {
                  "Variable": "$.taskStatus",
                  "StringEquals": "OK",
                  "Next": "Retrieve Cert Rotation Users to Remediate Succeeded"
                },
                {
                  "Variable": "$.taskStatus",
                  "StringEquals": "NONE",
                  "Next": "No Cert Rotation Findings"
                }
              ]
            },
            "Retrieve Cert Rotation Users to Remediate Failed": {
              "Type": "Fail",
              "Cause": "Processing report failed",
              "Error": "Report not found"
            },
            "Retrieve Cert Rotation Users to Remediate Succeeded": {
              "Type": "Pass",
      "Next": "Remediate Cert Rotation Findings"
    },
            "No Cert Rotation Findings": {
              "Type": "Pass",
              "End": true
            },
           "Remediate Cert Rotation Findings": {
             "Type": "Task",
             "InputPath": "$",
             "ResultPath": "$",
              "Resource": "${remediate-findings_cert-rotation-period-lambda-arn}",
             "Next": "Cert Rotation Findings Remediated?"
           },
           "Cert Rotation Findings Remediated?": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.taskStatus",
          "StringEquals": "FAILED",
          "Next": "Remediate Cert Rotation Findings Failed"
        },
        {
          "Variable": "$.taskStatus",
          "StringEquals": "OK",
          "Next": "Remediate Cert Rotation Findings Succeeded"
        }
      ]
         },
         "Remediate Cert Rotation Findings Failed": {
      "Type": "Fail",
      "Cause": "Processing report failed",
      "Error": "Report not found"
    },
           "Remediate Cert Rotation Findings Succeeded": {
      "Type": "Pass",
      "End": true
    }
       }
       },
       {
         "StartAt": "Cred Usage Findings",
         "States": {
           "Cred Usage Findings": {
             "Type": "Task",
             "InputPath": "$",
             "ResultPath": "$",
             "Resource": "${generate-findings_cred-usage-period-lambda-arn}",
             "Next": "Cred Usage Findings Complete?"
           },
           "Cred Usage Findings Complete?": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.taskStatus",
          "StringEquals": "FAILED",
          "Next": "Generate Cred Usage Findings Failed"
        },
        {
          "Variable": "$.taskStatus",
          "StringEquals": "OK",
          "Next": "Generate Cred Usage Findings Succeeded"
        }
      ]
         },
         "Generate Cred Usage Findings Failed": {
      "Type": "Fail",
      "Cause": "Processing report failed",
      "Error": "Report not found"
    },
    "Generate Cred Usage Findings Succeeded": {
      "Type": "Pass",
              "Next": "Retrieve Cred Usage Users to Remediate"
            },
            "Retrieve Cred Usage Users to Remediate": {
              "Type": "Task",
              "InputPath": "$",
              "ResultPath": "$",
              "Resource": "${retrieve-users-to-remediate-lambda-arn}",
              "Next": "Cred Usage Users to Remediate Retrieved?"
            },
            "Cred Usage Users to Remediate Retrieved?": {
              "Type": "Choice",
              "Choices": [
                {
                  "Variable": "$.taskStatus",
                  "StringEquals": "FAILED",
                  "Next": "Retrieve Cred Usage Users to Remediate Failed"
                },
                {
                  "Variable": "$.taskStatus",
                  "StringEquals": "OK",
                  "Next": "Retrieve Cred Usage Users to Remediate Succeeded"
                },
                {
                  "Variable": "$.taskStatus",
                  "StringEquals": "NONE",
                  "Next": "No Cred Usage Findings"
                }
              ]
            },
            "Retrieve Cred Usage Users to Remediate Failed": {
              "Type": "Fail",
              "Cause": "Processing report failed",
              "Error": "Report not found"
            },
            "Retrieve Cred Usage Users to Remediate Succeeded": {
              "Type": "Pass",
      "Next": "Remediate Cred Usage Findings"
    },
            "No Cred Usage Findings": {
              "Type": "Pass",
              "End": true
            },
           "Remediate Cred Usage Findings": {
             "Type": "Task",
             "InputPath": "$",
             "ResultPath": "$",
              "Resource": "${remediate-findings_cred-usage-period-lambda-arn}",
             "Next": "Cred Usage Findings Remediated?"
           },
           "Cred Usage Findings Remediated?": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.taskStatus",
          "StringEquals": "FAILED",
          "Next": "Remediate Cred Usage Findings Failed"
        },
        {
          "Variable": "$.taskStatus",
          "StringEquals": "OK",
          "Next": "Remediate Cred Usage Findings Succeeded"
        }
      ]
         },
         "Remediate Cred Usage Findings Failed": {
      "Type": "Fail",
      "Cause": "Processing report failed",
      "Error": "Report not found"
    },
           "Remediate Cred Usage Findings Succeeded": {
      "Type": "Pass",
      "End": true
    }
       }
       }
      ],
      "End": true
    }
  }
}
