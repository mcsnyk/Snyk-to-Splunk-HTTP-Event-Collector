#!/bin/bash

# get code results with the API
curl --request GET "https://api.snyk.io/rest/orgs/6391f850-81f8-48fc-9cd4-aa8c186c6ff0/issues?project_id=71f558ae-894e-4ff9-8656-55840e0fc78a&severity=high&type=code&version=2022-04-06%7Eexperimental" \
--header "Accept: application/vnd.api+json" \
--header "Authorization: Token bf9b9173-fdf6-4d2a-b603-ebc6e6b0f341" | tee code_results.json

# We can also leverage the python script: easier to configure
#pip3 install -r requirements.txt
#python3 rest-get-code-issues.py 2>&1 | sed '1,5d;$d' | sed '$d' | tee asd.json

# create a post request - send the results to AWS Lambda
curl --location --request POST 'https://vxy2zw7203.execute-api.us-west-2.amazonaws.com/default/SplunkOfficial' \
--header 'Content-Type: application/json' \
--data @code_results.json
