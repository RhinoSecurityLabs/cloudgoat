from flask import Flask, render_template, request, url_for, redirect
import db
import time
import sqs
import uuid
import json
import os

app = Flask(__name__)


def check_asset():
    cur = db.conn.cursor()
    cur.execute("select asset from asset_table")
    asset = cur.fetchall()
    cur.close()
    return asset[0][0]


@app.route("/sqs_process", methods=["POST"])
def sqs_process():
    try:
        data = request.get_json()
        if data["auth"] == os.environ["auth"]:
            charge_cash = data["sqs_request"]
            cur = db.conn.cursor()
            cur.execute("select asset from asset_table")
            asset = cur.fetchall()[0][0]
            asset = asset + charge_cash
            cur.execute("update asset_table set asset={}".format(asset))
            db.conn.commit()
            cur.close()
            return "update successs"
        else:
            return "this is not sqs message"

    except Exception as e:
        return str(e)


@app.route("/purchase/<item>", methods=["POST"])
def purchase(item):
    asset = check_asset()
    cur = db.conn.cursor()
    cur.execute("select price from item_table where item='{}'".format(item))
    price = cur.fetchall()[0][0]

    if asset >= price:
        asset = asset - price
        cur.execute("update asset_table set asset={}".format(asset))
        cur.execute(
            "insert into receipt_table (item, price, data) select item, price, data from item_table where item='{}'"
            .format(item))
        db.conn.commit()
        cur.close()
        return redirect(url_for("index"))
    else:
        cur.close()
        return "We don't have enough assets."


@app.route("/initialize_asset", methods=["POST"])
def initialize_asset():
    asset = 3000
    cur = db.conn.cursor()
    cur.execute("update asset_table set asset={}".format(asset))
    cur.execute("delete from receipt_table")
    db.conn.commit()
    cur.close()
    return redirect(url_for("index"))


@app.route("/charge_cash/<cash>", methods=["POST"])
def charge_cash(cash):
    cash = int(cash)
    if cash == 1 or cash == 5 or cash == 10:
        msg = {"charge_amount": cash}
        message_body = json.dumps(msg)
        response = sqs.sqs_client.send_message(QueueUrl=sqs.sqs_queue_url,
                                               MessageBody=message_body)
        time.sleep(10)
        return redirect(url_for("index"))
    else:
        return "BAD Request!!"


@app.route("/charge", methods=["GET", "POST"])
def charge():
    return render_template("charge.html")


@app.route("/receipt", methods=["GET"])
def receipt():
    cur = db.conn.cursor()
    cur.execute("select * from receipt_table")
    result = cur.fetchall()
    result = result[::-1]
    cur.close()
    return render_template("receipt.html", result=result)


@app.route("/", methods=["GET", "POST"])
def index():
    cur = db.conn.cursor()
    db.conn.commit()
    cur.close()
    asset = check_asset()
    return render_template("index.html", asset=asset)


def main():
    app.run(host="0.0.0.0", debug=True)


if __name__ == "__main__":
    main()
