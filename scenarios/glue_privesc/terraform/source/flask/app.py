from flask import Flask, render_template, request
import os
import boto3
import s3
import db
from datetime import datetime, timedelta
import matplotlib.pyplot as plt
from decimal import Decimal
import psycopg2

app = Flask(__name__)

s3_connect = boto3.client(
    "s3",
    aws_access_key_id=s3.AWS_ACCESS_KEY_ID,
    aws_secret_access_key=s3.AWS_SECRET_ACCESS_KEY,
)

cur = db.conn.cursor()


def file_filtering(filename):
    block_file_format = ["xlsx", "tsv", "json", "xml", "sql", "yaml", "ini", "jsonl"]
    _format = filename.split(".")[-1]
    _format = _format.lower()

    if _format in block_file_format:
        return True
    else:
        return False


def upload_to_s3(file, bucket_name, filename):
    try:
        cur.execute("delete from cc_data")
        db.conn.commit()
        s3_connect.upload_fileobj(file, bucket_name, filename)
        loader_display = "block"
        return render_template("upload.html", loader_display=loader_display)
    except Exception as e:
        loader_display = "none"
        return render_template("upload.html", loader_display=loader_display)


def make_octdate():
    start_date = datetime(2023, 10, 2)
    end_date = datetime(2023, 10, 31)
    date_list = []

    while start_date <= end_date:
        date_list.append(start_date.strftime("%Y-%m-%d"))
        start_date += timedelta(days=1)
    return date_list


def show_graph(result):
    # 데이터 처리 및 변환
    data_dict = {}
    for row in result:
        country_code, purchase_cnt, avg_price_decimal = row
        avg_price = float(avg_price_decimal) if avg_price_decimal is not None else 0.0
        # country_code가 None인 경우 "Unknown"으로 처리
        country_code = country_code if country_code is not None else "Unknown"
        if country_code in data_dict:
            data_dict[country_code]["purchase_cnt"] += purchase_cnt
            data_dict[country_code]["avg_price"] += avg_price
        else:
            data_dict[country_code] = {
                "purchase_cnt": purchase_cnt,
                "avg_price": avg_price,
            }

    countries = list(data_dict.keys())
    purchase_counts = [entry["purchase_cnt"] for entry in data_dict.values()]
    avg_prices = [entry["avg_price"] for entry in data_dict.values()]

    # 그래프 설정
    fig, ax1 = plt.subplots()

    # 수직 막대 그래프
    ax1.bar(countries, purchase_counts, color="b", alpha=0.7, label="Purchase Count")
    ax1.set_xlabel("Country Code")
    ax1.set_ylabel("Purchase Count", color="b")
    ax1.tick_params(axis="y", labelcolor="b")

    # 오른쪽 y 축 (평균 가격)
    ax2 = ax1.twinx()
    ax2.plot(countries, avg_prices, color="r", marker="o", label="Average Price")
    ax2.set_ylabel("Average Price", color="r")

    # 그래프 제목 및 범례
    plt.title("Purchase Count and Average Price by Country")
    plt.legend(loc="upper left")

    # 파일 경로 및 파일명 확인
    file_path = "./static/graph.png"
    if file_path:
        # 그래프를 이미지 파일로 저장
        plt.savefig(file_path)


@app.route("/", methods=["GET", "POST"])
def index():
    cur.execute("select * from cc_data")
    result = cur.fetchall()
    show_graph(result)

    date = make_octdate()
    cur.execute("select * from original_data where order_date='2023-10-01'")
    result = cur.fetchall()
    if request.method == "POST":
        try:
            selected_date = request.form["selected_date"]
            # print("selected_date : ", selected_date)
            cur.execute(
                "select * from original_data where order_date='{}'".format(
                    selected_date
                )
            )
            result = cur.fetchall()
        except psycopg2.errors.InFailedSqlTransaction as e:
            # Rollback the transaction
            db.conn.rollback()
    return render_template("index.html", result=result, date=date)


@app.route("/upload")
def upload():
    return render_template("upload.html", loader_display="none")


@app.route("/upload_to_s3", methods=["POST"])
def upload_file():
    file = request.files["file"]
    filename = file.filename

    if file_filtering(filename):
        return "file format is not valid"

    if not file:
        return "file is not valid"

    return upload_to_s3(file, s3.AWS_BUCKET_NAME, filename)


if __name__ == "__main__":
    app.run(host="0.0.0.0", debug=True)
else:
    db.conn.close()
    cur.close()
