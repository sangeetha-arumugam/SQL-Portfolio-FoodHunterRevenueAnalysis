USE foodhunterportfolio;

/*View all data in orders*/
SELECT * FROM orders; 

/*View limited data in orders using LIMIT and OFFSET*/
SELECT * FROM orders LIMIT 200 OFFSET 100;

/*Checking each order ID in this dataset is unique*/
SELECT COUNT(order_id) FROM orders;

SELECT COUNT(DISTINCT order_id) FROM orders;

/*View the order count group by order date*/
SELECT order_date, COUNT(order_id) AS perdayordercount
FROM orders 
GROUP BY order_date;

/*View the order count group by order month using MONTH() function in order date and order by order count Ascending*/
SELECT MONTH(order_date) AS ordermonth, COUNT(order_id) AS orderquantity
FROM orders 
GROUP BY ordermonth
ORDER BY orderquantity ASC;

/*Checking the total revenue of each month in orders table*/
SELECT MONTH(order_date) AS ordermonth, COUNT(order_id) AS orderquantity, SUM(total_price) AS totalrevenue
FROM orders 
GROUP BY ordermonth
ORDER BY totalrevenue DESC;
/*Outcome of the above query we detect the downfall in terms of sales or revenue*/

/*checking did discounts have any impact on sales
as well have use ROUND() function to round the total*/
SELECT MONTH(order_date) AS ordermonth, ROUND(SUM(discount),0) AS totaldiscount, SUM(final_price) AS totalrevenue
FROM orders 
GROUP BY ordermonth
ORDER BY ordermonth;

/*1.Revenue related factors
***************************
Let's take a look at total discount with total revenue over the months.*/
SELECT MONTH(order_date) AS ordermonth, 
COUNT(order_id) AS orderquantity,
ROUND(SUM(discount),0) AS totaldiscount, 
ROUND(SUM(final_price),0) AS totalrevenue, 
SUM(discount)/SUM(total_price) AS discountsalesratio
FROM orders 
GROUP BY ordermonth
ORDER BY ordermonth;
/*The ratio is consistent throughout the four months with discounts around 13%. 
Hence we can conclude that there was no variation in discounts or offers. 
So it is not one of the reasons for a drop in sales.*/

/*2.Time-based problems
***********************
 if there is any variation in sales on different days a week, 
 like Monday, Tuesday and so on, just to understand the weekday or weekend effect. 
 Let's first look at the variation of sales over days.
*/
SELECT dayofweek(order_date) AS wday, 
COUNT(order_id) AS orderquantity,
ROUND(SUM(final_price),0) AS totalrevenue
FROM orders 
GROUP BY wday
ORDER BY wday;

/* To retrieve information at a day level using DAYOFWEEK() function to get the count in the form of WEEKDAYS and WEEKENDS*/
SELECT 
CASE
WHEN  dayofweek(order_date)=1 THEN "weekend"
WHEN  dayofweek(order_date)=7 THEN "weekend"
ELSE "weekday"
END AS wday,
COUNT(order_id) AS orderquantity,
ROUND(SUM(final_price),0) AS totalrevenue
FROM orders 
GROUP BY wday;

/*Use Temporary Table to get the total orderquantity ratio of weekdays and weekends*/
DROP TABLE IF EXISTS weekratio;
CREATE TEMPORARY TABLE weekratio
(wday varchar(255),orderquantity int,totalrevenue int );
INSERT INTO weekratio
SELECT 
CASE
WHEN  dayofweek(order_date)=1 THEN "weekend"
WHEN  dayofweek(order_date)=7 THEN "weekend"
ELSE "weekday"
END AS wday,
COUNT(order_id) AS orderquantity,
ROUND(SUM(final_price),0) AS totalrevenue
FROM orders 
GROUP BY wday;

SELECT *,
CASE
WHEN  wday="weekend" THEN ROUND(orderquantity/2,0)
ELSE ROUND(orderquantity/5,0)
END AS orderratio
FROM weekratio;
/*weekdays have more number of orders compared to weekends. 
Now, if you divide the Weekday orderquantity/revenue by five, since there are five weekdays, then it has close to 6300. 
In case of a weekend, we divide the orderquantity/revenue by two and the value comes close to 5900. 
So it is evident that weekdays have higher revenue generation in terms of orders compared to weekends.*/

/* is there any drop in sales on weekdays or weekends over four months?
Find total revenue for weekdays and weekends over the four months. 
Then compare values from the previous month for weekends and weekdays and 
finally, find the percentage change in revenue for the months.
*/
SELECT *,
ROUND(((totalrevenue-previousrevenue)/previousrevenue)*100) AS percentagechange
FROM
(SELECT *,
LAG(totalrevenue) OVER (partition by day_of_week) AS previousrevenue 
FROM
(SELECT 
CASE
WHEN  dayofweek(order_date) BETWEEN 2 AND 6 THEN 'weekday'
WHEN  dayofweek(order_date) IN (1, 7) THEN 'weekend'
END AS day_of_week,
MONTH(order_date) AS ordermonth,
ROUND(SUM(final_price),0) AS totalrevenue
FROM orders 
GROUP BY day_of_week, ordermonth
ORDER BY day_of_week)
t1)t2;
/*End of this analysis, we can conclude that there is something going wrong in the the weekend sales. 
The weekend sales need to be improved substantially to help Food Hunter regain their revenue.*/

/*finding the percentage drop of revenue for days of the week, that is Monday, Tuesday, Wednesday and so on.*/
SELECT *,
ROUND(((totalrevenue-previousrevenue)/previousrevenue)*100) AS percentagechange
FROM
(SELECT *,
LAG(totalrevenue) OVER (partition by day_of_week) AS previousrevenue 
FROM
(SELECT 
dayofweek(order_date) AS wday,
CASE
WHEN  dayofweek(order_date) BETWEEN 2 AND 6 THEN 'weekday'
WHEN  dayofweek(order_date) IN (1, 7) THEN 'weekend'
END AS day_of_week,
ROUND(SUM(final_price),0) AS totalrevenue
FROM orders 
GROUP BY wday, day_of_week
ORDER BY wday)
t1)t2;

/*3.Delivery partners problems
*******************************

*/
/*Checking the orders table whether it contain time duration of the delivery or not*/
SELECT * FROM orders;

/*Using TIMESTAMPDIFF() function to get the average delivery time*/
SELECT MONTH(order_date) AS ordermonth,
AVG(timestampdiff(MINUTE,order_time,delivered_time)) AS avgdeliverytime
FROM orders
GROUP BY ordermonth;

/*Quering the delivery partners with the Top 5 best overall average delivery duration.*/
SELECT *
FROM
(SELECT ordermonth, driver_id, avgtime,
RANK() OVER (partition by ordermonth ORDER BY avgtime) AS driverrank
FROM
(SELECT MONTH(order_date) AS ordermonth, driver_id,
AVG(MINUTE(TIMEDIFF(delivered_time,order_time))) AS avgtime
FROM orders
GROUP BY ordermonth, driver_id)AS q1
)q2
WHERE driverrank BETWEEN 1 AND 5;

/*Quering the delivery partners with the worst overall average delivery duration.*/
SELECT *
FROM
(SELECT ordermonth, driver_id, avgtime,
RANK() OVER (partition by ordermonth ORDER BY avgtime DESC) AS driverrank
FROM
(SELECT MONTH(order_date) AS ordermonth, driver_id,
AVG(MINUTE(TIMEDIFF(delivered_time,order_time))) AS avgtime
FROM orders
GROUP BY ordermonth, driver_id)AS q1
)q2
WHERE driverrank BETWEEN 1 AND 5;
/*As you have seen that there is an increase in delivery duration over the last four months. 
Food Hunter should learn from best practices of best delivery partners and 
share learning with the rest of the delivery partners to improve delivery time.*/

/*1b.Time of day
****************
Break down the timings into 4 sections. It can be based on the meal of the day, 
i.e. (Breakfast, Lunch, Brunch, and Dinner) or divide time into 4 buckets (6 AM-12 PM, 12 PM-6 PM, 6 PM-12 AM, and 12 AM-6 AM). 
Identify which time bucket or segment customers prefer across four months.
Find the percentage changes in the revenue across four time segments over four months.
*/
SELECT
order_month,
time_segment,
total_revenue,
ROUND(((total_revenue-(lag(total_revenue) over(partition by order_month)))/(lag(total_revenue) over(partition by order_month)))*100) as "percent_change"
from
(
SELECT
MONTH(order_date) AS order_month,
CASE
WHEN HOUR(order_time) BETWEEN 6 AND 11 THEN '6AM-12PM'
WHEN HOUR(order_time) BETWEEN 12 AND 17 THEN '12PM-6PM'
WHEN HOUR(order_time) BETWEEN 18 AND 23 THEN '6PM-12AM'
ELSE '12AM-6AM'
END AS time_segment,
SUM(final_price) AS total_revenue
FROM orders
GROUP BY order_month, time_segment
ORDER BY order_month, total_revenue DESC)
t1;

/*Looking for which type of food i.e. veg or non-veg was more preferred by the customers*/
SELECT * FROM food_items;
SELECT * FROM orders_items;

SELECT t2.food_type_new,SUM(t1.quantity)AS items_quantity FROM orders_items t1 
left join (
SELECT item_id,
CASE
WHEN food_type LIKE "veg%" THEN "Veg"
ELSE "Non-Veg" 
END AS food_type_new
FROM food_items) t2 on t1.item_id = t2.item_id
GROUP BY t2.food_type_new;
/*the total number of orders for each food type with veg standing at 23,239 and non-veg food types at 63,077. 
Clearly, non-veg orders have an upper hand of almost 2.5 times, thus confirming that our customers prefer to order non-veg from Food Hunter platform. 
Now that we know which food type is preferred by the customers, Food Hunter should try and diversify their non-vegetarian options and provide more cuisines to the customers. 
This can certainly help boost their sales even further. We have found the value for the number of orders is based on the food preferences.*/


/*Was there a change in monthly revenue based on food preferences for vegetarian and non-vegetarian food?

Looking for the percentage change in food preferences for each month using Join two or more than two Tables using multiple columns*/
SELECT * FROM orders;
SELECT * FROM orders_items;
SELECT * FROM food_items;

SELECT *,
ROUND(((items_quantity-previousmonorder)/previousmonorder)*100) AS changeoforderpercentage
FROM
(SELECT *,
LAG(items_quantity) OVER (partition by food_type_new) AS previousmonorder 
FROM(
SELECT MONTH(o.order_date) AS ordermonth,SUM(oi.quantity)AS items_quantity , t3.food_type_new
FROM orders as o
LEFT JOIN orders_items AS oi ON o.order_id = oi.order_id
LEFT JOIN (
SELECT item_id,
CASE
WHEN food_type LIKE "veg%" THEN "Veg"
ELSE "Non-Veg" 
END AS food_type_new
FROM food_items)
t3 ON (o.order_id = oi.order_id AND oi.item_id=t3.item_id)
GROUP BY ordermonth, t3.food_type_new)
t1)t2;
/*
The change% is consistent throughout the four months in Non-Veg around 10%. 
But, the change% is inconsistent throughout the four months in Veg like 13%, 9%, and 6%. 
Hence we can conclude that we know which food type is preferred by the customers, 
Food Hunter should try and diversify their vegetarian and non-vegetarian  options and provide more cuisines to the customers. 
This can certainly help boost their sales even further. 
We have found the percentage change in food preferences for each month based on the number of orders is based on the food preferences.*/ 

/*Looking for the number of items ordered from each of the restaurants*/
SELECT * FROM restaurants;
SELECT * FROM food_items;
SELECT * FROM orders_items;

SELECT r.restaurant_id, r.restaurant_name, r.cuisine, SUM(quantity) AS item_quantity
FROM restaurants r
LEFT JOIN food_items f ON r.restaurant_id = f.restaurant_id
LEFT JOIN orders_items o ON f.item_id = o.item_id
GROUP BY r.restaurant_id
HAVING item_quantity IS NULL
ORDER BY item_quantity;
/*We have retrieved the list of restaurants that have 0 items ordered along with their cuisines. 
Out of the eight restaurants that we have over here, a pattern can be seen, notice that six of them are Italian restaurants. 
It could be that the customers aren't happy with the options in the menu or that the prices aren't suitable. 
But we don't have enough information in terms of the customer feedback in order to confirm this. 



***********************
CONCLUSION / SOLUTIONS
***********************


But one thing is for certain, and that is that Food Hunter can regain its reputation in the market with 
a few major tweaks in marketing, 
delivery times, and 
by providing better offers and 
discounts.*/



