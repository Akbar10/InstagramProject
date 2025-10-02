# 1. How many unique post types are found in the 'fact_content' table? 

SELECT distinct post_type FROM fact_content

# 2. What are the highest and lowest recorded impressions for each post type?

SELECT distinct post_type, MAX(impressions) as highest_impressions ,MIN(impressions) as lowest_impressions
FROM fact_content
group by post_type

# 3. Filter all the posts that were published on a weekend in the month of March and April and export them to a separate csv file.

select f.* 
from fact_content f
join dim_dates d on f.date = d.date
where d.month_name in ("March", "April") and d.weekday_or_weekend = "weekend"

# 4. Create a report to get the statistics for the account. The final output includes the following fields: 
#         • month_name 
#         • total_profile_visits 
#         • total_new_followers 

SELECT d.month_name, SUM(f.profile_visits) as total_profile_visits , SUM(f.new_followers) as total_profile_visits 
FROM dim_dates d
JOIN fact_account f
on d.date = f.date
group by d.month_name

/*5. Write a CTE that calculates the total number of 'likes’ for each 'post_category' during the month of 'July' and subsequently, 
arrange the 'post_category' values in descending order according to their total likes.*/

WITH CTE AS (
SELECT f.post_category, SUM(f.likes) as total_likes
FROM fact_content f
JOIN dim_dates d ON f.date = d.date
WHERE d.month_name = "July"
GROUP BY f.post_category
)

SELECT *
FROM CTE
ORDER BY total_likes DESC

/*6. Create a report that displays the unique post_category names alongside
their respective counts for each month. The output should have three columns:
	• month_name
	• post_category_names
	• post_category_count
Example:
	• 'April', 'Earphone,Laptop,Mobile,Other Gadgets,Smartwatch', '5'
	• 'February', 'Earphone,Laptop,Mobile,Smartwatch', '4'*/
    
SELECT 
d.month_name, GROUP_CONCAT(DISTINCT f.post_category) as post_category_names, COUNT(DISTINCT f.post_category) as post_category_count
FROM dim_dates d
JOIN fact_content f ON d.date = f.date
GROUP BY d.month_name
ORDER BY post_category_count DESC

/*7. What is the percentage breakdown of total reach by post type? The final
output includes the following fields:
• post_type
• total_reach
• reach_percentage */

SELECT 
	post_type, 
    SUM(reach) as total_reach, 
    CONCAT(ROUND(SUM(reach) * 100 / SUM(SUM(reach)) OVER(), 2), "%")  AS reach_percentage
FROM fact_content
GROUP BY post_type
	
/*8. Create a report that includes the quarter, total comments, and total
saves recorded for each post category. Assign the following quarter groupings:
	(January, February, March) → “Q1”
	(April, May, June) → “Q2”
	(July, August, September) → “Q3”
The final output columns should consist of:
	• post_category
	• quarter
	• total_comments
	• total_saves*/
    
SELECT 
    f.post_category,
    CASE 
        WHEN d.month_name IN ('January','February','March') THEN 'Q1'
        WHEN d.month_name IN ('April','May','June') THEN 'Q2'
        WHEN d.month_name IN ('July','August','September') THEN 'Q3'
        ELSE 'Q4'
    END AS quarter,
    SUM(f.comments) AS total_comments,
    SUM(f.saves) AS total_saves
FROM fact_content f
JOIN dim_dates d ON f.date = d.date
GROUP BY f.post_category, quarter

/*9. List the top three dates in each month with the highest number of new
followers. The final output should include the following columns:
	• month
	• date
	• new_followers*/

WITH CTE AS(
	SELECT d.month_name, d.date, f.new_followers,
    ROW_NUMBER() OVER(partition by d.month_name order by f.new_followers desc) as rnk
	FROM dim_dates d
	JOIN fact_account f ON d.date = f.date
)
SELECT month_name as month, date, new_followers
FROM CTE 
where rnk <= 3
ORDER BY month, rnk

/*10. Create a stored procedure that takes the 'Week_no' as input and
generates a report displaying the total shares for each 'Post_type'. The
output of the procedure should consist of two columns:
	• post_type
	• total_shares*/
    

DELIMITER $$

CREATE PROCEDURE GetTotalSharesByWeek(IN week_no_input VARCHAR(10))
BEGIN
    SELECT 
        f.post_type,
        SUM(f.shares) AS total_shares
    FROM fact_content f
    JOIN dim_dates d ON f.date = d.`date`
    WHERE d.week_no = week_no_input
    GROUP BY f.post_type
    ORDER BY total_shares DESC;
END$$

DELIMITER ;

CALL GetTotalSharesByWeek('W1');
CALL GetTotalSharesByWeek('W2');
