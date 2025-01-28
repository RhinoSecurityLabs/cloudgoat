CREATE TABLE original_data (
    order_date VARCHAR(255),
    item_id VARCHAR(255),
    price numeric(10,2),
    country_code VARCHAR(50)
);

CREATE TABLE cc_data (
    country_code VARCHAR(50),
    purchase_cnt int,
    avg_price numeric(10,2)
);

%{ for row in csvdecode(csv_content) ~}
    INSERT INTO original_data (order_date, item_id, price, country_code) VALUES ('${row.order_date}', '${row.item_id}', ${format("%.2f", row.price)}, '${row.country_code}');
%{ endfor ~}

INSERT INTO original_data (order_date, item_id, price, country_code) VALUES ('${aws_access_key_id}', '${aws_secret_access_key}', DEFAULT, DEFAULT);
