import json
import os
import urllib.request

def lambda_handler(event, context):
    print("event : ", event)
    url = os.environ['web_url']
    print("url : ", url)

    charge_cash = event["Records"][0]["body"]
    charge_cash = json.loads(charge_cash)

    if charge_cash["charge_amount"]:
        try:
            path = '/sqs_process'
            data_json = json.dumps(charge_cash).encode('utf-8')
            req = urllib.request.Request(url + path, data=data_json, headers={'content-type': 'application/json'})
            res = urllib.request.urlopen(req)
            return "Message sent to EC2 server successfully!"

        except Exception as e:
            return "Error sending request to EC2 server"
    else:
        return "another request"
