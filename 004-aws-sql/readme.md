# Small Internet Store Database

This project sets up a small internet store database using AWS RDS (MySQL) and an EC2 instance for initialization, all provisioned via Terraform. The database includes tables for customers, products, orders, and order items, with sample data and SQL JOIN queries to analyze the data.

## Overview

- **Database**: MySQL 5.7 on AWS RDS
- **Tables**: Customers, Products, Orders, Order_Items
- **Infrastructure**: Terraform provisions an RDS instance, VPC, subnets, security groups, and an EC2 instance (Ubuntu 20.04) to initialize the database.
- **Customers**: `customer_id`, `first_name`, `last_name`, `email`
- **Products**: `product_id`, `product_name`, `price`
- **Orders**: `order_id`, `customer_id`, `order_date`
- **Order_Items**: `order_item_id`, `order_id`, `product_id`, `quantity`

The sample data includes:
- Customers: John Doe, Jane Smith
- Products: Laptop (999.99), Mouse (19.99), Keyboard (49.99)
- Orders: Order #1 (John, 2025-03-01), Order #2 (Jane, 2025-03-02)
- Order_Items: Laptop (1), Mouse (2) in Order #1; Keyboard (1) in Order #2

## Query 1: All Orders with Customer and Product Details

```sql
SELECT 
    o.order_id,
    c.first_name,
    c.last_name,
    p.product_name,
    oi.quantity,
    p.price,
    (oi.quantity * p.price) AS total_cost
FROM Orders o
INNER JOIN Customers c ON o.customer_id = c.customer_id
INNER JOIN Order_Items oi ON o.order_id = oi.order_id
INNER JOIN Products p ON oi.product_id = p.product_id;

+----------+------------+-----------+--------------+----------+--------+------------+
| order_id | first_name | last_name | product_name | quantity | price  | total_cost |
+----------+------------+-----------+--------------+----------+--------+------------+
|        1 | John       | Doe       | Laptop       |        1 | 999.99 |     999.99 |
|        1 | John       | Doe       | Mouse        |        2 |  19.99 |      39.98 |
|        2 | Jane       | Smith     | Keyboard     |        1 |  49.99 |      49.99 |
+----------+------------+-----------+--------------+----------+--------+------------+

Purpose: Retrieves detailed information about all orders, including customer names, product names, quantities, prices, and the total cost per item.
JOINs:
    INNER JOIN Customers c ON o.customer_id = c.customer_id: Links each order to its customer using the customer_id.
    INNER JOIN Order_Items oi ON o.order_id = oi.order_id: Connects each order to its items using the order_id.
    INNER JOIN Products p ON oi.product_id = p.product_id: Links each order item to its product details using the product_id.

Calculation: oi.quantity * p.price computes the total cost for each line item.
Behavior: Only includes rows where all joins succeed (completed orders with items and products).

## Query 2: All Customers and Their Orders (LEFT JOIN)

```sql
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    o.order_id,
    o.order_date
FROM Customers c
LEFT JOIN Orders o ON c.customer_id = o.customer_id;

+-------------+------------+-----------+----------+------------+
| customer_id | first_name | last_name | order_id | order_date |
+-------------+------------+-----------+----------+------------+
|           1 | John       | Doe       |        1 | 2025-03-01 |
|           2 | Jane       | Smith     |        2 | 2025-03-02 |
+-------------+------------+-----------+----------+------------+


Purpose: Lists all customers and their orders, including customers who haven’t placed any orders.
JOIN:

    LEFT JOIN Orders o ON c.customer_id = o.customer_id: Starts with all customers and matches orders where available. If a customer has no orders, order_id and order_date will be NULL.

Behavior: Ensures every customer appears in the result, even those without orders.

## Query 3: Total Order Value per Customer

```sql
SELECT 
    c.first_name,
    c.last_name,
    o.order_id,
    SUM(oi.quantity * p.price) AS order_total
FROM Customers c
INNER JOIN Orders o ON c.customer_id = o.customer_id
INNER JOIN Order_Items oi ON o.order_id = oi.order_id
INNER JOIN Products p ON oi.product_id = p.product_id
GROUP BY c.customer_id, o.order_id;

+------------+-----------+----------+-------------+
| first_name | last_name | order_id | order_total |
+------------+-----------+----------+-------------+
| John       | Doe       |        1 |     1039.97 |
| Jane       | Smith     |        2 |       49.99 |
+------------+-----------+----------+-------------+

Purpose: Calculates the total value of each order, aggregated by customer and order.
JOINs:

    INNER JOIN Orders o ON c.customer_id = c.customer_id: Links customers to their orders.
    INNER JOIN Order_Items oi ON o.order_id = oi.order_id: Connects orders to their items.
    INNER JOIN Products p ON oi.product_id = p.product_id: Links items to product prices.

Aggregation:

    SUM(oi.quantity * p.price): Sums the total cost (quantity * price) for all items in each order.
    GROUP BY c.customer_id, o.order_id: Groups results by customer and order to get one total per order.

Behavior: Only includes customers with orders (due to INNER JOINs).

## Query 4: All Products and Their Order History (RIGHT JOIN Alternative as LEFT JOIN)

```sql
SELECT 
    p.product_name,
    p.price,
    oi.order_id,
    oi.quantity
FROM Products p
LEFT JOIN Order_Items oi ON p.product_id = oi.product_id;

+--------------+--------+----------+----------+
| product_name | price  | order_id | quantity |
+--------------+--------+----------+----------+
| Laptop       | 999.99 |        1 |        1 |
| Mouse        |  19.99 |        1 |        2 |
| Keyboard     |  49.99 |        2 |        1 |
+--------------+--------+----------+----------+

Purpose: Lists all products and their order history, including products that haven’t been ordered.
JOIN:

    LEFT JOIN Order_Items oi ON p.product_id = oi.product_id: Starts with all products and matches order items where they exist. If a product hasn’t been ordered, order_id and quantity will be NULL.

Behavior:
    Ensures every product is listed, even those not in any order.