-- Test métier : aucune vente ne doit avoir une remise négative ou supérieure à 30 %.
-- Le test échoue s'il renvoie au moins une ligne.
select order_id, discount_rate
from {{ ref('fct_sales') }}
where discount_rate < -0.001
   or discount_rate > 0.301
