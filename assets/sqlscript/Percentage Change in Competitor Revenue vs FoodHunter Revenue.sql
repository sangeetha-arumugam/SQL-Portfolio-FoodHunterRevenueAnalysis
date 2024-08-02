CREATE DATABASE foodcompetitor_analysis;

USE foodcompetitor_analysis;

CREATE TABLE vendors(company_id varchar(5) PRIMARY KEY, 
name char(255), 
website varchar(255), 
num_users int, 
num_cities int);

INSERT INTO foodcompetitor_analysis.vendors(company_id,name,website,num_users,num_cities)
VALUES
('C1', 'FoodBae', 'https://www.foodbae.com', 8450, 15),
('C2', 'Yumzo', 'https://www.yumzo.com', 9670, 18),
('C3', 'ZippyEats', 'https://www.zippy.eats.com', 7770, 11),
('C4', 'FlavourGo', 'https://www.flavourgo.com', 9789, 18);

SELECT * FROM vendors;

CREATE TABLE vendors_metrics(id int auto_increment PRIMARY KEY,
company_id varchar(5),
month int,
num_orders int,
num_sales float,
FOREIGN KEY(company_id) references vendors(company_id));

SELECT * FROM vendors_metrics;

INSERT INTO vendors VALUES('C5', 'FoodHunter', 'https://www.foodhunter.com', 10000, 17);

INSERT INTO vendors_metrics(company_id, month, num_orders, num_sales) VALUES('C5', 6, 12502, 347577.5);
INSERT INTO vendors_metrics(company_id, month, num_orders, num_sales) VALUES('C5', 7, 11144, 308601.5);
INSERT INTO vendors_metrics(company_id, month, num_orders, num_sales) VALUES('C5', 8, 10107, 283365.9);
INSERT INTO vendors_metrics(company_id, month, num_orders, num_sales) VALUES('C5', 9, 9365, 258161);

/*Notice, out of all the values over here in number of sales columns, particularly for C4 Company, 
that seems to be in a different unit compared to all the other values*/
/*update vendors metrics table*/


UPDATE vendors_metrics SET num_sales = num_sales * 100000 WHERE company_id = 'C4';

/*Add one more column to this table. The column containing the information of how many restaurants are registered on each application */
/*add new column in vendors table*/


ALTER TABLE foodcompetitor_analysis.vendors ADD COLUMN num_of_res INT;

SELECT * FROM vendors;
/*update new column in vendors table*/
SET SQL_SAFE_UPDATES=0;

UPDATE foodcompetitor_analysis.vendors
SET num_of_res = CASE
	WHEN company_id = 'C1' THEN 120
	WHEN company_id = 'C2' THEN 140
	WHEN company_id = 'C3' THEN 150
	WHEN company_id = 'C4' THEN 110
	WHEN company_id = 'C5' THEN 100
ELSE null     -- set a default value or use NULL is there's no matching company_id
END;

SET SQL_SAFE_UPDATES=1;

SELECT t2.name,
t1.month,
t1.num_sales,
(
(t1.num_sales - LAG(t1.num_sales) OVER (PARTITION BY t1.company_id ORDER BY t1.month)) / LAG(t1.num_sales) OVER (PARTITION BY t1.company_id ORDER BY t1.month)
) * 100 AS percentage_change
FROM vendors_metrics t1
INNER JOIN vendors t2 ON t1.company_id = t2.company_id;

/*While observing that different food delivery applications seems to have different trends based on the monthly revenue. 
While FoodBae has a similar downward trend to food Hunter, 
Yangzhou seems to have a month to month increase in revenue as you can see over here. 
On the other hand, Zippy Eats has been facing an extreme downfall in the revenue, which you can see over here. 
There isn't a particular trend with mixed variations and the revenue for FlavourGo, as you can see over here. 
Thus, you can conclude that this downfall in revenue is more or less Food Hunter centric. 
They need to fix the issues in order to get back on track with their competitors. */



















