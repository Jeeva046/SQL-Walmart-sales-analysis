Create DATABASE Walmart;

-- Create table
CREATE TABLE sales(
invoice_id VARCHAR(30) NOT NULL PRIMARY KEY,
branch VARCHAR(5) NOT NULL,
city VARCHAR(30) NOT NULL,
customer_type VARCHAR(30) NOT NULL,
gender VARCHAR(10) NOT NULL,
product_line VARCHAR(100) NOT NULL,
unit_price DECIMAL(10,2) NOT NULL,
quantity INT(20) NOT NULL,
vat FLOAT(6,4) NOT NULL,
total DECIMAL(12, 4) NOT NULL,
date DATETIME NOT NULL,
time TIME NOT NULL,
payment VARCHAR(15) NOT NULL,
cogs DECIMAL(10,2) NOT NULL,
gross_margin_pct FLOAT(11,9),
gross_income DECIMAL(12, 4),
rating FLOAT(2, 1)
);


Describe sales;

SELECT * 
FROM Sales;

SELECT * 
FROM Sales
WHERE gross_margin_pct IS NULL OR
gross_income IS NULL OR
rating IS NULL;


------------------- Feature Engineering -----------------------------
-- 1. Time_of_day

SELECT time,( CASE 
			WHEN time BETWEEN "00:00:00" AND "12:00:00" THEN "Morning"
            WHEN time BETWEEN "12:00:00" AND "16:00:00" THEN "Afternoon"
            ELSE "Evening"
		END ) AS time_of_day
FROM sales;

ALTER TABLE Sales ADD COLUMN  Time_of_day VARCHAR(25) ;

UPDATE sales
SET Time_of_day = ( CASE 
			WHEN time BETWEEN "00:00:00" AND "12:00:00" THEN "Morning"
            WHEN time BETWEEN "12:00:00" AND "16:00:00" THEN "Afternoon"
            ELSE "Evening"
		END );
        
-- 2. month name

select date,monthname(date)
FROM sales;

ALTER TABLE Sales ADD COLUMN  month_name VARCHAR(25) ;

UPDATE sales
SET month_name = monthname(date);

-- 3. day name

select date,dayname(date)
FROM sales;

ALTER TABLE Sales ADD COLUMN  day_name  VARCHAR(25) ;

UPDATE sales
SET day_name = dayname(date);

-- 
Select * 
From Sales;

-- -------------- Exploratory Data Analysis (EDA) ----------------------
-- Generic Questions
-- 1.How many distinct cities are present in the dataset?
SELECT distinct City , count( city) as City_Count
FROM sales
GROUP BY City
ORDER BY city_count DESC;

-- 2.In which city is each branch situated?
SELECT Distinct City , branch 
FROM sales
ORDER BY branch;


-- Product Analysis
-- 1.How many distinct product lines are there in the dataset?
Select Distinct Product_line , COUNT( Product_line) As Count
FROM Sales
GROUP BY Product_line
ORDER BY Count DESC;

Select COUNT(Distinct Product_line) AS "No. of Products"
FROM Sales;

-- 2.What is the most common payment method?
SELECT Payment , COUNT(payment) AS "no. of Occurence"
FROM Sales
Group by payment
Order by COUNT(payment) Desc
limit 1;


-- 3.What is the most selling product line?
SELECT Product_line , COUNT(Product_line) AS "no. of Occurence"
FROM Sales
Group by Product_line
Order by COUNT(Product_line) Desc
limit 1;


-- 4.What is the total revenue by month?
Select Month_name , sum(total) AS Total_revenue
FROM Sales
Group BY Month_name
Order by Total_revenue Desc;


-- 5.Which month recorded the highest Cost of Goods Sold (COGS)?
Select Month_name , sum(cogs) AS Total_COGS
FROM Sales
Group BY Month_name
Order by Total_COGS Desc;


-- 6.Which product line generated the highest revenue?
Select Product_line , cast(sum(total)AS decimal(15,2)) AS Total_revenue
FROM Sales
Group BY Product_line
Order by Total_revenue Desc;

-- 7.Which city has the highest revenue?
Select City , cast(sum(total)AS decimal(15,2)) AS Total_revenue
FROM Sales
Group BY City
Order by Total_revenue Desc;

-- 8.Which product line incurred the highest VAT?
Select Product_line , sum(vat) AS VAT
FROM Sales
GROUP BY Product_line
Order by VAT Desc;

-- 9.Retrieve each product line and add a column product_category, indicating 'Good' or 'Bad,'based on whether its sales are above the average.

UPDATE sales
JOIN (
        SELECT invoice_id, 
						CASE 
						WHEN total >= (SELECT AVG(total) FROM sales) THEN 'Good'
						ELSE 'Bad'
                        END AS new_category
    FROM sales
) AS derived_table
ON sales.invoice_id = derived_table.invoice_id
SET sales.Product_category = derived_table.new_category;

SELECT Product_category, COUNT(Product_category)
FROM Sales
GROUP BY Product_category;

-- 10.Which branch sold more products than average product sold?
Select Distinct Branch , sum(quantity) OVER(partition by branch )
FROM Sales;

-- 11.What is the most common product line by gender?
WITH CTE AS (
Select gender, Product_line , Count(product_line) AS count , Row_number() OVER(partition by gender order by  Count(product_line) DESC) AS rn
FROM Sales
GROUP BY gender, Product_line )
Select gender , product_line
FROM CTE 
WHERE rn = 1;

-- 12.What is the average rating of each product line?
SELECT Product_line, cast(avg(rating) AS Decimal(10,1)) AS "Average Rating"
FROM Sales
GROUP BY Product_line;

-- Sales Analysis
-- 1.Number of sales made in each time of the day per weekday
SELECT day_name AS Week_days, count(invoice_id) AS "No. of Sales"
FROM Sales
WHERE day_name NOT IN ("Saturday","Sunday")
GROUP BY day_name;


-- 2.Identify the customer type that generates the highest revenue.
SELECT customer_type, Sum(total) AS Revenue 
FROM Sales
GROUP BY customer_type
ORDER BY Revenue DESC;

-- 3.Which city has the largest tax percent/ VAT (Value Added Tax)?
SELECT day_name AS day, SUM(Vat) AS "Tax percent"
FROM Sales
GROUP BY day_name
ORDER BY SUM(Vat) DESC;

-- 4.Which customer type pays the most in VAT?
SELECT customer_type AS day, SUM(Vat) AS "Tax percent"
FROM Sales
GROUP BY customer_type
ORDER BY SUM(Vat) DESC;

-- Customer Analysis

-- 1.How many unique customer types does the data have?
SELECT distinct customer_type
FROM Sales;

SELECT count(distinct customer_type)
FROM Sales;

-- 2.How many unique payment methods does the data have?
SELECT distinct Payment
FROM Sales;

SELECT count(distinct Payment)
FROM Sales;

-- 3.Which is the most common customer type?
SELECT customer_type, count( customer_type) AS Count
FROM Sales
Group BY customer_type 
Order BY Count DESC
Limit 1;

-- 4.Which customer type buys the most?
SELECT customer_type, count(Invoice_id) AS Count
FROM Sales
Group BY customer_type 
Order BY Count DESC
Limit 1;

-- 5.What is the gender of most of the customers?
SELECT Gender, count(Invoice_id) AS Count
FROM Sales
Group BY Gender 
Order BY Count DESC
Limit 1;

-- 6.What is the gender distribution per branch?
SELECT Branch , Gender, count(Invoice_id) AS Count
FROM Sales
Group BY Gender, Branch
Order BY Branch ;

-- 7.Which time of the day do customers give most ratings?
SELECT Time_of_day,   cast(avg(rating) AS Decimal(10,1)) AS "Average Rating"
FROM Sales
GROUP BY Time_of_day
ORDER BY avg(rating) DESC;

-- 8.Which time of the day do customers give most ratings per branch?
SELECT Branch, Time_of_day,   cast(avg(rating) AS Decimal(10,1)) AS "Average Rating"
FROM Sales
GROUP BY Time_of_day, Branch
ORDER BY Branch  ;

WITH CTE AS ( SELECT Branch, Time_of_day,   
			  cast(avg(rating) AS Decimal(10,1)) AS Average_Rating , 
              row_number() OVER(partition by Branch ORDER BY avg(rating) DESC) AS rn 
              FROM Sales
              GROUP BY Time_of_day, Branch)
SELECT Branch, Time_of_day, Average_Rating
FROM CTE 
WHERE rn = 1;

-- 9.Which day of the week has the best avg ratings?
SELECT day_name, cast(avg(rating) AS Decimal(10,1)) AS Average_Rating
FROM Sales
GROUP BY day_name
ORDER BY Average_Rating DESC;

-- 10.Which day of the week has the best average ratings per branch?
WITH CTE AS ( 
             SELECT  branch, day_name,
             cast(avg(rating) AS Decimal(10,1)) AS Average_Rating,
             row_number() OVER(partition by branch ORDER BY avg(rating) DESC) AS rn
             FROM Sales
             GROUP BY day_name,branch)
SELECT * 
FROM CTE 
WHERE rn = 1;









