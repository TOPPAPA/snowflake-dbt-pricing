select
    product_id,
    trim(product_name)              as product_name,
    category,
    brand,
    cast(unit_cost as numeric(10, 2)) as unit_cost
from {{ ref('raw_products') }}
