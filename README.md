# Snyk-to-Splunk using the Splunk HTTP-Event-Collector
Connect Snyk to Splunk by leveraging the Splunk HTTP Event Collector and visualise your vulns to Splunk.   

## Useful resources   
I recommend the following resources:
- Snyk API masterclass: [Connecting Snyk to Slack with AWS Lambda](https://docs.google.com/document/d/1c-J3UnaJacPpUJwnCUIIATpmuRA4ekbjc5YQRS0h3gY/edit#heading=h.dfekck1qh08m), *(Fredrik Klasén, Eric Fernandez)*
- Forward Snyk Vulnerability data [to Splunk Observability Cloud](https://www.kimpel.com/post/forward-snyk-vuln-data-to-splunk/), *(Harry Kimpel)* 
- Snyk [webhook subscription](), *(Harry Kimpel)*

## Prerequisites
- An AWS account with access to:<br/>
	- Create new roles (or use an existing one)<br/>
	- Modify Lambda functions<br/>
	- Modify API Gateway<br/>
- Snyk account with Organization Admin access<br/>
- Splunk Clound account - note: **not the same** as Splunk Observability Cloud!<br/>

## 1. AWS Setup
Note: The Lambda and API Gateway have to be configured in the same region
We are going to use AWS Lambda, because it's a relatively cost-effective and efficient way to run code on events, for example when there is a new Snyk vulnerability.

### 1.1 Create a new IAM role (upfront) for the AWS Lambda function
1. Go to the AWS Console
2. Navigate to IAM
3. Click on Roles/Create role
4. Select for Trusted entity type: **AWS Service**, for Use case:**Lambda**, then click on Next
5. Search for **AmazonAPIGatewayInvokeFullAccess** and **AWSLambdaBasicExecutionRole** among the Permissions policies, then click on Next.   <br/>
**Note:** automatically created roles in AWS Lambda will restrict the "Resources", instead of 
```
"Resource": "*"
```
You will see something like:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:us-west-2:880724394176:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:us-west-2:880724394176:log-group:/aws/lambda/Splunk:*"
            ]
        }
    ]
}
```

6. Add a (custom) name for the role, then click on Create role
7. You can check, your roles should look like these (AWS build-in roles)

```json
//AmazonAPIGatewayInvokeFullAccess
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
```


```json
//AWSLambdaBasicExecutionRole
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "execute-api:Invoke",
                "execute-api:ManageConnections"
            ],
            "Resource": "arn:aws:execute-api:*:*:*"
        }
    ]
}
```

### 1.2 Create a Lambda function
1. Go to the AWS Console
2. Navigate to Lambda
3. Click on Create function
4. Choose Node.js 16.x for the Runtime
5. x86_64 for the architecture
6. Add or create a role with the policy AmazonAPIGatewayInvokeFullAccess as we will be interacting with the API Gateway
7. It should end up looking like this
