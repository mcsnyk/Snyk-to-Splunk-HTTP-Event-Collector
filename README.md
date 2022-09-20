# Snyk-to-Splunk using the Splunk HTTP-Event-Collector
Connect Snyk to Splunk by leveraging the Splunk HTTP Event Collector and visualise your vulns to Splunk.   

## Useful resources   
I recommend the following resources:
- Snyk API masterclass: [Connecting Snyk to Slack with AWS Lambda](https://docs.google.com/document/d/1c-J3UnaJacPpUJwnCUIIATpmuRA4ekbjc5YQRS0h3gY/edit#heading=h.dfekck1qh08m), *(Fredrik Klasén, Eric Fernandez)*
- Forward Snyk Vulnerability data [to Splunk Observability Cloud](https://www.kimpel.com/post/forward-snyk-vuln-data-to-splunk/), *(Harry Kimpel)* 
- Snyk [webhook subscription](https://github.com/harrykimpel/snyk-webhook-subscription/), *(Harry Kimpel)*

## Prerequisites
- An AWS account with access to:<br/>
	- Create new roles (or use an existing one)<br/>
	- Modify Lambda functions<br/>
	- Modify API Gateway<br/>
- Snyk account with Organization Admin access<br/>
- Splunk Clound account - note: **not the same** as Splunk Observability Cloud!<br/>

## List of content
- [1. AWS Setup](#1-aws-setup)<br/>
	- [1.1 Create a new IAM role (upfront) for the AWS Lambda function](#11-create-a-new-iam-role-upfront-for-the-aws-lambda-function)<br/>
	- [1.2 Create a Lambda function](#12-create-a-lambda-function)<br/>
	- [1.3 Setting the necessary environment variables](#13-setting-the-necessary-environment-variables)<br/>
- 
## 1. AWS Setup
Note: The Lambda and API Gateway have to be configured in the same region
We are going to use AWS Lambda, because it's a relatively cost-effective and efficient way to run code on events, for example when there is a new Snyk vulnerability.

### 1.1 Create a new IAM role (upfront) for the AWS Lambda function

<details>
<summary>Implementation steps here</summary>
<br>
	<table border="0">
		<tbody>
			<tr>
				<td> <img src="iam.webp" width="130"></td>
				<td>
1. Go to the AWS Console<br/><br/>
2. Navigate to <b>IAM</b><br/><br/>
3. Click on <b>Roles/Create role</b><br/><br/>
4. Select for Trusted entity type: <b>AWS Service</b>, for Use case:<b>Lambda</b>, then click on Next<br/><br/>
5. Search for <b>AmazonAPIGatewayInvokeFullAccess</b> (we'll be interacting with the API Gateway) and <b>AWSLambdaBasicExecutionRole</b> among the Permissions policies, then click on Next.<br/>
				</td>
			</tr>
		</tbody>
	</table>
</details>
<b>Note:</b> automatically created roles in AWS Lambda will restrict the "Resources", instead of  

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
<table border="0">
	<tbody>
		<tr>
			<td> <img src="lambda.png" width="130"></td>
			<td>
1. Go to the AWS Console<br/><br/>
2. Navigate to <b>Lambda</b><br/><br/>
3. Click on <b>Create function</b><br/><br/>
4. Choose <b>Node.js 16.x</b> for the Runtime<br/><br/>
5. <b>x86_64</b> for the architecture<br/><br/>
6. Attach the previously created <b>role</b> ("Use an existing role") to the Lambda function<br/>
(you can also create a new role, but make sure that you attach the <b>AmazonAPIGatewayInvokeFullAccess policy</b> in IAM to it afterwards)<br/><br/>
			</td>
		</tr>
	</tbody>
</table>
			
7. It should end up looking like this:
<img src="create_lambda_function.png" width="2048">

8. Click on <b>"Create function"</b>
9. In the code section paste the function "splunk-logging.js" file!    

---
:genie: **Alternatively we can immediately go to [Splunk's development site](https://dev.splunk.com/enterprise/docs/devtools/httpeventcollector/useawshttpcollector/createlambdafunctionnodejs/) and create a Lambda function using a Splunk blueprint:** select the "splunk-logging" blueprint option, or click [here to immediate action within AWS Lambda](https://console.aws.amazon.com/lambda/home?#/create/configure-triggers?bp=splunk-logging)

---

### 1.3 Setting the necessary environment variables
1. Go to Configuration in your Lambda 
2. Click on Environment variables
3. Add new environment variables (if you created the Lambda function on your own and didn't use the Splunk blueprint): <br/>
**SPLUNK_HEC_TOKEN** and **SPLUNK_HEC_URL**. Don't worry, we'll give them values in a minute.<br/>
