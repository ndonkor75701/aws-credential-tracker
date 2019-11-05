{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:GenerateCredentialReport",
                "logs:CreateLogStream",
                "iam:GetCredentialReport",
                "logs:PutLogEvents",
                "iam:ListAccessKeys",
                "iam:UpdateAccessKey",
                "iam:GetAccessKeyLastUsed",
                "iam:ListSigningCertificates",
                "iam:UpdateSigningCertificate",
                "iam:DeleteLoginProfile"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "lambda:InvokeFunction",
            "Resource": [
                "${generate-report-lambda-arn}",
                "${download-report-lambda-arn}",
                "${initialise-report-lambda-arn}",
                "${generate-findings_ak-usage-period-lambda-arn}",
                "${generate-findings_cred-usage-period-lambda-arn}",
                "${generate-findings_ak-rotation-period-lambda-arn}",
                "${generate-findings_cert-rotation-period-lambda-arn}",
                "${retrieve-users-to-remediate-lambda-arn}",
                "${remediate-findings_ak-usage-period-lambda-arn}",
                "${remediate-findings_cred-usage-period-lambda-arn}",
                "${remediate-findings_ak-rotation-period-lambda-arn}",
                "${remediate-findings_cert-rotation-period-lambda-arn}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "athena:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "glue:*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::${bucket-name}/*"
            ]
        }
    ]
}
