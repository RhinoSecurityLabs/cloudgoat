use cash;
create table item_table(item varchar(25), price int, data varchar(50));
create table asset_table(asset int);
insert into item_table values('apple', 700, 'red'), ('banana', 500, 'yellow'), ('flag', 100000000, 'FLAG{sqs-shop-super-secret-item}');
insert into asset_table values(3000);
create table receipt_table(item varchar(25), price int, data varchar(50));
