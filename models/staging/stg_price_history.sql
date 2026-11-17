-- Chaque prix est valable jusqu'au changement de prix suivant (valid_to exclu).
select
    product_id,
    cast(valid_from as date)                    as valid_from,
    lead(cast(valid_from as date)) over (
        partition by product_id order by valid_from
    )                                           as valid_to,
    cast(list_price as numeric(10, 2))          as list_price
from {{ ref('raw_price_history') }}
