# Pricing Analytics – Snowflake · dbt · Power BI

Projet personnel de data engineering et d'analytics : construire, avec la « modern data stack »,
un pipeline qui transforme les données de ventes d'un distributeur fictif en indicateurs de
**pricing et de marge**, testés et prêts pour Power BI.

> Les données sont **entièrement fictives** (distributeur imaginaire « NordElec »), générées pour l'exercice.

## Ce que fait le projet

```
CSV bruts ──(dbt seed)──▶ Snowflake RAW ──(dbt run)──▶ STAGING ──▶ INTERMEDIATE ──▶ MARTS ──▶ Power BI
```

| Couche | Modèles | Rôle |
|---|---|---|
| Raw (seeds) | `raw_products`, `raw_price_history`, `raw_customers`, `raw_sales` | Données brutes chargées depuis les CSV |
| Staging | `stg_*` | Nettoyage, typage ; calcul de la période de validité de chaque prix (`lead()`) |
| Intermediate | `int_sales_priced` | Rattache chaque vente au **prix catalogue en vigueur à sa date** (jointure sur une plage de dates), calcule CA, coût, marge et remise |
| Marts | `dim_products`, `dim_customers`, `fct_sales`, `mart_margin_monthly` | Modèle en étoile et table d'indicateurs mensuels pour Power BI |

**Qualité des données :** 23 tests dbt (unicité, valeurs non nulles, relations entre tables,
valeurs autorisées), dont un test métier : aucune remise négative ou supérieure à 30 %.

**Volume :** 40 produits, 94 prix, 60 clients, 3 000 ventes (janvier 2025 – octobre 2026).

---

## Guide pas à pas

### Étape 1 – Créer un compte Snowflake (gratuit 30 jours)

1. Va sur https://signup.snowflake.com et crée un compte d'essai.
2. Choisis l'édition **Standard**, le cloud **AWS** (ou Azure) et une région **Europe** (ex. Paris ou Frankfurt).
   Ces choix ne sont pas modifiables ensuite.
3. Active ton compte avec l'e-mail reçu et connecte-toi à **Snowsight**, l'interface web.

> 💡 Pour ne pas consommer tes crédits inutilement : utilise toujours un entrepôt **X-Small**
> avec arrêt automatique (`auto_suspend = 60`). Ne laisse jamais un entrepôt tourner un week-end.

### Étape 2 – Mettre le projet sur GitHub

1. Crée un compte sur https://github.com si tu n'en as pas.
2. Crée un nouveau dépôt public nommé `snowflake-dbt-pricing`.
3. Dépose tous les fichiers de ce dossier dans le dépôt (bouton « Add file › Upload files »,
   ou en ligne de commande avec `git`).

### Étape 3 – Connecter dbt à Snowflake

**Option A – dbt Cloud (recommandée, tout se fait dans le navigateur)**

1. Dans Snowsight, ouvre **Partner Connect** (menu Admin ou Data Products selon la version),
   cherche **dbt** et clique sur **Connect**. Snowflake crée automatiquement la base, l'entrepôt,
   le rôle et l'utilisateur pour dbt, puis ouvre la création de ton compte dbt Cloud (plan Developer gratuit).
2. Dans dbt Cloud, ouvre les paramètres du projet et connecte ton dépôt GitHub `snowflake-dbt-pricing`.
3. Ouvre l'**IDE** de dbt Cloud et passe à l'étape 4.

**Option B – dbt Core en local (en ligne de commande)**

1. Installe Python, puis : `pip install dbt-core dbt-snowflake`
2. Génère une paire de clés pour l'authentification :
   ```bash
   openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out ~/.ssh/snowflake_dbt_key.p8 -nocrypt
   openssl rsa -in ~/.ssh/snowflake_dbt_key.p8 -pubout -out ~/.ssh/snowflake_dbt_key.pub
   ```
3. Dans Snowsight, exécute `snowflake/01_setup_dbt_core.sql` en y collant ta clé publique.
4. Copie `profiles.example.yml` dans `~/.dbt/profiles.yml` et remplace `<identifiant_compte>`.
5. Vérifie la connexion : `dbt debug`

### Étape 4 – Lancer le pipeline

Dans l'IDE dbt Cloud (barre de commande en bas) ou dans ton terminal :

```bash
dbt seed     # charge les 4 fichiers CSV dans Snowflake
dbt build    # crée tous les modèles et lance les 23 tests
```

Tu dois obtenir `PASS=36 ... ERROR=0`. Dans Snowsight, tu verras apparaître les schémas
`..._RAW`, `..._STAGING`, `..._INTERMEDIATE` et `..._MARTS`.

Bonus : `dbt docs generate` produit une documentation avec le graphe de dépendances (lineage) des modèles.
Fais-en une capture d'écran pour ton README.

### Étape 5 – Construire le tableau de bord Power BI

1. Power BI Desktop › **Obtenir les données** › **Snowflake**.
2. Serveur : `<identifiant_compte>.snowflakecomputing.com`, entrepôt : celui créé à l'étape 3.
3. Importe les tables du schéma `..._MARTS` : `MART_MARGIN_MONTHLY`, `FCT_SALES`, `DIM_PRODUCTS`, `DIM_CUSTOMERS`.
4. Relie `FCT_SALES` à `DIM_PRODUCTS` (product_id) et à `DIM_CUSTOMERS` (customer_id).
5. Idées de visuels :
   - courbe du **CA et du taux de marge** par mois ;
   - barres du **taux de marge par catégorie** ;
   - **remise moyenne par segment de clients** ;
   - nuage de points **remise vs marge** par produit, pour repérer les produits trop remisés.
6. Exporte une capture du rapport dans le dépôt (`docs/dashboard.png`) et ajoute-la au README.

### Étape 6 – Couper les coûts

Quand tu as fini : dans Snowsight, `alter warehouse <nom> suspend;`.
L'essai s'arrête au bout de 30 jours ou quand les crédits sont épuisés.

---

## Pistes pour aller plus loin

- Transformer `fct_sales` en modèle **incrémental** (`materialized='incremental'`).
- Ajouter un **snapshot** dbt pour historiser les changements de coûts produits.
- Ajouter un test sur la marge minimale par catégorie.
- Planifier un job quotidien dans dbt Cloud.
