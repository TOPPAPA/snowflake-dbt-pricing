-- Indicateurs mensuels par catégorie : CA, marge, taux de marge et remise moyenne pondérée.
with sales as (
    select * from {{ ref('fct_sales') }}
),

products as (
    select product_id, category from {{ ref('dim_products') }}
)

select
    cast(date_trunc('month', s.order_date) as date)             as month,
    p.category,
    count(distinct s.order_id)                                  as nb_orders,
    sum(s.quantity)                                             as units_sold,
    round(sum(s.revenue), 2)                                    as revenue,
    round(sum(s.gross_margin), 2)                               as gross_margin,
    round(sum(s.gross_margin) / nullif(sum(s.revenue), 0), 4)   as margin_rate,
    round(1 - sum(s.revenue) / nullif(sum(s.quantity * s.list_price), 0), 4) as avg_discount_rate
from sales s
join products p on s.product_id = p.product_id
group by 1, 2
