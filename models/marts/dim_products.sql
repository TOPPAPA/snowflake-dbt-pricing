with products as (
    select * from {{ ref('stg_products') }}
),

current_price as (
    select product_id, list_price
    from {{ ref('stg_price_history') }}
    where valid_to is null
)

select
    p.product_id,
    p.product_name,
    p.category,
    p.brand,
    p.unit_cost,
    c.list_price                                            as current_list_price,
    round((c.list_price - p.unit_cost) / c.list_price, 4)   as current_margin_rate
from products p
left join current_price c on p.product_id = c.product_id
