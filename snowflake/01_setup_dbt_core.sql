-- =====================================================================
-- Mise en place Snowflake pour utiliser dbt Core en local (option B).
-- Inutile si tu passes par dbt Cloud + Partner Connect (option A).
-- À exécuter dans une feuille de calcul Snowsight avec le rôle ACCOUNTADMIN.
-- =====================================================================

use role accountadmin;

-- 1. Entrepôt de calcul : le plus petit, qui s'arrête après 60 s d'inactivité
create warehouse if not exists transforming_wh
    warehouse_size = 'XSMALL'
    auto_suspend = 60
    auto_resume = true
    initially_suspended = true;

-- 2. Base de données du projet
create database if not exists pricing_db;

-- 3. Rôle dédié à dbt
create role if not exists transformer;
grant usage on warehouse transforming_wh to role transformer;
grant all on database pricing_db to role transformer;
grant role transformer to role sysadmin;

-- 4. Utilisateur technique pour dbt, authentifié par paire de clés
--    Colle ici ta clé publique (contenu de snowflake_dbt_key.pub, sans les lignes BEGIN/END).
create user if not exists dbt_user
    type = service
    default_role = transformer
    default_warehouse = transforming_wh
    rsa_public_key = '<COLLE_TA_CLE_PUBLIQUE_ICI>';
grant role transformer to user dbt_user;

-- 5. Vérification
show grants to role transformer;
