-- Associe chaque vente au prix catalogue en vigueur à la date de commande,
-- puis calcule le chiffre d'affaires, la remise et la marge.
with sales as (
    select * from {{ ref('stg_sales') }}
),

prices as (
    select * from {{ ref('stg_price_history') }}
),

products as (
    select * from {{ ref('stg_products') }}
)

select
    s.order_id,
    s.order_date,
    s.customer_id,
    s.product_id,
    s.quantity,
    p.list_price,
    s.unit_price_paid,
    pr.unit_cost,
    s.quantity * s.unit_price_paid                          as revenue,
    s.quantity * pr.unit_cost                               as cost,
    s.quantity * (s.unit_price_paid - pr.unit_cost)         as gross_margin,
    round(1 - s.unit_price_paid / p.list_price, 4)          as discount_rate
from sales s
left join prices p
    on  s.product_id = p.product_id
    and s.order_date >= p.valid_from
    and (p.valid_to is null or s.order_date < p.valid_to)
left join products pr
    on s.product_id = pr.product_id
