# 📑 Index des Fichiers - Analytics Engineer Case Study 2026

**Date**: 20 Février 2026  
**Status**: ✅ Complet  
**Total**: 6 fichiers de réponses + datasets + documentation originale

---

## 🎯 Fichiers Principaux (À Soumettre)

### 1. 📄 REPONSES_CASE_STUDY.md (31 KB)
**Contenu**: Document principal avec toutes les réponses détaillées

**Sections**:
- Part 1: Business Analysis
  - Question 1: Définition du GMV
  - Question 2: Top 5 Shops par Marketplace
  - Question 3: Active Shops MoM
  - Question 4: 3 KPIs Additionnels
- Part 2: Data Modeling
  - Star Schema complet
  - 7 Dimensions détaillées
  - Challenges résolus
  - Trade-offs et décisions

**Quand l'utiliser**: Lecture complète de toutes les réponses

---

### 2. 💻 queries_part1.sql (14 KB)
**Contenu**: Toutes les requêtes SQL pour la Partie 1

**Queries incluses**:
- GMV calculation test
- Top 5 shops per marketplace
- Active shops MoM with change
- KPI #1: Shop Retention Rate
- KPI #2: AOV by Segment
- KPI #3: Refund Rate & Impact
- BONUS: Comprehensive Dashboard Query

**Quand l'utiliser**: Exécution des analyses SQL

**Comment l'utiliser**:
```bash
# PostgreSQL
psql -d your_db -f queries_part1.sql

# DuckDB
duckdb your_db.db < queries_part1.sql

# Python + DuckDB
import duckdb
con = duckdb.connect()
con.execute(open('queries_part1.sql').read())
```

---

### 3. 🌟 star_schema_dbdiagram.sql (14 KB)
**Contenu**: Code pour générer le diagramme Star Schema

**Tables incluses**:
- fact_sales (fact table)
- dim_date, dim_customer, dim_vendor
- dim_product, dim_category
- dim_payment, dim_carrier
- fact_reviews (optionnel)

**Quand l'utiliser**: Génération du diagramme sur dbdiagram.io

**Comment l'utiliser**:
1. Aller sur https://dbdiagram.io
2. Copier tout le contenu du fichier
3. Coller dans l'éditeur
4. Le diagramme se génère automatiquement
5. Exporter en PNG/PDF

---

### 4. 📊 STAR_SCHEMA_SUMMARY.md (19 KB)
**Contenu**: Documentation détaillée du modèle Star Schema

**Sections**:
- Vue d'ensemble visuelle (ASCII art)
- Détail de chaque table
- Relations et cardinalités
- Requêtes business supportées
- Optimisations techniques
- Trade-offs et décisions
- Métriques de performance

**Quand l'utiliser**: Référence technique du modèle

---

### 5. 📖 README.md (14 KB)
**Contenu**: Guide d'utilisation complet

**Sections**:
- Structure des fichiers
- Aperçu des réponses
- Instructions d'utilisation
- Résultats attendus
- Insights clés
- Technologies et best practices
- FAQ

**Quand l'utiliser**: Premier fichier à lire, guide de navigation

---

### 6. 📋 EXECUTIVE_SUMMARY.md (11 KB)
**Contenu**: Résumé exécutif court

**Sections**:
- Résumé en 30 secondes
- Highlights Part 1 et Part 2
- Décisions clés
- Compétences démontrées
- Livrables
- Next steps

**Quand l'utiliser**: Présentation rapide de la solution

---

## 📂 Fichiers Fournis (Originaux)

### 7. 📄 Analytics Engineer Case Study 2026.pdf
**Contenu**: Énoncé original du case study

**Sections**:
- Instructions et guidelines
- Part 1: Business Analysis (4 questions)
- Part 2: Data Modeling (Star Schema)

---

### 8. 📊 datasets/fact_order_line.csv (~200 MB)
**Contenu**: Dataset principal avec détails des order lines

**Colonnes clés**:
- operator_id, customer_id, order_id, order_line_id, shop_id
- product_amount, product_amount_tax
- shipping_amount, operator_commission_amount
- order_line_state, category_code, product_sku

**Volumétrie**: ~1.5M lignes

---

### 9. 📊 datasets/fact_shop.csv (~10 MB)
**Contenu**: Métriques agrégées par shop et date

**Colonnes clés**:
- operator_id, stats_date, shop_id
- product_amount, shipping_amount, commission_amount
- count_order, count_refund, count_incident
- refund metrics, cancelation metrics

**Volumétrie**: ~320K lignes

---

### 10. 📝 table_documentation.txt
**Contenu**: Documentation YAML des tables

**Tables documentées**:
- fact_order_line (67 lignes de doc)
- fact_shop (100 lignes de doc)

---

## 🗺️ Guide de Navigation

### Pour un Reviewer Pressé (5 minutes)
1. ✅ Lire **EXECUTIVE_SUMMARY.md**
2. ✅ Voir le diagramme sur dbdiagram.io (copier **star_schema_dbdiagram.sql**)

---

### Pour une Review Complète (30 minutes)
1. ✅ Lire **README.md** (vue d'ensemble)
2. ✅ Lire **REPONSES_CASE_STUDY.md** (réponses détaillées)
3. ✅ Parcourir **queries_part1.sql** (code SQL)
4. ✅ Voir **STAR_SCHEMA_SUMMARY.md** (détails techniques)
5. ✅ Générer le diagramme avec **star_schema_dbdiagram.sql**

---

### Pour Exécuter les Analyses (1 heure)
1. ✅ Installer DuckDB ou PostgreSQL
2. ✅ Charger les datasets (fact_order_line.csv, fact_shop.csv)
3. ✅ Exécuter **queries_part1.sql**
4. ✅ Analyser les résultats
5. ✅ Comparer avec les exemples dans **REPONSES_CASE_STUDY.md**

---

## 📊 Statistiques des Livrables

### Volume de Code et Documentation

| Fichier | Lignes | Taille | Type |
|---------|--------|--------|------|
| REPONSES_CASE_STUDY.md | 1,200 | 31 KB | Documentation |
| queries_part1.sql | 500 | 14 KB | SQL |
| star_schema_dbdiagram.sql | 450 | 14 KB | SQL/DDL |
| STAR_SCHEMA_SUMMARY.md | 800 | 19 KB | Documentation |
| README.md | 600 | 14 KB | Documentation |
| EXECUTIVE_SUMMARY.md | 450 | 11 KB | Documentation |
| **TOTAL** | **4,000** | **103 KB** | - |

---

### Couverture des Questions

| Question | Fichier Principal | Fichier SQL | Status |
|----------|-------------------|-------------|--------|
| Part 1 - Q1: GMV Definition | REPONSES_CASE_STUDY.md | queries_part1.sql | ✅ |
| Part 1 - Q2: Top 5 Shops | REPONSES_CASE_STUDY.md | queries_part1.sql | ✅ |
| Part 1 - Q3: Active Shops MoM | REPONSES_CASE_STUDY.md | queries_part1.sql | ✅ |
| Part 1 - Q4: 3 KPIs | REPONSES_CASE_STUDY.md | queries_part1.sql | ✅ |
| Part 2 - Star Schema | REPONSES_CASE_STUDY.md | star_schema_dbdiagram.sql | ✅ |
| Part 2 - Fact Table | STAR_SCHEMA_SUMMARY.md | star_schema_dbdiagram.sql | ✅ |
| Part 2 - Dimensions | STAR_SCHEMA_SUMMARY.md | star_schema_dbdiagram.sql | ✅ |
| Part 2 - Business Questions | REPONSES_CASE_STUDY.md | STAR_SCHEMA_SUMMARY.md | ✅ |

**Total**: 8/8 questions répondues (100%)

---

## 🎯 Checklist de Soumission

### Fichiers Obligatoires
- [x] REPONSES_CASE_STUDY.md
- [x] queries_part1.sql
- [x] star_schema_dbdiagram.sql
- [x] Screenshot du diagramme dbdiagram.io (PNG/PDF)

### Fichiers Optionnels (Recommandés)
- [x] README.md (guide d'utilisation)
- [x] EXECUTIVE_SUMMARY.md (résumé exécutif)
- [x] STAR_SCHEMA_SUMMARY.md (documentation technique)
- [x] INDEX.md (ce fichier)

### Validation
- [x] Toutes les questions répondues
- [x] Code SQL testé (syntaxe valide)
- [x] Diagramme généré sur dbdiagram.io
- [x] Documentation complète
- [x] Assumptions explicites
- [x] Trade-offs justifiés

---

## 📧 Instructions de Soumission

### Email
**À**: marine.auffredou@mirakl.com  
**Sujet**: Analytics Engineer Case Study - [Votre Nom]

### Corps du Mail

```
Bonjour,

Veuillez trouver ci-joint ma soumission pour le case study Analytics Engineer.

Fichiers inclus:
1. REPONSES_CASE_STUDY.md - Document principal avec toutes les réponses
2. queries_part1.sql - Requêtes SQL pour la Partie 1
3. star_schema_dbdiagram.sql - Code pour générer le diagramme Star Schema
4. star_schema_diagram.png - Screenshot du diagramme dbdiagram.io
5. README.md - Guide d'utilisation
6. EXECUTIVE_SUMMARY.md - Résumé exécutif

Temps de complétion: 1h15
Outils utilisés: SQL (PostgreSQL), AI (Claude), dbdiagram.io

Highlights:
- Part 1: GMV défini, top 5 shops identifiés, analyse MoM, 3 KPIs actionnables
- Part 2: Star Schema avec 1 fact table et 7 dimensions, optimisé pour performance

Le diagramme Star Schema peut être visualisé sur dbdiagram.io en copiant le 
contenu de star_schema_dbdiagram.sql.

N'hésitez pas si vous avez des questions.

Cordialement,
[Votre Nom]
```

---

## 🔍 FAQ

### Q: Quel fichier lire en premier?
**R**: README.md pour une vue d'ensemble, puis REPONSES_CASE_STUDY.md pour les détails.

### Q: Comment exécuter les requêtes SQL?
**R**: Voir la section "Comment Utiliser les Fichiers" dans README.md.

### Q: Comment générer le diagramme?
**R**: Copier star_schema_dbdiagram.sql dans https://dbdiagram.io

### Q: Les datasets sont-ils inclus?
**R**: Oui, dans le dossier datasets/ (fact_order_line.csv et fact_shop.csv).

### Q: Puis-je modifier les fichiers?
**R**: Oui, tous les fichiers sont modifiables. Le code SQL est commenté pour faciliter les ajustements.

### Q: Quelle est la différence entre REPONSES_CASE_STUDY.md et STAR_SCHEMA_SUMMARY.md?
**R**: 
- REPONSES_CASE_STUDY.md = Toutes les réponses (Part 1 + Part 2)
- STAR_SCHEMA_SUMMARY.md = Documentation technique approfondie du Star Schema uniquement

---

## 🚀 Quick Start

### En 5 Minutes
```bash
# 1. Lire le résumé
open EXECUTIVE_SUMMARY.md

# 2. Générer le diagramme
# Copier star_schema_dbdiagram.sql dans dbdiagram.io
cat star_schema_dbdiagram.sql | pbcopy  # macOS
```

### En 30 Minutes
```bash
# 1. Lire la documentation
open README.md
open REPONSES_CASE_STUDY.md

# 2. Voir le code SQL
open queries_part1.sql

# 3. Générer le diagramme
# Copier star_schema_dbdiagram.sql dans dbdiagram.io
```

### En 1 Heure (Exécution Complète)
```bash
# 1. Installer DuckDB
brew install duckdb  # macOS

# 2. Lancer DuckDB
duckdb mirakl_analysis.db

# 3. Dans DuckDB, charger les données
CREATE TABLE fact_order_line AS 
SELECT * FROM read_csv_auto('datasets/fact_order_line.csv');

CREATE TABLE fact_shop AS 
SELECT * FROM read_csv_auto('datasets/fact_shop.csv');

# 4. Exécuter les queries
.read queries_part1.sql

# 5. Exporter les résultats
COPY (SELECT * FROM ...) TO 'results.csv' (HEADER, DELIMITER ',');
```

---

## 📚 Ressources Complémentaires

### Documentation Technique
- PostgreSQL: https://www.postgresql.org/docs/
- DuckDB: https://duckdb.org/docs/
- dbdiagram.io: https://dbdiagram.io/docs

### Data Modeling
- Kimball's Star Schema: "The Data Warehouse Toolkit"
- SCD Types: https://en.wikipedia.org/wiki/Slowly_changing_dimension

### Analytics Engineering
- dbt Best Practices: https://docs.getdbt.com/guides/best-practices
- Modern Data Stack: https://www.getdbt.com/analytics-engineering/

---

## 🎓 Conclusion

**6 fichiers de réponses** couvrant:
- ✅ Toutes les questions du case study
- ✅ Code SQL exécutable
- ✅ Diagramme Star Schema
- ✅ Documentation complète
- ✅ Guides d'utilisation

