# Snyk-to-Splunk using the Splunk HTTP-Event-Collector
Connect Snyk to Splunk by leveraging the Splunk HTTP Event Collector and visualise your vulns to Splunk.   

## Useful resources   
I recommend the following resources:
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
- [1. Splunk Setup](#1-splunk-setup)<br/>
	- [1.1 Setting up the HTTP Event Collector in Splunk Cloud](#11-setting-up-the-http-event-collector-in-splunk-cloud)<br/>
	- [1.2 Generate a UUID for the Splunk connection (X-Splunk-Request-Channel)](#12-generate-a-uuid-for-the-splunk-connection-x-splunk-request-channel)<br/>
	- [1.3 Test our Splunk connection](#12-firetest-our-splunk-connectionfire)<br/>
- [2. AWS Setup](#2-aws-setup)<br/>
	- [2.1 Create a new IAM role (upfront) for the AWS Lambda function](#21-create-a-new-iam-role-upfront-for-the-aws-lambda-function)<br/>
	- [2.2 Create a Lambda function](#22-create-a-lambda-function)<br/>
	- [2.3 Setting the necessary environment variables](#23-setting-the-necessary-environment-variables-for-our-aws-lambda-function)<br/>

## 1. Splunk Setup
To start with, we will set up and configure the Splunk HTTP Event Collector and test our connection before moving to AWS Lambda.<br/>  

### 1.1 Setting up the HTTP Event Collector in Splunk Cloud    
Our intention is to get data in Splunk Cloud via monitoring. We'll leverage the Splunk HTTP Event Collector, which is an endpoint that lets developers send application events directly to the Splunk platform via HTTP or HTTPS using a token-based authentication model.<br/>  
It's a handy solution, because we can use the Splunk .NET and Java logging libraries or any standard HTTP Client that lets us send data in JavaScript Object Notation (JSON) format.<br/>       
The HTTP Event Collector receives data over HTTPS on TCP port 8088 by default. We can change this port, as well as disable HTTPS.<br/>  

<details>
<summary><b>:hammer_and_wrench: Implementation steps</b></summary>
<br/>
1. Log in to your <b>Splunk Cloud account</b> (you receive the login information via email, like the Splunk Cloud Platform URL, the Username and a Temporary Password)<br/>
<img src="resources_img/splunk_login_information.png" width="400"><br/><br/>
2. After a succesful log in, navigate to <b>Settings</b> in the top menu bar and select the Add Data icon!<br/>
<img src="resources_img/splunk_add_data.png" width="400"><br/><br/>
3. In the <b>Or get data in with the following methods </b> section choose Monitor<br/><br/>
4. Among the many options choose <b>HTTP Event Collector</b><br/><br/>
5. Give a name for your Token and make sure that the option <b>Enable indexer acknowledgement</b> is selected!<br/>
<img src="resources_img/splunk_httpec_setup.png" width="1024"><br/><br/>
6. On the Input Settings site the source type should be <b>automatic</b>, and we can allow the <b>main </b>index (The Splunk platform stores incoming data as events in the selected index):<br/>
<img src="resources_img/splunk_allow_main_index.png" width="1024"><br/><br/>
7. After reviewing all the information, we're done, you should see the generated Token Value (in this setup on AWS Lambda it is called <b>SPLUNK_HEC_TOKEN</b>):<br/>
<img src="resources_img/splunk_generated_token.png" width="800"><br/><br/>
</details>

### 1.2 Generate a UUID for the Splunk connection (X-Splunk-Request-Channel)
[Sending events to HEC with indexer acknowledgment](https://docs.splunk.com/Documentation/Splunk/9.0.1/Data/AboutHECIDXAck) active is similar to sending them with the setting off. There is one crucial difference: when you have indexer acknowledgment turned on, you must specify a channel when you send events.<br/>
The concept of a channel was introduced in HEC primarily to prevent a fast client from impeding the performance of a slow client. When you assign one channel per client, because channels are treated equally on Splunk Enterprise, one client can't affect another.<br/>

In order to We need a unique identifier which we can generate for example [here](https://www.guidgenerator.com/online-guid-generator.aspx), this will make our communication unique by using this globally unique component (in this case message) identifiers.<br/>
<img src="resources_img/uuid_generation.png" width="400"><br/>

### 1.3 :fire:Test our Splunk connection:fire: 
To test our Splunk connection, we will use <b>Postman</b> this time (feel free to use your own API platform to interact with Splunk).      
I recommend to create a new collection in Splunk, and put all the requests there.

<details>
<summary><b>:hammer_and_wrench: Test steps</b></summary>
Parameters of the <b>POST</b> request:
- As a URL, let's use ``` https://prd-p-2mqiy.splunkcloud.com:8088/services/collector ```
- Authorization type: <b>No Auth</b>
- Headers:
	- Content-Type: <b>application/json</b>
	- Authorization: <b>Splunk \<your-splunk-token\></b>
	- X-Splunk-Request-Channel: <b>\<the generated UUID\></b><br/>

It should look like:     
<img src="resources_img/postman_splunk_header.png" width="1024"><br/>
- Body: Let's just use a short sentence as an <b>httpevent</b>, like:
```json
{
    "event": "Let's ping Splunk", 
    "sourcetype": "httpevent"
}	
```
It should look like:     
<img src="resources_img/postman_splunk_body.png" width="700"><br/>

After sending the POST request, we should see in Postman:       
<img src="resources_img/postman_splunk_success.png" width="500"><br/>
	
We need to navigate to the Search & Reporting site in Splunk Cloud (right menu pane):      
<img src="resources_img/splunk_search_and_reporting.png" width="200"><br/>

We shall start a new search, into the search field we need to enter ``` source="http:<name-of-your-http-event-token>" (index="main")```.      
Fortunately we turned on the indexing option when setting up the HTTP Event Collector, now it's easy to find our messages.<br/><br/>
<img src="resources_img/splunk_ping_success.png" width="2048"><br/>

As we can see, Splunk successfully received our message. Now we can set up and configure our AWS Lambda finction.    
</details>
	
## 2. AWS Setup
In this section, I'll show you how to configure AWS in order to send data towards Splunk, as well as the background of the 5 implementation steps.

Note: The AWS Lambda function and the API Gateway have to be configured in the same region.   
We are going to use AWS Lambda, because it's a relatively cost-effective and efficient way to run code on events, for example when there is a new Snyk vulnerability.

### 2.1 Create a new IAM role (upfront) for the AWS Lambda function
To start with, we need to create an IAM role that we can assign to the AWS Lambda function. We need to provide basic execution roles and permissions to invoke an API Gateway which we'll be interacting with. If you're interested in the implementation, click below.  
<details>
<summary><b>:hammer_and_wrench: Implementation steps</b></summary>
<br/>
	<table border="0">
		<tbody>
			<tr>
				<td> <img src="resources_img/iam.webp" width="130"></td>
				<td>
1. Go to the AWS Console<br/><br/>
2. Navigate to <b>IAM</b><br/><br/>
3. Click on <b>Roles/Create role</b><br/><br/>
4. Select for Trusted entity type: <b>AWS Service</b>, for Use case: <b>Lambda</b>, then click on Next<br/><br/>
5. Search for <b>AmazonAPIGatewayInvokeFullAccess</b> (we'll be interacting with the API Gateway) and <b>AWSLambdaBasicExecutionRole</b> among the Permissions policies, then click on Next.<br/><br/>
6. Add a (custom) name for the role, then click on <b>Create role</b><br/>
				</td>
			</tr>
		</tbody>
	</table>
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
</details>

You can check, your roles should look like these (AWS build-in roles)

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

### 2.2 Create a Lambda function
---
:genie: **The fastest and most convenient way is to go to [Splunk's development site](https://dev.splunk.com/enterprise/docs/devtools/httpeventcollector/useawshttpcollector/createlambdafunctionnodejs/) and create a Lambda function using a Splunk blueprint:** select the "splunk-logging" blueprint option, or click [here to immediate action within AWS Lambda](https://console.aws.amazon.com/lambda/home?#/create/configure-triggers?bp=splunk-logging)

---

Alternatively, of course we can create own our JavaScript code as described below.
<details>
<summary><b>:hammer_and_wrench: Implementation steps</b></summary>
<br/>
	<table border="0">
	<tbody>
		<tr>
			<td> <img src="resources_img/lambda.png" width="130"></td>
			<td>
1. Go to the AWS Console<br/><br/>
2. Navigate to <b>Lambda</b><br/><br/>
3. Click on <b>Create function</b><br/><br/>
4. Choose <b>Node.js 16.x</b> for the Runtime<br/><br/>
5. <b>x86_64</b> for the architecture<br/><br/>
6. Attach the previously created <b>role</b> ("Use an existing role") to the Lambda function<br/>
(you can also create a new role, but make sure that you attach the <b>AmazonAPIGatewayInvokeFullAccess policy</b> in IAM to it afterwards)<br/><br/>
8. Click on <b>"Create function"</b><br/><br/>
9. In the code section paste the function "[splunk-logging.js](https://github.com/mcsnyk/Snyk-to-Splunk-HTTP-Event-Collector/blob/main/scripts/splunk-logging.js)" file!<br/>  
			</td>
		</tr>
	</tbody>
</table>

The configuration should look like this:
<img src="resources_img/create_lambda_function.png" width="2048">
</details>

### 2.3 Setting the necessary environment variables for our AWS Lambda function
In order to interact with Splunk and the Splunk HTTP event collector, we need to set two environment variables in AWS Lambda:

**SPLUNK_HEC_URL**: URL address for your Splunk HTTP event collector endpoint.
Default port for event collector is 8088. Example: https://host.com:8088/services/collector

**SPLUNK_HEC_TOKEN**: Token for your Splunk HTTP event collector.
To create a new token for this Lambda function, refer to Splunk Docs:
http://docs.splunk.com/Documentation/Splunk/latest/Data/UsetheHTTPEventCollector#Create_an_Event_Collector_token   

<details>
<summary><b>:hammer_and_wrench: Implementation steps</b></summary>
<br/>
1. Go to <b>Configuration</b> in your AWS Lambda<br/><br/> 
2. Click on <b>Environment</b> variables<br/><br/>
3. Add new environment variables (if you created the Lambda function on your own and didn't use the Splunk blueprint): <br/>
<b>SPLUNK_HEC_TOKEN</b> and <b>SPLUNK_HEC_URL</b>.<br/><br/>
- We have already generated our <a href="https://github.com/mcsnyk/Snyk-to-Splunk-HTTP-Event-Collector/blob/main/README.md#13-setting-up-the-http-event-collector-in-splunk-cloud">Splunk Token in 1.3, Step 7 </a>which we can use now.<br/><br/>
- When configuring the URL we need to pay attention to the [following configurations](https://community.splunk.com/t5/Getting-Data-In/What-is-the-URI-for-HTTP-Event-Collector-for-Splunk-Cloud/m-p/425704
</details>

In our setup, the HEC URL is going to look like:
```
https://prd-p-2mqiy.splunkcloud.com:8088/services/collector?channel=2b5fcd04-f37e-4484-9610-8ea31cb510ef
```
You might ask, why we need the ``` ?channel=2b5fcd04-f37e-4484-9610-8ea31cb510ef ``` part in the URL, you can find an explanation [here](https://cultivatingsoftware.wordpress.com/2018/07/24/splunk-hec-gotcha/) and [here](https://community.splunk.com/t5/Splunk-Enterprise/Why-am-I-getting-error-quot-Data-channel-is-missing-quot-using/td-p/280621).
     
### 2.4 Setting up the Lambda trigger
Our goal is to have the Lambda function triggered by a Snyk webhook. To do this we are going to use the API Gateway provided by AWS to trigger the Lambda every time a new event is received.

<details>
<summary><b>:hammer_and_wrench: Implementation steps</b></summary>
<br/>
<table border="0">
	<tbody>
		<tr>
			<td> <img src="resources_img/API_gateway.png" width="130"></td>
			<td>
1. Go to the AWS Console if you are not there, pay attention to be in the right region!<br/><br/>
2. Navigate to the function and click on Add Trigger<br/><br/>
3. Select API Gateway as trigger<br/><br/>
4. Configure the API Gateway as per the image<br/><br/>  
			</td>
		</tr>
	</tbody>
</table>

</details>
### 1.5 :fire: Time to test our AWS connection :fire:
To test our connections, we will use <b>Postman</b> this time (feel free to use your own API platform to interact with Splunk and AWS Lambda).
