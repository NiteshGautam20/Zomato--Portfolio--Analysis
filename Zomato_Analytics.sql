create database projects_portfolio;
use projects_portfolio;
drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'2017-09-22'),
(3,'2017-04-21');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'2014-02-09'),
(2,'2015-01-15'),
(3,'2014-03-22');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'2017-02-14',2),
(3,'2017-09-22',1),
(2,'2018-04-02',3),
(1,'2019-09-12',2),
(1,'2016-09-22',3),
(3,'2016-07-12',2),
(1,'2017-09-16',1),
(1,'2020-09-22',3),
(2,'2021-09-28',1),
(1,'2019-09-17',2),
(1,'2022-09-22',1),
(3,'2019-09-21',1),
(3,'2017-12-22',2),
(3,'2017-06-22',2),
(2,'2020-06-20',2),
(2,'2023-05-17',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;
 
 
 -- 1).what is total amount each customer spent on zomato ?

select s.userid ,sum(price) as total_amount_spent from Sales as s
join product as P on s.product_id = p.product_id
group by s.userid;


-- 2).How many days has each customer visited zomato?

select  userid , count(distinct created_date) as Distinct_days from sales as s
group by  userid;


-- 3) what was the first product purchased by each customer?

select s.userid ,P.product_id , min(created_date) as First_order_date , product_name   from sales as s
inner join product as P on s.product_id = p.product_id
group by s.userid
order by userid;



--  4) what is most purchased item on menu & how many times was it purchased by all customers ?


select userid  , count(product_id) as Purchased_time from sales
where product_id =
   (select product_id  from sales
   group by product_id
   order by count(product_id) desc
   limit 1)
   group by userid;
   
   
   --  5) which item was most popular for each customer?
   
   
   with Purchase_Count as
  ( select userid  ,product_id ,count(product_id) as Purchase_count from sales 
   group by userid , product_id
   order by userid )
   ,rnk as
   (select * , dense_rank() over(partition by userid order by purchase_count desc) as rnk from Purchase_Count )
   select userid , product_id , purchase_count from rnk
   where rnk =1;
   
   
-- 6) which item was purchased first by customer after they become a member ?


select s.userid , s.product_id ,gold_signup_date , first_date_after_memeber  from sales s
join 
(select s.userid  , min(created_date) as first_date_after_memeber ,gold_signup_date from  goldusers_signup as gu
join sales as s on gu.userid = s.userid
where created_date >= gold_signup_date
group by s.userid  
)v 
on s.userid =v.userid and s.created_date = first_date_after_memeber;


-- 7) which item was purchased just before customer became a member?

select s.userid , s.product_id ,gold_signup_date , last_date_before_memeber  from sales s
join 
(select s.userid  , max(created_date) as last_date_before_memeber ,gold_signup_date from  goldusers_signup as gu
join sales as s on gu.userid = s.userid
where created_date <= gold_signup_date
group by s.userid  
)v 
on s.userid =v.userid and s.created_date = last_date_before_memeber;


-- 8). what is total orders and amount spent for each member before they become a member ?

select  s.userid,count(p.product_id) as Total_Orders , sum(price) as total_spent from sales as s
left join goldusers_signup as gu on gu.userid = s.userid
left join product as p on s.product_id = p.product_id
where created_date <= gold_signup_date
group by s.userid;


-- 9). If buying each product generate points for eg 5rs=2 zomato point and each product has different purchasing points 
-- for eg for p1 5rs=1 zomato point,for p2 10rs= 5 zomato point and p3 5rs=1 zomato point 
-- calculate points collected by each customers and for which product most points have been given till now.

with total_spent as
(select s.userid , p.product_id , p.product_name , sum(price) as total_spent from sales as s
join product as p on s.product_id = p.product_id
group by userid , product_id
order by userid)
,points as
(select *, case when product_name ="P1" then round((total_spent/5)*1,0)
           when product_name ="p2" then round((total_spent/10)*5,0)
		   when product_name ="p3" then round((total_spent/5)*1,0)
		   end as Points from total_spent )
 ,Total_cash_bypoints as
 (select userid , round((sum(points)/2)*5,0) As Total_cashbacks_Points from points
 group by userid)
 
 -- Max_points_byProducts 
 (select product_name , sum(points) as Total_points from points 
 group by product_name
 order by Total_points desc 
 limit 1);
 
 
 -- 10). In the first one year after customer joins the gold program (including the join date ) irrespective of 
 --  what customer has purchased earn 5 zomato points for every 10rs spent who earned more more 1 or 3
 -- what int earning in first yr ? 1zp = 2rs
 with purchse_amount_inyear as
(select s.userid , p.product_id , p.product_name , sum(price) as total_spent ,gold_signup_date   from sales as s
left join goldusers_signup as gu on gu.userid = s.userid
left join product as p on s.product_id = p.product_id
where created_date >= gold_signup_date and created_date <= date_add(gold_signup_date , interval 1 year)
group by s.userid )
-- Total_points_erned 
(select *, round((total_spent*0.5),0) as Total_points_earned from purchse_amount_inyear);




-- 11). Rank all transaction of the customers

 select * , dense_rank() over(partition by userid order by created_date asc) as rnk from sales;
 
 
 -- 12). Rank all transaction for each member whenever they are zomato gold member for every non gold member transaction mark as na
 
 select * , case when gold_signup_date is null then 'na' else dense_rank() over(partition by gu.userid order by created_date asc)end  as rnk 
 from goldusers_signup as gu
 right join  sales as s on gu.userid = s.userid and created_date>=gold_signup_date

 

 
 
 
































   
    
   








 



