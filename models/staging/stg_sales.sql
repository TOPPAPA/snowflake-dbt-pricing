select
    order_id,
    cast(order_date as date)                    as order_date,
    customer_id,
    product_id,
    cast(quantity as integer)                   as quantity,
    cast(unit_price_paid as numeric(10, 2))     as unit_price_paid
from {{ ref('raw_sales') }}
