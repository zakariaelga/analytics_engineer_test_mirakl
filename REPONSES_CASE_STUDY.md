# Analytics Engineer Case Study 2026 - Réponses Complètes

**Candidat Expert Analytics Engineer**  
Date: 20 Février 2026

---

## Part 1: Business Analysis

### Question 1: Définition du GMV (Gross Merchandise Value)

#### Ma Définition du GMV

**GMV = Somme des montants produits (product_amount) pour toutes les order lines avec un statut valide (non cancelled, non refused)**

#### Justification et Choix d'Inclusion/Exclusion

**✅ CE QUI EST INCLUS:**

1. **`product_amount`** - Le montant principal des produits vendus
   - **Pourquoi**: C'est la valeur réelle des marchandises échangées sur la marketplace
   - Représente la valeur brute avant commissions et frais

2. **`product_amount_tax`** - Les taxes sur les produits
   - **Pourquoi**: Selon la documentation, certains opérateurs incluent les taxes dans product_amount, d'autres les séparent
   - Pour une mesure cohérente du GMV, j'inclus les taxes car elles font partie de la valeur totale payée par le client
   - **GMV Total = product_amount + product_amount_tax**

3. **Statuts valides uniquement** - Exclusion des order_line_state = 'CANCELLED' ou 'REFUSED'
   - **Pourquoi**: Ces commandes n'ont jamais généré de valeur réelle pour la marketplace
   - Seules les commandes confirmées et traitées comptent dans le GMV

**❌ CE QUI EST EXCLU:**

1. **`shipping_amount` et `shipping_amount_tax`**
   - **Pourquoi**: Le GMV mesure la valeur des **marchandises**, pas des services logistiques
   - Les frais de livraison sont des frais accessoires, pas la valeur des biens vendus
   - Standard industrie: le GMV exclut généralement le shipping

2. **`operator_commission_amount`**
   - **Pourquoi**: C'est le revenu de la plateforme, pas la valeur des marchandises
   - Le GMV est une métrique "top-line" avant toute déduction

3. **`promotion_total_amount`**
   - **Pourquoi**: Les promotions sont déjà déduites du product_amount
   - Les inclure causerait une double comptabilisation

4. **Commandes annulées ou refusées**
   - **Pourquoi**: Aucune transaction réelle n'a eu lieu
   - Fausserait les métriques de performance

#### Formule SQL Finale

```sql
GMV = SUM(product_amount + COALESCE(product_amount_tax, 0))
WHERE order_line_state NOT IN ('CANCELLED', 'REFUSED')
  AND YEAR(order_created_datetime) = 2024
```

---

### Question 2: Top 5 Shops par Marketplace en 2024

#### Approche Analytique

J'utilise la table `fact_order_line` car elle contient:
- Le détail granulaire par ligne de commande
- Les montants produits exacts
- Les statuts de commande
- L'association shop_id / operator_id

#### SQL Query

```sql
WITH gmv_by_shop AS (
  SELECT 
    operator_id,
    shop_id,
    SUM(product_amount + COALESCE(product_amount_tax, 0)) AS total_gmv,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(order_line_id) AS total_order_lines,
    SUM(product_quantity) AS total_products_sold
  FROM fact_order_line
  WHERE 
    YEAR(order_created_datetime) = 2024
    AND order_line_state NOT IN ('CANCELLED', 'REFUSED')
  GROUP BY operator_id, shop_id
),
ranked_shops AS (
  SELECT 
    operator_id,
    shop_id,
    total_gmv,
    total_orders,
    total_order_lines,
    total_products_sold,
    ROW_NUMBER() OVER (PARTITION BY operator_id ORDER BY total_gmv DESC) AS rank
  FROM gmv_by_shop
)
SELECT 
  operator_id AS marketplace,
  shop_id,
  ROUND(total_gmv, 2) AS gmv_2024,
  total_orders,
  total_order_lines,
  total_products_sold,
  rank
FROM ranked_shops
WHERE rank <= 5
ORDER BY operator_id, rank;
```

#### Résultats Attendus (Structure)

| Marketplace | Shop ID | GMV 2024 | Total Orders | Order Lines | Products Sold | Rank |
|-------------|---------|----------|--------------|-------------|---------------|------|
| housedecor  | 1532    | €XXX,XXX | X,XXX        | X,XXX       | X,XXX         | 1    |
| housedecor  | 1391    | €XXX,XXX | X,XXX        | X,XXX       | X,XXX         | 2    |
| ...         | ...     | ...      | ...          | ...         | ...           | ...  |
| perfecthome | 1169    | €XXX,XXX | X,XXX        | X,XXX       | X,XXX         | 1    |
| perfecthome | 1166    | €XXX,XXX | X,XXX        | X,XXX       | X,XXX         | 2    |

#### Insights Clés

1. **Concentration du GMV**: Les top 5 shops représentent probablement 60-80% du GMV total
2. **Diversité des marketplaces**: Chaque opérateur a ses propres leaders
3. **Métriques complémentaires**: J'ai ajouté orders, order_lines et products_sold pour contextualiser le GMV

---

### Question 3: Shops Actifs par Mois en 2024 avec MoM Change

#### Définition de "Shop Actif"

**Un shop est considéré actif dans un mois si:**
- Il a au moins une order_line créée ce mois-là
- Avec un statut valide (non CANCELLED, non REFUSED)
- Peu importe le montant (même une petite commande compte)

#### SQL Query

```sql
WITH monthly_active_shops AS (
  SELECT 
    DATE_TRUNC('month', order_created_datetime) AS month,
    operator_id,
    shop_id,
    COUNT(DISTINCT order_id) AS orders_count
  FROM fact_order_line
  WHERE 
    YEAR(order_created_datetime) = 2024
    AND order_line_state NOT IN ('CANCELLED', 'REFUSED')
  GROUP BY 
    DATE_TRUNC('month', order_created_datetime),
    operator_id,
    shop_id
),
monthly_counts AS (
  SELECT 
    month,
    operator_id,
    COUNT(DISTINCT shop_id) AS active_shops
  FROM monthly_active_shops
  GROUP BY month, operator_id
),
with_previous AS (
  SELECT 
    month,
    operator_id,
    active_shops,
    LAG(active_shops) OVER (PARTITION BY operator_id ORDER BY month) AS previous_month_shops
  FROM monthly_counts
)
SELECT 
  TO_CHAR(month, 'YYYY-MM') AS month,
  operator_id AS marketplace,
  active_shops,
  previous_month_shops,
  active_shops - COALESCE(previous_month_shops, 0) AS absolute_change,
  CASE 
    WHEN previous_month_shops IS NULL THEN NULL
    WHEN previous_month_shops = 0 THEN NULL
    ELSE ROUND(((active_shops - previous_month_shops) * 100.0 / previous_month_shops), 2)
  END AS pct_change_mom
FROM with_previous
ORDER BY operator_id, month;
```

#### Résultats Attendus (Structure)

| Month   | Marketplace | Active Shops | Previous Month | Absolute Change | % Change MoM |
|---------|-------------|--------------|----------------|-----------------|--------------|
| 2024-01 | housedecor  | 450          | NULL           | NULL            | NULL         |
| 2024-02 | housedecor  | 478          | 450            | +28             | +6.22%       |
| 2024-03 | housedecor  | 465          | 478            | -13             | -2.72%       |
| ...     | ...         | ...          | ...            | ...             | ...          |

#### Analyse des Tendances

**Insights à rechercher:**
1. **Saisonnalité**: Pics en novembre-décembre (Black Friday, Noël)
2. **Croissance**: Tendance générale à la hausse ou baisse?
3. **Churn**: Mois avec forte baisse = problème de rétention shops
4. **Acquisition**: Mois avec forte hausse = campagnes d'onboarding réussies

---

### Question 4: 3 KPIs Additionnels pour le Dashboard Customer Success

#### KPI #1: **Shop Retention Rate (Taux de Rétention des Shops)**

**Définition:**
```
Retention Rate = (Shops actifs mois M ET mois M-1) / (Shops actifs mois M-1) × 100
```

**Calcul SQL:**
```sql
WITH monthly_shops AS (
  SELECT DISTINCT
    DATE_TRUNC('month', order_created_datetime) AS month,
    operator_id,
    shop_id
  FROM fact_order_line
  WHERE order_line_state NOT IN ('CANCELLED', 'REFUSED')
),
retention_calc AS (
  SELECT 
    current.month,
    current.operator_id,
    COUNT(DISTINCT current.shop_id) AS shops_current_month,
    COUNT(DISTINCT previous.shop_id) AS shops_retained,
    COUNT(DISTINCT previous.shop_id) * 100.0 / 
      NULLIF(COUNT(DISTINCT current.shop_id), 0) AS retention_rate
  FROM monthly_shops current
  LEFT JOIN monthly_shops previous
    ON current.shop_id = previous.shop_id
    AND current.operator_id = previous.operator_id
    AND previous.month = current.month - INTERVAL '1 month'
  GROUP BY current.month, current.operator_id
)
SELECT * FROM retention_calc;
```

**Valeur Business:**
- **Décision informée**: Identifier les périodes de churn élevé
- **Action**: Déclencher des campagnes de réengagement
- **Santé de la plateforme**: Un taux < 80% est un signal d'alerte
- **ROI**: Retenir un shop coûte 5x moins cher que d'en acquérir un nouveau

---

#### KPI #2: **Average Order Value (AOV) par Shop Segment**

**Définition:**
```
AOV = Total GMV / Nombre de commandes
Segmenté par: Top Performers (Top 20%), Mid-tier (20-80%), Long Tail (Bottom 20%)
```

**Calcul SQL:**
```sql
WITH shop_performance AS (
  SELECT 
    operator_id,
    shop_id,
    SUM(product_amount + COALESCE(product_amount_tax, 0)) AS total_gmv,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(product_amount + COALESCE(product_amount_tax, 0)) / 
      NULLIF(COUNT(DISTINCT order_id), 0) AS aov
  FROM fact_order_line
  WHERE 
    YEAR(order_created_datetime) = 2024
    AND order_line_state NOT IN ('CANCELLED', 'REFUSED')
  GROUP BY operator_id, shop_id
),
shop_segments AS (
  SELECT 
    *,
    NTILE(5) OVER (PARTITION BY operator_id ORDER BY total_gmv DESC) AS gmv_quintile,
    CASE 
      WHEN NTILE(5) OVER (PARTITION BY operator_id ORDER BY total_gmv DESC) = 1 
        THEN 'Top Performers'
      WHEN NTILE(5) OVER (PARTITION BY operator_id ORDER BY total_gmv DESC) IN (2,3,4) 
        THEN 'Mid-Tier'
      ELSE 'Long Tail'
    END AS segment
  FROM shop_performance
)
SELECT 
  operator_id,
  segment,
  COUNT(shop_id) AS shop_count,
  ROUND(AVG(aov), 2) AS avg_order_value,
  ROUND(SUM(total_gmv), 2) AS segment_gmv,
  ROUND(SUM(total_gmv) * 100.0 / SUM(SUM(total_gmv)) OVER (PARTITION BY operator_id), 2) AS pct_of_total_gmv
FROM shop_segments
GROUP BY operator_id, segment
ORDER BY operator_id, segment;
```

**Valeur Business:**
- **Décision informée**: Identifier les segments à fort potentiel
- **Action**: Stratégies différenciées par segment
  - Top Performers: Programme VIP, support premium
  - Mid-Tier: Upsell, formation
  - Long Tail: Automatisation, self-service
- **Priorisation**: Allouer les ressources CS efficacement

---

#### KPI #3: **Refund Rate & Impact on GMV**

**Définition:**
```
Refund Rate = (Nombre d'order_lines avec refund) / (Total order_lines) × 100
Refund Impact = (Montant total des refunds) / (GMV brut) × 100
```

**Calcul SQL:**
```sql
WITH refund_analysis AS (
  SELECT 
    operator_id,
    shop_id,
    DATE_TRUNC('month', order_created_datetime) AS month,
    
    -- Total metrics
    COUNT(order_line_id) AS total_order_lines,
    SUM(product_amount + COALESCE(product_amount_tax, 0)) AS gross_gmv,
    
    -- Refund metrics from fact_order_line
    COUNT(CASE WHEN order_line_state = 'REFUNDED' THEN 1 END) AS refunded_lines,
    
    -- Cancelled/Refused as proxy for issues
    COUNT(CASE WHEN order_line_state IN ('CANCELLED', 'REFUSED') THEN 1 END) AS problematic_lines,
    SUM(CASE WHEN order_line_state IN ('CANCELLED', 'REFUSED') 
      THEN product_amount + COALESCE(product_amount_tax, 0) 
      ELSE 0 END) AS lost_gmv
      
  FROM fact_order_line
  WHERE YEAR(order_created_datetime) = 2024
  GROUP BY operator_id, shop_id, DATE_TRUNC('month', order_created_datetime)
),
shop_refund_rates AS (
  SELECT 
    operator_id,
    shop_id,
    SUM(total_order_lines) AS total_lines,
    SUM(refunded_lines + problematic_lines) AS total_issues,
    SUM(gross_gmv) AS total_gmv,
    SUM(lost_gmv) AS total_lost_gmv,
    
    -- Refund Rate
    ROUND(SUM(refunded_lines + problematic_lines) * 100.0 / 
      NULLIF(SUM(total_order_lines), 0), 2) AS refund_rate_pct,
    
    -- GMV Impact
    ROUND(SUM(lost_gmv) * 100.0 / NULLIF(SUM(gross_gmv), 0), 2) AS gmv_impact_pct
    
  FROM refund_analysis
  GROUP BY operator_id, shop_id
)
SELECT 
  operator_id,
  shop_id,
  total_lines,
  total_issues,
  refund_rate_pct,
  ROUND(total_gmv, 2) AS total_gmv,
  ROUND(total_lost_gmv, 2) AS lost_gmv,
  gmv_impact_pct,
  CASE 
    WHEN refund_rate_pct > 15 THEN '🔴 High Risk'
    WHEN refund_rate_pct > 8 THEN '🟡 Medium Risk'
    ELSE '🟢 Healthy'
  END AS health_status
FROM shop_refund_rates
WHERE total_lines > 10  -- Minimum volume for statistical relevance
ORDER BY refund_rate_pct DESC
LIMIT 50;
```

**Valeur Business:**
- **Décision informée**: Identifier les shops problématiques
- **Action**: 
  - Refund Rate > 15%: Investigation immédiate, possibilité de suspension
  - Refund Rate 8-15%: Coaching, amélioration qualité
  - Refund Rate < 8%: Benchmark de bonnes pratiques
- **Impact financier**: Chaque % de refund = perte directe de GMV
- **Expérience client**: Refunds élevés = insatisfaction = churn clients

---

## Part 2: Data Modeling - STAR Schema pour Market+

### Vue d'Ensemble de l'Architecture

**Objectif**: Créer un modèle dimensionnel optimisé pour l'analyse des ventes, commissions, et performance de la marketplace.

**Approche**: Star Schema avec 1 fact table principale et 6 dimensions

---

### Fact Table: `fact_sales`

**Grain**: Une ligne par order_item (niveau le plus granulaire de transaction)

**Justification du Grain**:
- Permet l'analyse par produit individuel
- Supporte l'agrégation à tous les niveaux (order, customer, vendor, category)
- Capture les commissions au niveau item (commission_rate peut varier)

#### Colonnes de la Fact Table

**Clés étrangères (Foreign Keys):**
```sql
- order_item_id (PK, degenerate dimension)
- order_id (degenerate dimension)
- date_key (FK → dim_date)
- customer_key (FK → dim_customer)
- vendor_key (FK → dim_vendor)
- product_key (FK → dim_product)
- payment_key (FK → dim_payment)
- carrier_key (FK → dim_carrier)
```

**Mesures (Measures):**
```sql
- quantity (INT)
- unit_price (DECIMAL(10,2))
- line_total (DECIMAL(10,2))  -- quantity × unit_price
- commission_rate (DECIMAL(5,2))  -- en %
- commission_amount (DECIMAL(10,2))  -- line_total × commission_rate
- shipping_fee (DECIMAL(10,2))  -- prorata du shipping total
- tax_amount (DECIMAL(10,2))
- discount_amount (DECIMAL(10,2))
- net_revenue (DECIMAL(10,2))  -- line_total - discount_amount
```

**Flags (pour filtrage rapide):**
```sql
- is_paid (BOOLEAN)
- is_shipped (BOOLEAN)
- is_reviewed (BOOLEAN)
- order_status (VARCHAR)  -- 'pending', 'completed', 'cancelled'
```

---

### Dimension Tables

#### 1. `dim_date` (Dimension Temporelle)

**Justification**: Analyse temporelle cruciale pour les marketplaces (trends, saisonnalité)

```sql
CREATE TABLE dim_date (
  date_key INT PRIMARY KEY,  -- Format: YYYYMMDD
  full_date DATE,
  year INT,
  quarter INT,
  month INT,
  month_name VARCHAR(20),
  week INT,
  day_of_month INT,
  day_of_week INT,
  day_name VARCHAR(20),
  is_weekend BOOLEAN,
  is_holiday BOOLEAN,
  fiscal_year INT,
  fiscal_quarter INT
);
```

**Business Value**: Répond aux questions sur l'évolution des commissions dans le temps

---

#### 2. `dim_customer` (Dimension Client)

**Type**: Slowly Changing Dimension Type 2 (SCD2)

**Justification**: Historisation des changements (adresse, pays) pour analyse géographique correcte

```sql
CREATE TABLE dim_customer (
  customer_key INT PRIMARY KEY,  -- Surrogate key
  customer_id INT,  -- Business key
  name VARCHAR(255),
  email VARCHAR(255),
  country VARCHAR(100),
  region VARCHAR(100),  -- Dérivé du pays
  signup_date DATE,
  customer_segment VARCHAR(50),  -- 'VIP', 'Regular', 'New'
  
  -- SCD2 fields
  effective_date DATE,
  expiration_date DATE,
  is_current BOOLEAN
);
```

**Business Value**: Analyse par région/pays (question 2 du case study)

---

#### 3. `dim_vendor` (Dimension Vendeur)

**Type**: SCD2

```sql
CREATE TABLE dim_vendor (
  vendor_key INT PRIMARY KEY,
  vendor_id INT,
  name VARCHAR(255),
  country VARCHAR(100),
  region VARCHAR(100),
  signup_date DATE,
  status VARCHAR(50),  -- 'active', 'suspended', 'inactive'
  vendor_tier VARCHAR(50),  -- 'small', 'medium', 'large'
  
  -- SCD2 fields
  effective_date DATE,
  expiration_date DATE,
  is_current BOOLEAN
);
```

**Business Value**: Revenue par vendeur (question 1 du case study)

---

#### 4. `dim_product` (Dimension Produit)

**Type**: SCD2 (prix peut changer)

```sql
CREATE TABLE dim_product (
  product_key INT PRIMARY KEY,
  product_id INT,
  name VARCHAR(255),
  category_key INT,  -- FK to dim_category
  vendor_key INT,  -- FK to dim_vendor
  price DECIMAL(10,2),
  
  -- SCD2 fields
  effective_date DATE,
  expiration_date DATE,
  is_current BOOLEAN
);
```

**Relation avec dim_category**: Snowflake pour gérer la hiérarchie

---

#### 5. `dim_category` (Dimension Catégorie - Hiérarchique)

**Type**: Hiérarchie parent-child aplatie

```sql
CREATE TABLE dim_category (
  category_key INT PRIMARY KEY,
  category_id INT,
  category_name VARCHAR(255),
  
  -- Hiérarchie aplatie (jusqu'à 3 niveaux)
  level_1_category VARCHAR(255),  -- Ex: "Electronics"
  level_2_category VARCHAR(255),  -- Ex: "Computers"
  level_3_category VARCHAR(255),  -- Ex: "Laptops"
  
  category_level INT,  -- 1, 2, or 3
  parent_category_id INT
);
```

**Justification**: Hiérarchie aplatie pour performance des requêtes (éviter les récursions)

**Business Value**: Revenue par catégorie (question 1)

---

#### 6. `dim_payment` (Dimension Paiement)

**Type**: SCD1 (statut peut changer, on garde la dernière valeur)

```sql
CREATE TABLE dim_payment (
  payment_key INT PRIMARY KEY,
  payment_id INT,
  payment_method VARCHAR(100),  -- 'credit_card', 'paypal', 'bank_transfer'
  payment_date TIMESTAMP,
  status VARCHAR(50),  -- 'approved', 'rejected', 'pending'
  amount DECIMAL(10,2)
);
```

**Business Value**: Analyse des méthodes de paiement et taux d'approbation (question 4)

---

#### 7. `dim_carrier` (Dimension Transporteur)

**Type**: SCD1

```sql
CREATE TABLE dim_carrier (
  carrier_key INT PRIMARY KEY,
  carrier_id INT,
  name VARCHAR(255),
  service_area VARCHAR(255),
  avg_rating DECIMAL(3,2)
);
```

**Business Value**: Analyse de la qualité de livraison

---

### Gestion des Cas Complexes

#### Problème 1: Orders avec Multiple Carriers

**Challenge**: Une commande peut avoir plusieurs transporteurs (items de différents vendeurs)

**Solution**: 
- Dans `fact_sales`, chaque order_item a son propre carrier_key
- Un order_id peut apparaître plusieurs fois avec différents carriers
- Agrégation possible par carrier au niveau analyse

**Exemple**:
```
Order #123 avec 3 items:
- Item 1 (Vendor A) → Carrier DHL
- Item 2 (Vendor B) → Carrier FedEx  
- Item 3 (Vendor A) → Carrier DHL

→ 3 lignes dans fact_sales avec carrier_key différents
```

---

#### Problème 2: Commission au Niveau Order vs Item

**Challenge**: La colonne `commission` existe dans `orders` mais `commission_rate` dans `order_items`

**Solution**:
- Stocker `commission_amount` au niveau item dans fact_sales
- Calculer: `commission_amount = line_total × commission_rate`
- La commission totale de l'order = SUM(commission_amount) de tous ses items
- Permet une granularité fine (commission peut varier par produit/catégorie)

---

#### Problème 3: Hiérarchie de Catégories

**Challenge**: Structure parent-child récursive difficile à requêter

**Solution**: Hiérarchie aplatie dans dim_category
- Pré-calculer les 3 niveaux de hiérarchie
- Stocker level_1, level_2, level_3 dans des colonnes séparées
- Permet des GROUP BY simples sans récursion

**Exemple**:
```
Electronics > Computers > Laptops
→ level_1_category = 'Electronics'
→ level_2_category = 'Computers'  
→ level_3_category = 'Laptops'
```

---

### Réponses aux Questions Business

#### Question 1: Revenue par Catégorie et Vendeur par Mois

```sql
SELECT 
  d.year,
  d.month_name,
  c.level_1_category,
  v.name AS vendor_name,
  SUM(f.net_revenue) AS total_revenue,
  SUM(f.commission_amount) AS total_commission
FROM fact_sales f
JOIN dim_date d ON f.date_key = d.date_key
JOIN dim_product p ON f.product_key = p.product_key
JOIN dim_category c ON p.category_key = c.category_key
JOIN dim_vendor v ON f.vendor_key = v.vendor_key
WHERE d.year = 2024 AND d.month = 1
GROUP BY d.year, d.month_name, c.level_1_category, v.name
ORDER BY total_revenue DESC;
```

---

#### Question 2: Volume et Montant par Région/Pays

```sql
SELECT 
  c.region,
  c.country,
  COUNT(DISTINCT f.order_id) AS order_volume,
  SUM(f.line_total + f.shipping_fee + f.tax_amount) AS total_billed_amount
FROM fact_sales f
JOIN dim_customer c ON f.customer_key = c.customer_key
WHERE c.is_current = TRUE
GROUP BY c.region, c.country
ORDER BY total_billed_amount DESC;
```

---

#### Question 3: Évolution des Commissions

```sql
SELECT 
  d.year,
  d.month_name,
  SUM(f.commission_amount) AS total_commission,
  AVG(f.commission_rate) AS avg_commission_rate,
  COUNT(DISTINCT f.order_id) AS order_count
FROM fact_sales f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.year, d.month_name
ORDER BY d.year, d.month;
```

---

#### Question 4: Méthodes de Paiement et Taux d'Approbation

```sql
SELECT 
  p.payment_method,
  COUNT(*) AS total_transactions,
  SUM(CASE WHEN p.status = 'approved' THEN 1 ELSE 0 END) AS approved_count,
  SUM(CASE WHEN p.status = 'rejected' THEN 1 ELSE 0 END) AS rejected_count,
  ROUND(SUM(CASE WHEN p.status = 'approved' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS approval_rate,
  SUM(f.line_total) AS total_amount
FROM fact_sales f
JOIN dim_payment p ON f.payment_key = p.payment_key
GROUP BY p.payment_method
ORDER BY total_transactions DESC;
```

---

### Trade-offs et Décisions de Design

#### 1. Star vs Snowflake

**Décision**: Hybrid (majoritairement Star avec mini-snowflake pour catégories)

**Justification**:
- ✅ Star: Performance optimale pour la plupart des requêtes
- ✅ Snowflake pour catégories: Gérer la hiérarchie sans duplication
- ⚖️ Trade-off: Légère complexité vs normalisation des catégories

---

#### 2. Grain de la Fact Table

**Décision**: Order_item level (pas order level)

**Justification**:
- ✅ Maximum de flexibilité analytique
- ✅ Supporte tous les niveaux d'agrégation
- ✅ Commission au niveau item (business rule)
- ❌ Trade-off: Table plus volumineuse, mais acceptable avec partitioning

---

#### 3. SCD Type 2 vs Type 1

**Décision**: SCD2 pour Customer et Vendor, SCD1 pour Payment

**Justification**:
- ✅ SCD2: Historisation des changements géographiques (analyse région correcte)
- ✅ SCD1 pour Payment: Statut actuel suffit, historique dans fact table
- ⚖️ Trade-off: Complexité vs précision historique

---

#### 4. Degenerate Dimensions

**Décision**: order_id et order_item_id dans fact table (pas de dim_order)

**Justification**:
- ✅ Évite une dimension inutile (pas d'attributs descriptifs)
- ✅ Performance: moins de joins
- ✅ order_id utilisé pour agrégation, pas pour filtrage

---

### Défis de Modélisation et Solutions

#### Défi 1: Gestion des Reviews

**Problème**: Reviews arrivent après la vente, relation 1-to-many avec order_items

**Solution**: 
- Option A: Fact table séparée `fact_reviews` (recommandé)
- Option B: Flags dans fact_sales (is_reviewed) + dimension review
- **Choix**: Option A pour éviter la duplication et gérer le timing différent

```sql
CREATE TABLE fact_reviews (
  review_key INT PRIMARY KEY,
  review_id INT,
  order_item_key INT,  -- FK to fact_sales
  product_key INT,
  customer_key INT,
  date_key INT,
  rating INT,
  sentiment_score DECIMAL(3,2)  -- NLP analysis
);
```

---

#### Défi 2: Shipping Fees Allocation

**Problème**: Shipping fee au niveau order, mais fact table au niveau item

**Solution**: Prorata allocation
```sql
shipping_fee_per_item = (order_shipping_total × item_line_total) / order_total
```

**Alternative**: Attribuer 100% du shipping au premier item (plus simple mais moins précis)

---

#### Défi 3: Late-Arriving Facts

**Problème**: Paiements peuvent arriver après la création de l'order

**Solution**:
- Utiliser une date_key pour order_date (pas payment_date)
- Stocker payment_date dans dim_payment
- Permet l'analyse "commandes du mois X payées quand?"

---

### Optimisations Techniques

#### 1. Partitioning Strategy

```sql
-- Partition fact_sales par date (mensuel)
PARTITION BY RANGE (date_key) (
  PARTITION p_2024_01 VALUES LESS THAN (20240201),
  PARTITION p_2024_02 VALUES LESS THAN (20240301),
  ...
);
```

**Bénéfice**: Queries sur un mois = scan d'une seule partition

---

#### 2. Indexing Strategy

```sql
-- Fact table
CREATE INDEX idx_fact_date ON fact_sales(date_key);
CREATE INDEX idx_fact_customer ON fact_sales(customer_key);
CREATE INDEX idx_fact_vendor ON fact_sales(vendor_key);
CREATE INDEX idx_fact_product ON fact_sales(product_key);

-- Dimensions
CREATE INDEX idx_customer_country ON dim_customer(country);
CREATE INDEX idx_vendor_status ON dim_vendor(status);
CREATE INDEX idx_payment_method ON dim_payment(payment_method);
```

---

#### 3. Aggregate Tables (Cubes)

Pour les dashboards temps-réel, créer des tables agrégées:

```sql
CREATE TABLE agg_daily_sales AS
SELECT 
  date_key,
  vendor_key,
  category_key,
  SUM(net_revenue) AS daily_revenue,
  SUM(commission_amount) AS daily_commission,
  COUNT(DISTINCT order_id) AS order_count
FROM fact_sales
GROUP BY date_key, vendor_key, category_key;
```

**Bénéfice**: Dashboards 100x plus rapides

---

### Diagramme dbdiagram.io - Code SQL

Voici le code à copier dans dbdiagram.io:

```sql
// STAR SCHEMA - Market+ Marketplace Analytics
// Designed by: Expert Analytics Engineer
// Date: 2026-02-20

// ============================================
// FACT TABLE
// ============================================

Table fact_sales {
  order_item_id int [pk]
  order_id int [note: 'Degenerate dimension']
  
  // Foreign Keys to Dimensions
  date_key int [ref: > dim_date.date_key]
  customer_key int [ref: > dim_customer.customer_key]
  vendor_key int [ref: > dim_vendor.vendor_key]
  product_key int [ref: > dim_product.product_key]
  payment_key int [ref: > dim_payment.payment_key]
  carrier_key int [ref: > dim_carrier.carrier_key]
  
  // Measures
  quantity int
  unit_price decimal(10,2)
  line_total decimal(10,2) [note: 'quantity × unit_price']
  commission_rate decimal(5,2) [note: 'in %']
  commission_amount decimal(10,2) [note: 'line_total × commission_rate']
  shipping_fee decimal(10,2) [note: 'Prorata allocation']
  tax_amount decimal(10,2)
  discount_amount decimal(10,2)
  net_revenue decimal(10,2) [note: 'line_total - discount_amount']
  
  // Flags
  is_paid boolean
  is_shipped boolean
  is_reviewed boolean
  order_status varchar(50)
  
  Note: 'Grain: One row per order item. Core fact table for sales analytics.'
}

// ============================================
// DIMENSION TABLES
// ============================================

Table dim_date {
  date_key int [pk, note: 'Format: YYYYMMDD']
  full_date date
  year int
  quarter int
  month int
  month_name varchar(20)
  week int
  day_of_month int
  day_of_week int
  day_name varchar(20)
  is_weekend boolean
  is_holiday boolean
  fiscal_year int
  fiscal_quarter int
  
  Note: 'Time dimension for temporal analysis'
}

Table dim_customer {
  customer_key int [pk, note: 'Surrogate key']
  customer_id int [note: 'Business key']
  name varchar(255)
  email varchar(255)
  country varchar(100)
  region varchar(100) [note: 'Derived from country']
  signup_date date
  customer_segment varchar(50) [note: 'VIP, Regular, New']
  
  // SCD Type 2 fields
  effective_date date
  expiration_date date
  is_current boolean
  
  Note: 'SCD Type 2 for historical tracking of customer changes'
}

Table dim_vendor {
  vendor_key int [pk]
  vendor_id int [note: 'Business key']
  name varchar(255)
  country varchar(100)
  region varchar(100)
  signup_date date
  status varchar(50) [note: 'active, suspended, inactive']
  vendor_tier varchar(50) [note: 'small, medium, large']
  
  // SCD Type 2 fields
  effective_date date
  expiration_date date
  is_current boolean
  
  Note: 'SCD Type 2 for vendor attribute changes'
}

Table dim_product {
  product_key int [pk]
  product_id int [note: 'Business key']
  name varchar(255)
  category_key int [ref: > dim_category.category_key]
  vendor_key int [ref: > dim_vendor.vendor_key]
  price decimal(10,2)
  
  // SCD Type 2 fields
  effective_date date
  expiration_date date
  is_current boolean
  
  Note: 'SCD Type 2 for price changes. Snowflake to category dimension.'
}

Table dim_category {
  category_key int [pk]
  category_id int [note: 'Business key']
  category_name varchar(255)
  
  // Flattened hierarchy (up to 3 levels)
  level_1_category varchar(255) [note: 'Ex: Electronics']
  level_2_category varchar(255) [note: 'Ex: Computers']
  level_3_category varchar(255) [note: 'Ex: Laptops']
  
  category_level int [note: '1, 2, or 3']
  parent_category_id int
  
  Note: 'Flattened hierarchy for query performance. Avoids recursive queries.'
}

Table dim_payment {
  payment_key int [pk]
  payment_id int [note: 'Business key']
  payment_method varchar(100) [note: 'credit_card, paypal, bank_transfer']
  payment_date timestamp
  status varchar(50) [note: 'approved, rejected, pending']
  amount decimal(10,2)
  
  Note: 'SCD Type 1 - keeps latest status'
}

Table dim_carrier {
  carrier_key int [pk]
  carrier_id int [note: 'Business key']
  name varchar(255)
  service_area varchar(255)
  avg_rating decimal(3,2)
  
  Note: 'SCD Type 1 for carrier information'
}

// ============================================
// OPTIONAL: SEPARATE FACT TABLE FOR REVIEWS
// ============================================

Table fact_reviews {
  review_key int [pk]
  review_id int
  order_item_key int [note: 'Links to fact_sales']
  product_key int [ref: > dim_product.product_key]
  customer_key int [ref: > dim_customer.customer_key]
  date_key int [ref: > dim_date.date_key]
  rating int [note: '1-5 stars']
  sentiment_score decimal(3,2) [note: 'NLP analysis of comment']
  
  Note: 'Separate fact table for reviews (late-arriving facts)'
}
```

---

## Résumé Exécutif

### Part 1: Résultats Clés

1. **GMV Défini**: product_amount + product_amount_tax, excluant shipping et commissions
2. **Top 5 Shops**: Query SQL fournie avec métriques complémentaires
3. **Shops Actifs**: Analyse MoM avec absolute et percentage change
4. **3 KPIs Recommandés**:
   - Shop Retention Rate (santé de la plateforme)
   - AOV par Segment (priorisation CS)
   - Refund Rate & Impact (qualité et risque)

### Part 2: Architecture du Modèle

1. **Star Schema** avec 1 fact table principale (fact_sales)
2. **7 Dimensions**: date, customer, vendor, product, category, payment, carrier
3. **Grain**: Order_item level pour maximum de flexibilité
4. **SCD Type 2** pour customer et vendor (historisation)
5. **Hiérarchie aplatie** pour catégories (performance)
6. **Gestion des cas complexes**: Multiple carriers, commission allocation, late-arriving facts

### Assumptions Principales

1. **Données 2024**: Toutes les analyses se basent sur l'année 2024
2. **Statuts valides**: CANCELLED et REFUSED exclus du GMV
3. **Shop actif**: Au moins 1 commande valide dans le mois
4. **Currency**: Pas de conversion, analyse par currency_code
5. **Partitioning**: Mensuel sur date_key pour optimisation

---

**Temps estimé de complétion**: 1h15  
**Outils utilisés**: SQL (PostgreSQL syntax), AI assistance (Claude), dbdiagram.io  
**Approche**: Data-driven, business-focused, scalable architecture

