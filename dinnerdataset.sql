create database dinnerdb;
use dinnerdb;

CREATE TABLE sales(
	customer_id VARCHAR(1),
	order_date DATE,
	product_id INTEGER
);

INSERT INTO sales
	(customer_id, order_date, product_id)
VALUES
	('A', '2021-01-01', 1),
	('A', '2021-01-01', 2),
	('A', '2021-01-07', 2),
	('A', '2021-01-10', 3),
	('A', '2021-01-11', 3),
	('A', '2021-01-11', 3),
	('B', '2021-01-01', 2),
	('B', '2021-01-02', 2),
	('B', '2021-01-04', 1),
	('B', '2021-01-11', 1),
	('B', '2021-01-16', 3),
	('B', '2021-02-01', 3),
	('C', '2021-01-01', 3),
	('C', '2021-01-01', 3),
	('C', '2021-01-07', 3);

CREATE TABLE menu(
	product_id INTEGER,
	product_name VARCHAR(5),
	price INTEGER
);

INSERT INTO menu
	(product_id, product_name, price)
VALUES
	(1, 'sushi', 10),
    (2, 'curry', 15),
    (3, 'ramen', 12);

CREATE TABLE members(
	customer_id VARCHAR(1),
	join_date DATE
);

INSERT INTO members
	(customer_id, join_date)
VALUES
	('A', '2021-01-07'),
    ('B', '2021-01-09');
    
-- 1. What is the total amount each customer spent at the restaurant?
select s.customer_id,sum(price)as total_amount 
from sales as s
join menu as m on s.product_id=m.product_id
group by s.customer_id;

-- 2. How many days has each customer visited the restaurant?
select customer_id,count(distinct(order_date)) as total_count
from sales
group by customer_id;


-- 3. What was the first item from the menu purchased by each customer?
with cte as (
select s.customer_id,m.product_name,min(s.order_date)as first_order_date,rank() over (partition by s.customer_id order by min(s.order_date)) as rn
from menu as m
join sales as s on m.product_id=s.product_id
group by s.customer_id,m.product_name)
select cte.customer_id,cte.product_name,cte.first_order_date from cte where rn=1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select m.product_name,count(*) as totalcount
from sales as s 
join menu as m on s.product_id=m.product_id
group by m.product_name
order by totalcount desc
limit 1;

-- 5. Which item was the most popular for each customer?
with cte as (select s.customer_id,m.product_name,count(*) as pruchase_count,rank() over(partition by s.customer_id order by count(*) desc) as rnk
from sales as s
inner join menu as m on s.product_id=m.product_id
group by s.customer_id,m.product_name)
select * from cte where rnk =1;


-- 6. Which item was purchased first by the customer after they became a member?
with first_purchase_after_membership as (
    select s.customer_id, MIN(s.order_date) as first_purchase_date
    from sales s
    join members mb on s.customer_id = mb.customer_id
    where  s.order_date >= mb.join_date
    group by s.customer_id
)select fpam.customer_id, m.product_name
from first_purchase_after_membership fpam
join sales s on fpam.customer_id = s.customer_id 
and fpam.first_purchase_date = s.order_date
join menu m on s.product_id = m.product_id;


-- 7. Which item was purchased just before the customer became a member?

with last_purchase_before_membership as(
    select s.customer_id, MAX(s.order_date) as last_purchase_date
    from sales s
    join members mb on s.customer_id = mb.customer_id
    where s.order_date < mb.join_date
    group by s.customer_id
)
select lpbm.customer_id, m.product_name
from last_purchase_before_membership lpbm
join sales s on lpbm.customer_id = s.customer_id 
and lpbm.last_purchase_date = s.order_date
join menu m on s.product_id = m.product_id;

-- 8. What is the total items and amount spent for each member before they became a member?
select s.customer_id,count(*) as total_item,sum(m.price)as total_amount
from members as mm 
join sales as s on mm.customer_id=s.customer_id
join menu as m on s.product_id=m.product_id
where s.order_date < mm.join_date
group by s.customer_id
order by total_amount desc;


-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?


select s.customer_id, SUM(
	case
		when m.product_name = 'sushi' then m.price*20 
		else m.price*10
	end) as total_points
from sales s
join  menu m on s.product_id = m.product_id
group by s.customer_id;

/* 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi -
how many points do customer A and B have at the end of January?*/

select s.customer_id, sum(
    case
        when s.order_date between mb.join_date and date_add(mb.join_date,interval 7 day) then m.price*20
        when m.product_name = 'sushi' then m.price*20 
        else m.price*10 
    end) as total_points
from sales s
join menu m on s.product_id = m.product_id
left join members mb on s.customer_id = mb.customer_id
where s.customer_id in ('A', 'B') and s.order_date <= '2021-01-31'
group by s.customer_id
order by total_points desc

















