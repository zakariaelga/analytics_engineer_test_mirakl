// ============================================
// STAR SCHEMA - Market+ Marketplace Analytics
// Designed by: Zakaria EL GAZI
// Date: 2026-02-20
// ============================================

// INSTRUCTIONS:
// 1. Go to https://dbdiagram.io
// 2. Copy this entire code
// 3. Paste in the editor
// 4. The diagram will auto-generate

// ============================================
// FACT TABLE (Core Sales Transactions)
// ============================================

Table fact_sales {
  order_item_id int [pk, note: 'Primary Key - Unique identifier for each order item']
  order_id int [note: 'Degenerate dimension - Order identifier']
  
  // Foreign Keys to Dimensions
  date_key int [ref: > dim_date.date_key, note: 'FK to date dimension']
  customer_key int [ref: > dim_customer.customer_key, note: 'FK to customer dimension']
  vendor_key int [ref: > dim_vendor.vendor_key, note: 'FK to vendor dimension']
  product_key int [ref: > dim_product.product_key, note: 'FK to product dimension']
  payment_key int [ref: > dim_payment.payment_key, note: 'FK to payment dimension']
  carrier_key int [ref: > dim_carrier.carrier_key, note: 'FK to carrier dimension']
  
  // Measures (Numeric Facts)
  quantity int [note: 'Number of units sold']
  unit_price decimal(10,2) [note: 'Price per unit']
  line_total decimal(10,2) [note: 'Calculated: quantity × unit_price']
  commission_rate decimal(5,2) [note: 'Commission percentage (e.g., 15.50 for 15.5%)']
  commission_amount decimal(10,2) [note: 'Calculated: line_total × commission_rate']
  shipping_fee decimal(10,2) [note: 'Prorata allocation of order shipping to item']
  tax_amount decimal(10,2) [note: 'Tax on this line item']
  discount_amount decimal(10,2) [note: 'Discount applied to this item']
  net_revenue decimal(10,2) [note: 'Calculated: line_total - discount_amount']
  
  // Flags (for fast filtering)
  is_paid boolean [note: 'Payment completed?']
  is_shipped boolean [note: 'Item shipped?']
  is_reviewed boolean [note: 'Customer left a review?']
  order_status varchar(50) [note: 'pending, completed, cancelled, refunded']
  
  Note: '''
    GRAIN: One row per order item (most granular level)
    PURPOSE: Core fact table for sales, revenue, and commission analytics
    VOLUME: High (millions of rows)
    PARTITIONING: By date_key (monthly partitions recommended)
  '''
}

// ============================================
// DIMENSION: TIME
// ============================================

Table dim_date {
  date_key int [pk, note: 'Surrogate key in format YYYYMMDD (e.g., 20240115)']
  full_date date [note: 'Actual date value']
  
  // Date components
  year int [note: 'Year (e.g., 2024)']
  quarter int [note: 'Quarter 1-4']
  month int [note: 'Month 1-12']
  month_name varchar(20) [note: 'January, February, etc.']
  week int [note: 'ISO week number 1-53']
  day_of_month int [note: 'Day 1-31']
  day_of_week int [note: 'Day 1-7 (Monday=1)']
  day_name varchar(20) [note: 'Monday, Tuesday, etc.']
  
  // Special flags
  is_weekend boolean [note: 'Saturday or Sunday?']
  is_holiday boolean [note: 'Public holiday?']
  
  // Fiscal calendar
  fiscal_year int [note: 'Fiscal year (may differ from calendar year)']
  fiscal_quarter int [note: 'Fiscal quarter 1-4']
  
  Note: '''
    TYPE: Conformed dimension (shared across all fact tables)
    PURPOSE: Enable time-based analysis and trending
    SIZE: Small (~3650 rows for 10 years)
    PRE-POPULATED: Yes, generate for past and future dates
  '''
}

// ============================================
// DIMENSION: CUSTOMER
// ============================================

Table dim_customer {
  customer_key int [pk, note: 'Surrogate key (auto-increment)']
  customer_id int [note: 'Business key from source system']
  
  // Customer attributes
  name varchar(255) [note: 'Customer full name']
  email varchar(255) [note: 'Customer email address']
  country varchar(100) [note: 'Customer country']
  region varchar(100) [note: 'Geographic region (derived from country)']
  signup_date date [note: 'Date customer registered']
  customer_segment varchar(50) [note: 'VIP, Regular, New, Churned']
  
  // SCD Type 2 fields (for historical tracking)
  effective_date date [note: 'Date this version became effective']
  expiration_date date [note: 'Date this version expired (NULL if current)']
  is_current boolean [note: 'Is this the current version? (TRUE/FALSE)']
  
  Note: '''
    TYPE: Slowly Changing Dimension Type 2 (SCD2)
    PURPOSE: Track customer attribute changes over time
    WHY SCD2: Customer may move countries, change segments
    EXAMPLE: Customer moves from France to Germany
      → Old row: is_current=FALSE, expiration_date=2024-03-15
      → New row: is_current=TRUE, effective_date=2024-03-15
  '''
}

// ============================================
// DIMENSION: VENDOR (Seller)
// ============================================

Table dim_vendor {
  vendor_key int [pk, note: 'Surrogate key']
  vendor_id int [note: 'Business key from source system']
  
  // Vendor attributes
  name varchar(255) [note: 'Vendor/seller name']
  country varchar(100) [note: 'Vendor country']
  region varchar(100) [note: 'Geographic region']
  signup_date date [note: 'Date vendor joined marketplace']
  status varchar(50) [note: 'active, suspended, inactive']
  vendor_tier varchar(50) [note: 'small, medium, large (based on GMV)']
  
  // SCD Type 2 fields
  effective_date date [note: 'Date this version became effective']
  expiration_date date [note: 'Date this version expired']
  is_current boolean [note: 'Is this the current version?']
  
  Note: '''
    TYPE: Slowly Changing Dimension Type 2 (SCD2)
    PURPOSE: Track vendor changes (status, tier) over time
    WHY SCD2: Vendor status changes (active→suspended), tier upgrades
    BUSINESS VALUE: Analyze performance by vendor tier, track suspensions
  '''
}

// ============================================
// DIMENSION: PRODUCT
// ============================================

Table dim_product {
  product_key int [pk, note: 'Surrogate key']
  product_id int [note: 'Business key from source system']
  
  // Product attributes
  name varchar(255) [note: 'Product name/title']
  category_key int [ref: > dim_category.category_key, note: 'FK to category dimension (snowflake)']
  vendor_key int [ref: > dim_vendor.vendor_key, note: 'FK to vendor dimension']
  price decimal(10,2) [note: 'Current list price']
  
  // SCD Type 2 fields
  effective_date date [note: 'Date this version became effective']
  expiration_date date [note: 'Date this version expired']
  is_current boolean [note: 'Is this the current version?']
  
  Note: '''
    TYPE: Slowly Changing Dimension Type 2 (SCD2)
    PURPOSE: Track product price changes over time
    WHY SCD2: Prices change frequently, need historical accuracy
    SNOWFLAKE: Links to dim_category for hierarchical analysis
  '''
}

// ============================================
// DIMENSION: CATEGORY (Hierarchical)
// ============================================

Table dim_category {
  category_key int [pk, note: 'Surrogate key']
  category_id int [note: 'Business key from source system']
  category_name varchar(255) [note: 'Category name']
  
  // Flattened hierarchy (up to 3 levels)
  level_1_category varchar(255) [note: 'Top level (e.g., Electronics)']
  level_2_category varchar(255) [note: 'Mid level (e.g., Computers)']
  level_3_category varchar(255) [note: 'Bottom level (e.g., Laptops)']
  
  category_level int [note: 'Depth in hierarchy: 1, 2, or 3']
  parent_category_id int [note: 'Reference to parent category']
  
  Note: '''
    TYPE: Hierarchical dimension (flattened)
    PURPOSE: Enable category-based analysis and roll-ups
    WHY FLATTENED: Avoid recursive queries, improve performance
    EXAMPLE: 
      Electronics > Computers > Laptops
      → level_1 = Electronics
      → level_2 = Computers
      → level_3 = Laptops
    TRADE-OFF: Some denormalization for query speed
  '''
}

// ============================================
// DIMENSION: PAYMENT
// ============================================

Table dim_payment {
  payment_key int [pk, note: 'Surrogate key']
  payment_id int [note: 'Business key from source system']
  
  // Payment attributes
  payment_method varchar(100) [note: 'credit_card, paypal, bank_transfer, etc.']
  payment_date timestamp [note: 'When payment was processed']
  status varchar(50) [note: 'approved, rejected, pending, refunded']
  amount decimal(10,2) [note: 'Payment amount']
  
  Note: '''
    TYPE: Slowly Changing Dimension Type 1 (SCD1)
    PURPOSE: Track payment methods and approval rates
    WHY SCD1: Payment status updates in place (no history needed)
    BUSINESS VALUE: Analyze payment method effectiveness, rejection rates
  '''
}

// ============================================
// DIMENSION: CARRIER (Delivery Service)
// ============================================

Table dim_carrier {
  carrier_key int [pk, note: 'Surrogate key']
  carrier_id int [note: 'Business key from source system']
  
  // Carrier attributes
  name varchar(255) [note: 'Carrier name (e.g., DHL, FedEx, UPS)']
  service_area varchar(255) [note: 'Geographic coverage area']
  avg_rating decimal(3,2) [note: 'Average customer rating (1.00 to 5.00)']
  
  Note: '''
    TYPE: Slowly Changing Dimension Type 1 (SCD1)
    PURPOSE: Track delivery service performance
    WHY SCD1: Rating updates in place
    BUSINESS RULE: Orders can have multiple carriers (different vendors)
  '''
}

// ============================================
// OPTIONAL: SEPARATE FACT TABLE FOR REVIEWS
// ============================================

Table fact_reviews {
  review_key int [pk, note: 'Surrogate key']
  review_id int [note: 'Business key from source system']
  
  // Foreign Keys
  order_item_key int [note: 'Links back to fact_sales (optional FK)']
  product_key int [ref: > dim_product.product_key]
  customer_key int [ref: > dim_customer.customer_key]
  date_key int [ref: > dim_date.date_key]
  
  // Review measures
  rating int [note: 'Star rating: 1-5']
  sentiment_score decimal(3,2) [note: 'NLP sentiment analysis: -1.00 to +1.00']
  
  Note: '''
    GRAIN: One row per review
    PURPOSE: Separate fact for reviews (late-arriving facts)
    WHY SEPARATE: Reviews arrive days/weeks after sale
    BUSINESS VALUE: Product quality analysis, vendor ratings
  '''
}

// ============================================
// RELATIONSHIPS SUMMARY
// ============================================

// STAR SCHEMA CORE:
// fact_sales → dim_date (many-to-one)
// fact_sales → dim_customer (many-to-one)
// fact_sales → dim_vendor (many-to-one)
// fact_sales → dim_product (many-to-one)
// fact_sales → dim_payment (many-to-one)
// fact_sales → dim_carrier (many-to-one)

// SNOWFLAKE EXTENSION:
// dim_product → dim_category (many-to-one)
// dim_product → dim_vendor (many-to-one)

// OPTIONAL FACT:
// fact_reviews → dim_product (many-to-one)
// fact_reviews → dim_customer (many-to-one)
// fact_reviews → dim_date (many-to-one)

// ============================================
// DESIGN DECISIONS & TRADE-OFFS
// ============================================

// 1. GRAIN: Order_item level
//    ✅ PRO: Maximum analytical flexibility
//    ✅ PRO: Supports all aggregation levels
//    ❌ CON: Larger table size
//    MITIGATION: Partitioning by date_key

// 2. SCD TYPE 2 for Customer & Vendor
//    ✅ PRO: Historical accuracy for geographic analysis
//    ✅ PRO: Track vendor tier changes over time
//    ❌ CON: More complex ETL
//    MITIGATION: Clear effective_date/expiration_date logic

// 3. FLATTENED CATEGORY HIERARCHY
//    ✅ PRO: Fast queries (no recursion)
//    ✅ PRO: Simple GROUP BY operations
//    ❌ CON: Some data duplication
//    MITIGATION: Category dimension is small

// 4. MULTIPLE CARRIERS per ORDER
//    ✅ PRO: Handled at item level (each item has one carrier)
//    ✅ PRO: Accurate carrier performance tracking
//    SOLUTION: carrier_key in fact_sales (not in dim_order)

// 5. COMMISSION at ITEM LEVEL
//    ✅ PRO: Flexible commission rates per product/category
//    ✅ PRO: Accurate vendor payouts
//    CALCULATION: commission_amount = line_total × commission_rate

// ============================================
// BUSINESS QUESTIONS SUPPORTED
// ============================================

// Q1: Revenue by category and vendor per month?
//     → JOIN fact_sales, dim_date, dim_product, dim_category, dim_vendor
//     → GROUP BY year, month, category, vendor

// Q2: Order volume and billed amount by region/country?
//     → JOIN fact_sales, dim_customer
//     → GROUP BY region, country

// Q3: Commission evolution over time?
//     → JOIN fact_sales, dim_date
//     → GROUP BY year, month
//     → SUM(commission_amount)

// Q4: Payment method usage and approval rates?
//     → JOIN fact_sales, dim_payment
//     → GROUP BY payment_method
//     → Calculate approval_rate = approved / total

// ============================================
// PERFORMANCE OPTIMIZATIONS
// ============================================

// 1. PARTITIONING:
//    - fact_sales: PARTITION BY RANGE(date_key) - Monthly
//    - fact_reviews: PARTITION BY RANGE(date_key) - Monthly

// 2. INDEXING:
//    - fact_sales: INDEX on (date_key, customer_key, vendor_key, product_key)
//    - dim_customer: INDEX on (country, is_current)
//    - dim_vendor: INDEX on (status, is_current)
//    - dim_payment: INDEX on (payment_method, status)

// 3. AGGREGATE TABLES (for dashboards):
//    - agg_daily_sales: Pre-aggregated daily metrics
//    - agg_monthly_vendor: Pre-aggregated monthly vendor performance

// 4. MATERIALIZED VIEWS:
//    - mv_top_products: Top 100 products by revenue (refreshed daily)
//    - mv_vendor_kpis: Vendor KPIs (refreshed hourly)

// ============================================
// END OF SCHEMA
// ============================================
