import pymysql
import json
import os
import sys
import logging
import boto3

sqs = boto3.client('sqs', region_name="us-east-2")

db_host = os.environ['DB_HOST']
db_user = os.environ['DB_USER']
db_password = os.environ['DB_PASSWORD']
db_name = os.environ["DB_NAME"]
queue_url = os.environ['QueueUrl']

def lambda_handler(event, context):
    print("event: ", event)
    conn = pymysql.connect(host=db_host, user=db_user, passwd=db_password, db=db_name, connect_timeout=5)
    print(conn)
    cur = conn.cursor()
    charge_cash = event["Records"][0]["body"]
    charge_cash = json.loads(charge_cash)
    try:
        charge_cash = charge_cash["charge_amount"]
        print("charge_cash: ", charge_cash, type(charge_cash))
        try:
            cur.execute("select asset from asset_table")
            asset = cur.fetchall()[0][0]
            print("asset: ", asset)
            
            asset = asset + charge_cash
            print("asset: ", asset)
            
            cur.execute("update asset_table set asset={}".format(asset))
            conn.commit()
            cur.close()
            return "update success"
        except Exception as e:
            print("error : ", str(e))
            return "update fail"
    except Exception as e:
        return "another request"