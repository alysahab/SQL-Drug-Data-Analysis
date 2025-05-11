USE mydb;

SELECT * FROM mydb.drug_clean;

-- Problem-1: For each condition, what is the average satisfaction level of drugs that are "On Label" vs "Off Label"?
select t.condition, indication, round(avg_satisfaction,2) from (
select d.Condition, d.Indication, 
avg(Satisfaction) over(partition by d.condition, d.indication) avg_satisfaction,
row_number() over(partition by d.condition, d.indication) r
from drug_clean d) t
where r = 1;


-- Problem-2: For each drug type (RX, OTC, RX/OTC), what is the average ease of use and satisfaction level of drugs with a price above the median for their type?

select round((count(*)/2)) total_rows from drug_clean; -- Median row number
-- To find median price I need to sort the total rows based on price in ascending and select the middle value of price out of total rows

with cte as (
select *, row_number() over(order by price) row_num
from drug_clean)
select Type, round(avg(EaseOfUse),2) as AVG_Ease_of_Use, round(avg(Satisfaction),2) as AVG_Satisfacion
from cte
where price > (select price from cte where row_num = (select round(count(*)/2) from cte))
group by Type;


-- Problem 3: What is the cumulative distribution of EaseOfUse ratings for each drug type (RX, OTC, RX/OTC)? 
-- Show the results in descending order by drug type and cumulative distribution. 
-- (Use the built-in method and the manual method by calculating on your own. 
-- or the manual method, use the "ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW" and see if you get the same results as the built-in method.)

select type, 
sum(EaseOfUse) over(partition by Type order by EaseOfUse rows between unbounded preceding and current row) as cumulative_sum,
sum(EaseOfUse) over(partition by type) total_sum, 
sum(EaseOfUse) over(partition by Type order by EaseOfUse rows between unbounded preceding and current row) / 
sum(EaseOfUse) over(partition by type) as cumulative_distribution
from drug_clean;
    
    

-- Problem 4: What is the median satisfaction level for each medical condition? Show the results in descending order by median satisfaction level. 
-- (Don't repeat the same rows of your result.)
with cte as (
select *, row_number() over(partition by drug.Condition order by drug.Satisfaction asc) row_num
from drug_clean as drug)
select cte.Condition, round(Satisfaction,2) Median_Satisfaction
from cte
where cte.row_num = (select round(count(*)/2) from cte c2 where c2.condition = cte.condition)
order by Median_Satisfaction desc;



-- Problem 5: What is the running average of the price of drugs for each medical condition? Show the results in ascending order by medical condition and drug name.

select d.condition, round(avg(price) over(partition by d.condition order by price rows between unbounded preceding and current row),2) as Running_Average
from drug_clean d
order by d.Condition;


-- Problem 6: What is the percentage change in the number of reviews for each drug between 
-- the previous row and the current row?

select drug, reviews, 
		((reviews - lag(reviews) over(partition by drug order by reviews desc))/lag(reviews) over(partition by drug order by reviews desc)) * 100 as percent_change_review
from drug_clean;



-- Problem 7: What is the percentage contribution of total satisfaction level for each drug type (RX, OTC, RX/OTC)? 
-- Show the results in descending order by drug type and percentage of total satisfaction.

select*,round((satisfaction_level/sum(satisfaction_level) over()) * 100,2) percentage_satisfaction
from (
select type, sum(satisfaction) as satisfaction_level
from drug_clean
group by type) t
order by satisfaction_level/sum(satisfaction_level) over() * 100 desc, type;


-- Problem 8: What is the cumulative sum of effective ratings for each medical condition and drug form combination? 
-- Show the results in ascending order by medical condition, drug form and the name of the drug.

select d.condition,drug,form,effective, sum(effective) over(partition by d.condition,form order by Effective rows between unbounded preceding and current row) cumulative_sum
from drug_clean d
order by d.Condition and drug and form;


-- Problem-9: What is the rank of the average ease of use for each drug type (RX, OTC, RX/OTC)? Show the results in descending order by rank and drug type.
select type, 
avg(EaseOfUse) avg_ease,
rank() over(order by avg(EaseOfUse) desc) "rank"
from drug_clean
group by type
order by rank() over(order by avg(EaseOfUse) desc) and type desc;


-- Problem-10: For each condition, what is the average effectiveness of the top 3 most reviewed drugs?

select * from(
select d.condition,reviews,drug,
avg(effective) over(partition by d.condition,drug order by reviews desc) avg_eff,
dense_rank() over(partition by d.condition order by reviews desc) r
from drug_clean d
order by reviews desc) t
where r<4
order by t.condition, r;