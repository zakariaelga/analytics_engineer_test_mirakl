# 📊 Analytics Engineer Case Study 2026 - Réponses Complètes

**Date**: 20 Février 2026  
**Temps de complétion**: ~1h15  
**Outils utilisés**: SQL (PostgreSQL), AI (Claude), dbdiagram.io

---

## 📁 Structure des Fichiers

```
mirakl/
├── README.md                          # Ce fichier - Guide d'utilisation
├── REPONSES_CASE_STUDY.md            # Document principal avec toutes les réponses
├── queries_part1.sql                 # Requêtes SQL pour la Partie 1
├── star_schema_dbdiagram.sql         # Code pour générer le diagramme (Partie 2)
├── datasets/
│   ├── fact_order_line.csv           # Dataset fourni
│   └── fact_shop.csv                 # Dataset fourni
├── table_documentation.txt           # Documentation fournie
└── Analytics Engineer Case Study 2026.pdf  # Énoncé original
└── star_schema.pdf  # star schema

```

---

## 🎯 Aperçu des Réponses

### Part 1: Business Analysis (30-45 min)

#### ✅ Question 1: Définition du GMV
- **GMV = product_amount + product_amount_tax**
- Exclusions: shipping, commissions, cancelled/refused orders
- Justification détaillée dans `REPONSES_CASE_STUDY.md`

#### ✅ Question 2: Top 5 Shops par Marketplace
- Query SQL complète dans `queries_part1.sql`
- Métriques: GMV, orders, customers, AOV, commission
- Ranking par marketplace avec ROW_NUMBER()

#### ✅ Question 3: Shops Actifs par Mois + MoM Change
- Query SQL avec LAG() pour calcul MoM
- Métriques: absolute change, % change, GMV trends
- Analyse de saisonnalité et croissance

#### ✅ Question 4: 3 KPIs Additionnels
1. **Shop Retention Rate** - Santé de la plateforme
2. **AOV par Segment** - Priorisation Customer Success
3. **Refund Rate & Impact** - Qualité et risque

---

### Part 2: Data Modeling (20-30 min)

#### ✅ Star Schema Design
- **1 Fact Table**: `fact_sales` (grain: order_item level)
- **7 Dimensions**: date, customer, vendor, product, category, payment, carrier
- **Hybrid approach**: Star + mini-snowflake pour catégories
- **SCD Type 2**: customer, vendor, product (historisation)

#### ✅ Business Questions Supportées
1. ✅ Revenue par catégorie et vendeur par mois
2. ✅ Volume et montant par région/pays
3. ✅ Évolution des commissions
4. ✅ Méthodes de paiement et taux d'approbation

#### ✅ Challenges Résolus
- Multiple carriers per order
- Commission allocation au niveau item
- Hiérarchie de catégories (flattened)
- Late-arriving facts (reviews)

---

## 🚀 Comment Utiliser les Fichiers

### 1. Lire le Document Principal

```bash
# Ouvrir le document de réponses complet
open REPONSES_CASE_STUDY.md
```

Ce fichier contient:
- Toutes les réponses détaillées
- Justifications et raisonnements
- Exemples de résultats
- Trade-offs et décisions de design

---

### 2. Exécuter les Requêtes SQL (Part 1)

#### Option A: PostgreSQL

```bash
# Se connecter à votre base PostgreSQL
psql -h localhost -U your_user -d your_database

# Charger les données (si nécessaire)
\copy fact_order_line FROM 'datasets/fact_order_line.csv' CSV HEADER;
\copy fact_shop FROM 'datasets/fact_shop.csv' CSV HEADER;

# Exécuter les queries
\i queries_part1.sql
```

#### Option B: DuckDB (Recommandé pour fichiers CSV volumineux)

```bash
# Installer DuckDB si nécessaire
brew install duckdb  # macOS
# ou télécharger depuis https://duckdb.org

# Lancer DuckDB
duckdb mirakl_analysis.db

# Dans DuckDB, charger les CSV
CREATE TABLE fact_order_line AS 
SELECT * FROM read_csv_auto('datasets/fact_order_line.csv');

CREATE TABLE fact_shop AS 
SELECT * FROM read_csv_auto('datasets/fact_shop.csv');

# Exécuter les queries
.read queries_part1.sql

# Exporter les résultats
COPY (
  -- Coller une query ici
) TO 'results_question2.csv' (HEADER, DELIMITER ',');
```

#### Option C: Python + Pandas (Pour analyse exploratoire)

```python
import pandas as pd
import duckdb

# Charger les données
df_order_line = pd.read_csv('datasets/fact_order_line.csv')
df_shop = pd.read_csv('datasets/fact_shop.csv')

# Utiliser DuckDB pour requêter
con = duckdb.connect()
con.register('fact_order_line', df_order_line)
con.register('fact_shop', df_shop)

# Exécuter une query
result = con.execute("""
    SELECT 
        operator_id,
        SUM(product_amount + COALESCE(product_amount_tax, 0)) AS gmv
    FROM fact_order_line
    WHERE EXTRACT(YEAR FROM order_created_datetime) = 2024
      AND order_line_state NOT IN ('CANCELLED', 'REFUSED')
    GROUP BY operator_id
""").df()

print(result)
```

---

### 3. Générer le Diagramme Star Schema (Part 2)

#### Étapes:

1. **Aller sur dbdiagram.io**
   ```
   https://dbdiagram.io/
   ```

2. **Copier le contenu de `star_schema_dbdiagram.sql`**
   ```bash
   # Sur macOS
   cat star_schema_dbdiagram.sql | pbcopy
   
   # Sur Linux
   cat star_schema_dbdiagram.sql | xclip -selection clipboard
   
   # Ou simplement ouvrir le fichier et copier manuellement
   ```

3. **Coller dans l'éditeur dbdiagram.io**
   - Le diagramme se génère automatiquement
   - Toutes les relations (FK) sont affichées
   - Les notes apparaissent au survol

4. **Exporter le diagramme**
   - Format PNG: Clic droit > Export to PNG
   - Format PDF: Clic droit > Export to PDF
   - Format SQL: Export > PostgreSQL / MySQL / SQL Server

#### Aperçu du Diagramme:

```
                    ┌─────────────┐
                    │  dim_date   │
                    └──────┬──────┘
                           │
         ┌─────────────────┼─────────────────┐
         │                 │                 │
    ┌────▼────┐       ┌────▼────┐      ┌────▼────┐
    │dim_cust │       │fact_    │      │dim_vend │
    │omer     │◄──────┤sales    │─────►│or       │
    └─────────┘       └────┬────┘      └─────────┘
                           │
         ┌─────────────────┼─────────────────┐
         │                 │                 │
    ┌────▼────┐       ┌────▼────┐      ┌────▼────┐
    │dim_prod │       │dim_pay  │      │dim_carr │
    │uct      │       │ment     │      │ier      │
    └────┬────┘       └─────────┘      └─────────┘
         │
    ┌────▼────┐
    │dim_cate │
    │gory     │
    └─────────┘
```

---

## 📊 Résultats Attendus

### Question 2: Top 5 Shops

**Exemple de sortie:**

| Marketplace | Shop ID | GMV 2024   | Orders | Customers | AOV     | Rank |
|-------------|---------|------------|--------|-----------|---------|------|
| housedecor  | 1532    | €458,234   | 2,145  | 1,876     | €213.65 | 1    |
| housedecor  | 1391    | €423,891   | 1,987  | 1,654     | €213.34 | 2    |
| housedecor  | 1155    | €387,654   | 1,765  | 1,432     | €219.63 | 3    |
| ...         | ...     | ...        | ...    | ...       | ...     | ...  |

### Question 3: Active Shops MoM

**Exemple de sortie:**

| Month   | Marketplace | Active Shops | Previous | Change | % Change |
|---------|-------------|--------------|----------|--------|----------|
| 2024-01 | housedecor  | 450          | NULL     | NULL   | NULL     |
| 2024-02 | housedecor  | 478          | 450      | +28    | +6.22%   |
| 2024-03 | housedecor  | 465          | 478      | -13    | -2.72%   |
| ...     | ...         | ...          | ...      | ...    | ...      |

### Question 4: KPI Examples

**Shop Retention Rate:**
| Month   | Marketplace | Retention % | New Shops | Churned | Status      |
|---------|-------------|-------------|-----------|---------|-------------|
| 2024-02 | housedecor  | 87.5%       | 45        | 17      | 🟢 Excellent |
| 2024-03 | housedecor  | 82.3%       | 32        | 45      | 🟡 Good      |

**Refund Rate:**
| Shop ID | Refund Rate | Lost GMV  | Status        | Action              |
|---------|-------------|-----------|---------------|---------------------|
| 1234    | 18.5%       | €12,345   | 🔴 High Risk  | Investigate urgently |
| 5678    | 11.2%       | €5,678    | 🟡 Medium     | Monitor closely     |

---

## 🔍 Insights Clés & Recommandations

### Business Analysis (Part 1)

#### 📈 GMV Trends
- **Saisonnalité**: Pics attendus en Q4 (Black Friday, Noël)
- **Concentration**: Top 20% des shops = ~70-80% du GMV
- **Opportunité**: Focus sur mid-tier shops pour croissance

#### 🏪 Shop Performance
- **Retention**: Taux < 80% = signal d'alerte
- **AOV**: Varier stratégies CS par segment
- **Qualité**: Refund rate > 15% = intervention immédiate

#### 💡 Actions Recommandées
1. **Programme VIP** pour Top Performers
2. **Coaching & Formation** pour Mid-Tier
3. **Automatisation** pour Long Tail
4. **Campagnes de réengagement** pour churned shops

---

### Data Modeling (Part 2)

#### 🎯 Design Choices

**✅ Strengths:**
- Flexible grain (order_item level)
- Historical accuracy (SCD Type 2)
- Fast queries (flattened hierarchy)
- Scalable (partitioning strategy)

**⚠️ Trade-offs:**
- Larger fact table (mitigated by partitioning)
- More complex ETL (SCD2) (worth it for accuracy)
- Some denormalization (acceptable for performance)

#### 🚀 Performance Optimizations

1. **Partitioning**: Monthly on date_key
2. **Indexing**: On all FK columns
3. **Aggregate tables**: For dashboards
4. **Materialized views**: For top products/vendors

---

## 🛠️ Technologies & Best Practices

### SQL Best Practices Utilisées

1. **CTEs (Common Table Expressions)**
   - Lisibilité et réutilisabilité
   - Facilite le debugging

2. **Window Functions**
   - ROW_NUMBER() pour ranking
   - LAG() pour MoM calculations
   - NTILE() pour segmentation

3. **Null Handling**
   - COALESCE pour valeurs par défaut
   - NULLIF pour éviter division par zéro

4. **Type Casting**
   - Explicit casting pour dates et decimals
   - Évite les erreurs de type

5. **Commenting**
   - Chaque section bien documentée
   - Business logic expliquée

---

### Data Modeling Best Practices

1. **Surrogate Keys**
   - Auto-increment pour toutes les dimensions
   - Indépendant des business keys

2. **SCD Type 2**
   - effective_date / expiration_date
   - is_current flag pour filtrage rapide

3. **Degenerate Dimensions**
   - order_id dans fact table (pas de dim_order)
   - Évite les dimensions inutiles

4. **Naming Conventions**
   - fact_* pour fact tables
   - dim_* pour dimensions
   - *_key pour surrogate keys
   - *_id pour business keys

---

## 📚 Ressources Complémentaires

### Documentation Technique

- **PostgreSQL Window Functions**: https://www.postgresql.org/docs/current/functions-window.html
- **DuckDB SQL Reference**: https://duckdb.org/docs/sql/introduction
- **dbdiagram.io Syntax**: https://dbdiagram.io/docs

### Data Modeling

- **Kimball's Star Schema**: "The Data Warehouse Toolkit" by Ralph Kimball
- **SCD Types**: https://en.wikipedia.org/wiki/Slowly_changing_dimension
- **Dimensional Modeling**: https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/

### Analytics Engineering

- **dbt Best Practices**: https://docs.getdbt.com/guides/best-practices
- **Modern Data Stack**: https://www.getdbt.com/analytics-engineering/

---

## ❓ FAQ

### Q: Pourquoi exclure le shipping du GMV?
**R**: Le GMV mesure la valeur des **marchandises** vendues, pas les services logistiques. C'est le standard industrie pour les marketplaces (Amazon, eBay, Etsy).

### Q: Pourquoi SCD Type 2 pour Customer?
**R**: Pour l'analyse géographique correcte. Si un customer déménage de France en Allemagne, on veut attribuer les anciennes commandes à la France et les nouvelles à l'Allemagne.

### Q: Pourquoi grain au niveau order_item et pas order?
**R**: Maximum de flexibilité. On peut toujours agréger au niveau order, mais l'inverse est impossible. Les commissions peuvent varier par item.

### Q: Comment gérer les multiple carriers?
**R**: Chaque order_item a son propre carrier_key. Un order avec 3 items de 2 vendors différents aura potentiellement 2 carriers différents.

### Q: Quelle est la taille estimée de fact_sales?
**R**: Si 10M orders/an avec 2.5 items/order en moyenne = 25M rows/an. Avec partitioning mensuel, chaque partition = ~2M rows (très gérable).

---

**Merci pour votre temps et considération !** 🚀

---

*Document généré le 20 Février 2026*  
*Temps total: ~1h15*  
*Outils: Cursor (Claude Sonnet 4.5), SQL, dbdiagram.io*
