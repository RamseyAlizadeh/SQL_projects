/* 
The goal of this project is to analyze data from a sales records database for scale model cars and extract information for decision-making.

Below are the questions we want to answer for this project.

Question 1: Which products should we order more of or less of?
Question 2: How should we tailor marketing and communication strategies to customer behaviors?
Question 3: How much can we spend on acquiring new customers?

This database contains 8 tables:

Customers: customer data
Employees: all employee information
Offices: sales office information
Orders: customers' sales orders
OrderDetails: sales order line for each sales order
Payments: customers' payment records
Products: a list of scale model cars
ProductLines: a list of product line categories 
*/

SELECT 'Customers' AS table_name, 
	   (SELECT COUNT(*)
          FROM pragma_table_info('customers')) AS number_of_attribute,
	    COUNT(*) AS number_of_rows
  FROM customers
 
UNION ALL 
 
SELECT 'Products' AS table_name, 
	   (SELECT COUNT(*)
          FROM pragma_table_info('products')) AS number_of_attribute,
	    COUNT(*) AS number_of_rows
  FROM products
 
UNION ALL
 
SELECT 'ProductLines' AS table_name, 
	   (SELECT COUNT(*)
          FROM pragma_table_info('productlines')) AS number_of_attribute,
	    COUNT(*) AS number_of_rows
  FROM productlines

UNION ALL 

SELECT 'Orders' AS table_name, 
	   (SELECT COUNT(*)
          FROM pragma_table_info('orders')) AS number_of_attribute,
	    COUNT(*) AS number_of_rows
  FROM orders
  
UNION ALL

SELECT 'OrderDetails' AS table_name, 
	   (SELECT COUNT(*)
          FROM pragma_table_info('orderdetails')) AS number_of_attribute,
	    COUNT(*) AS number_of_rows
  FROM orderdetails

UNION ALL

SELECT 'Payments' AS table_name, 
	   (SELECT COUNT(*)
          FROM pragma_table_info('payments')) AS number_of_attribute,
	    COUNT(*) AS number_of_rows
  FROM payments
 
UNION ALL

SELECT 'Employees' AS table_name, 
	   (SELECT COUNT(*)
          FROM pragma_table_info('employees')) AS number_of_attribute,
	    COUNT(*) AS number_of_rows
  FROM employees
 
UNION ALL

SELECT 'Offices' AS table_name, 
	   (SELECT COUNT(*)
          FROM pragma_table_info('offices')) AS number_of_attribute,
	    COUNT(*) AS number_of_rows
  FROM offices;
  
  /*
Question 1: Which products should we order more of or less of?
For that we will check two parameters:  low stock and product performance
Part 1) Low stock:  the quantity of each product sold divided by the quantity of product in stock 
The ten highest rates will be the top ten products that are (almost) out-of-stock.
Part 2) Product performance: sum of sales per product.
Priority products for restocking are those with high product performance that are (almost) out-of-stock.

Question 1_Part 1: Low Stock
*/

SELECT productCode, 
       ROUND(SUM(quantityOrdered) * 1.0 / (SELECT quantityInStock
                                             FROM products p
                                            WHERE od.productCode = p.productCode), 2) AS low_stock
  FROM orderdetails od
 GROUP BY productCode
 ORDER BY low_stock DESC
 LIMIT 10;
 
 /*
Question 1_Part 2: Product Performance
*/

SELECT productCode, 
       SUM(quantityOrdered * priceEach) AS prod_perf
  FROM orderdetails od
 GROUP BY productCode 
 ORDER BY prod_perf DESC
 LIMIT 10;
 
 /*
Priority products for restocking are those with 
high product performance that are going out of stock.

Step 1
*/
WITH

low_stock_table AS (
SELECT productCode, 
       ROUND(SUM(quantityOrdered) * 1.0 / (SELECT quantityInStock
                                             FROM products p
                                            WHERE od.productCode = p.productCode), 2) AS low_stock
  FROM orderdetails od
 GROUP BY productCode
 ORDER BY low_stock DESC
 LIMIT 10
 )
 
SELECT productCode,
       SUM(quantityOrdered * priceEach) AS prod_perf
  FROM orderdetails od
 WHERE productCode IN (SELECT productCode
                         FROM low_stock_table)
 GROUP BY productCode 
 ORDER BY prod_perf DESC
 LIMIT 10;
 
 /*
Priority products for restocking are those with 
high product performance that are going out of stock.

Step 2
*/
WITH

low_stock_table AS (
SELECT productCode, 
       ROUND(SUM(quantityOrdered) * 1.0 / (SELECT quantityInStock
                                             FROM products p
                                            WHERE od.productCode = p.productCode), 2) AS low_stock
  FROM orderdetails od
 GROUP BY productCode
 ORDER BY low_stock DESC
 LIMIT 10
 ),
 
performance AS (
SELECT productCode,
       SUM(quantityOrdered * priceEach) AS prod_perf
  FROM orderdetails od
 WHERE productCode IN (SELECT productCode
                         FROM low_stock_table)
 GROUP BY productCode 
 ORDER BY prod_perf DESC
 LIMIT 10
 )
 
SELECT productCode, productName, productLine
  FROM products p
 WHERE productCode IN (SELECT productCode
                         FROM performance);

/*
Question 2: How Should We Match Marketing and Communication Strategies to Customer Behavior?
We compute how much profit each customer generates. From there, we can launch a campaign for the less engaged customers.
*/

SELECT customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS profit
  FROM products p
  JOIN orderdetails od
    ON p.productCode = od.productCode
  JOIN orders o
    ON o.orderNumber = od.orderNumber
 GROUP BY customerNumber;
 
 -- Top 5 VIP
WITH 
customer__money_table AS (
SELECT customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS revenue
  FROM products p
  JOIN orderdetails od
    ON p.productCode = od.productCode
  JOIN orders o
    ON o.orderNumber = od.orderNumber
 GROUP BY customerNumber
)
SELECT contactLastName, contactFirstName, city, country, cm.revenue
  FROM customers c
  JOIN customer__money_table cm
    ON cm.customerNumber = c.customerNumber
 ORDER BY cm.revenue DESC
 LIMIT 5;
 
 -- Top 5 less enaging customers
WITH 
customer__money_table AS (
SELECT customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS revenue
  FROM products p
  JOIN orderdetails od
    ON p.productCode = od.productCode
  JOIN orders o
    ON o.orderNumber = od.orderNumber
 GROUP BY customerNumber
)
SELECT contactLastName, contactFirstName, city, country, cm.revenue
  FROM customers c
  JOIN customer__money_table cm
    ON cm.customerNumber = c.customerNumber
 ORDER BY cm.revenue
 LIMIT 5;
 
/*
Question 3: How much can we spend on acquiring new customers?
Customer Lifetime Value (LTV): the average amount of money a customer generates or the profit an average customer generates during their lifetime with the store
*/

WITH 
customer__money_table AS (
SELECT customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS revenue
  FROM products p
  JOIN orderdetails od
    ON p.productCode = od.productCode
  JOIN orders o
    ON o.orderNumber = od.orderNumber
 GROUP BY customerNumber
)
SELECT AVG(cm.revenue) AS LTV
 FROM customer__money_table cm;