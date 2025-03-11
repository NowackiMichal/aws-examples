# Migrate DB

This project sets up AWS RDS, PostgreSQL and migrate DB from RDS to PostgreSQL.

## Task

- Create AWS RDS
- Create instance with PostgreSQL
- Prepare DB for migration (mysqldump)
- Copy DB to PostgreSQL instance
- Conversion of mysqldump to PostgreSQL format
- Migrate DB
- Verify migration.

```bash
mysqldump -u nebo -p -h <DB_ENDPOINT> --no-tablespaces --single-transaction --set-gtid-purged=OFF --column-statistics=0 --compatible=ansi nebotask > nebotask_db_mysql.sql
```
```bash
root@ip-10-0-1-27:/home/ubuntu# pgloader /home/ubuntu/nebotask_db_mysql.sql postgresql://<USER>:<PASSWORD>@localhost/<DB_NAME>
2025-03-10T14:56:01.016000Z LOG pgloader version "3.6.3~devel"
```

```bash
postgres=# \c nebo_db
You are now connected to database "nebo_db" as user "postgres".
nebo_db=# \dt
          List of relations
 Schema |    Name     | Type  | Owner 
--------+-------------+-------+-------
 public | Customers   | table | nebo
 public | Order_Items | table | nebo
 public | Orders      | table | nebo
 public | Products    | table | nebo
(4 rows)

nebo_db=# SELECT 
    o.order_id,
    c.first_name,
    c.last_name,
    p.product_name,
    oi.quantity,
    p.price,
    (oi.quantity * p.price) AS total_cost
FROM "Orders" o
INNER JOIN "Customers" c ON o.customer_id = c.customer_id
INNER JOIN "Order_Items" oi ON o.order_id = oi.order_id
INNER JOIN "Products" p ON oi.product_id = p.product_id;
 order_id | first_name | last_name | product_name | quantity | price  | total_cost 
----------+------------+-----------+--------------+----------+--------+------------
        1 | John       | Doe       | Laptop       |        1 | 999.99 |     999.99
        1 | John       | Doe       | Mouse        |        2 |  19.99 |      39.98
        2 | Jane       | Smith     | Keyboard     |        1 |  49.99 |      49.99
(3 rows)

nebo_db=# SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    o.order_id,
    o.order_date
FROM "Customers" c
LEFT JOIN "Orders" o ON c.customer_id = o.customer_id;
 customer_id | first_name | last_name | order_id | order_date 
-------------+------------+-----------+----------+------------
           1 | John       | Doe       |        1 | 2025-03-01
           2 | Jane       | Smith     |        2 | 2025-03-02
(2 rows)

nebo_db=# SELECT 
    c.first_name,
    c.last_name,
    o.order_id,
    SUM(oi.quantity * p.price) AS order_total
FROM "Customers" c
INNER JOIN "Orders" o ON c.customer_id = o.customer_id
INNER JOIN "Order_Items" oi ON o.order_id = oi.order_id
INNER JOIN "Products" p ON oi.product_id = p.product_id
GROUP BY c.customer_id, o.order_id;
 first_name | last_name | order_id | order_total 
------------+-----------+----------+-------------
 John       | Doe       |        1 |     1039.97
 Jane       | Smith     |        2 |       49.99
(2 rows)

nebo_db=# SELECT 
    p.product_name,
    p.price,
    oi.order_id,
    oi.quantity
FROM "Products" p
LEFT JOIN "Order_Items" oi ON p.product_id = oi.product_id;
 product_name | price  | order_id | quantity 
--------------+--------+----------+----------
 Laptop       | 999.99 |        1 |        1
 Mouse        |  19.99 |        1 |        2
 Keyboard     |  49.99 |        2 |        1
(3 rows)
```
