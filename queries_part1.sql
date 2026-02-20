-- ============================================
-- ANALYTICS ENGINEER CASE STUDY 2026
-- PART 1: BUSINESS ANALYSIS - SQL QUERIES
-- ============================================

-- Date: 2026-02-20
-- Database: PostgreSQL / DuckDB compatible

-- ============================================
-- QUESTION 1: GMV DEFINITION
-- ============================================

-- GMV = product_amount + product_amount_tax
-- Excluding: shipping, commissions, cancelled/refused orders
-- Including: All valid order_line_state (CLOSED, RECEIVED, SHIPPED, etc.)

-- Test query to verify GMV calculation
SELECT 
  operator_id,
  COUNT(DISTINCT order_id) AS total_orders,
  COUNT(order_line_id) AS total_order_lines,
  SUM(product_amount) AS sum_product_amount,
  SUM(COALESCE(product_amount_tax, 0)) AS sum_product_tax,
  SUM(product_amount + COALESCE(product_amount_tax, 0)) AS total_gmv,
  SUM(shipping_amount) AS sum_shipping_excluded,
  SUM(operator_commission_amount) AS sum_commission_excluded
FROM fact_order_line
WHERE 
  EXTRACT(YEAR FROM order_created_datetime) = 2024
  AND order_line_state NOT IN ('CANCELLED', 'REFUSED')
GROUP BY operator_id
ORDER BY total_gmv DESC;


-- ============================================
-- QUESTION 2: TOP 5 SHOPS PER MARKETPLACE
-- ============================================

WITH gmv_by_shop AS (
  SELECT 
    operator_id,
    shop_id,
    
    -- GMV calculation
    SUM(product_amount + COALESCE(product_amount_tax, 0)) AS total_gmv,
    
    -- Additional metrics for context
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(order_line_id) AS total_order_lines,
    SUM(product_quantity) AS total_products_sold,
    
    -- Average order value
    SUM(product_amount + COALESCE(product_amount_tax, 0)) / 
      NULLIF(COUNT(DISTINCT order_id), 0) AS avg_order_value,
    
    -- Commission metrics
    SUM(operator_commission_amount) AS total_commission_earned
    
  FROM fact_order_line
  WHERE 
    EXTRACT(YEAR FROM order_created_datetime) = 2024
    AND order_line_state NOT IN ('CANCELLED', 'REFUSED')
  GROUP BY operator_id, shop_id
),
ranked_shops AS (
  SELECT 
    operator_id,
    shop_id,
    total_gmv,
    total_orders,
    unique_customers,
    total_order_lines,
    total_products_sold,
    ROUND(avg_order_value, 2) AS avg_order_value,
    ROUND(total_commission_earned, 2) AS total_commission,
    
    -- Rank within each marketplace
    ROW_NUMBER() OVER (PARTITION BY operator_id ORDER BY total_gmv DESC) AS rank
  FROM gmv_by_shop
)
SELECT 
  operator_id AS marketplace,
  shop_id,
  ROUND(total_gmv, 2) AS gmv_2024,
  total_orders,
  unique_customers,
  total_order_lines,
  total_products_sold,
  avg_order_value,
  total_commission,
  rank
FROM ranked_shops
WHERE rank <= 5
ORDER BY operator_id, rank;


-- ============================================
-- QUESTION 3: ACTIVE SHOPS PER MONTH + MoM CHANGE
-- ============================================

-- Step 1: Identify active shops per month
WITH monthly_active_shops AS (
  SELECT 
    DATE_TRUNC('month', order_created_datetime)::DATE AS month,
    operator_id,
    shop_id,
    COUNT(DISTINCT order_id) AS orders_count,
    SUM(product_amount + COALESCE(product_amount_tax, 0)) AS shop_monthly_gmv
  FROM fact_order_line
  WHERE 
    EXTRACT(YEAR FROM order_created_datetime) = 2024
    AND order_line_state NOT IN ('CANCELLED', 'REFUSED')
  GROUP BY 
    DATE_TRUNC('month', order_created_datetime),
    operator_id,
    shop_id
),

-- Step 2: Count unique shops per month per marketplace
monthly_counts AS (
  SELECT 
    month,
    operator_id,
    COUNT(DISTINCT shop_id) AS active_shops,
    SUM(orders_count) AS total_orders,
    ROUND(SUM(shop_monthly_gmv), 2) AS total_gmv
  FROM monthly_active_shops
  GROUP BY month, operator_id
),

-- Step 3: Calculate month-over-month changes
with_previous AS (
  SELECT 
    month,
    operator_id,
    active_shops,
    total_orders,
    total_gmv,
    LAG(active_shops) OVER (PARTITION BY operator_id ORDER BY month) AS previous_month_shops,
    LAG(total_gmv) OVER (PARTITION BY operator_id ORDER BY month) AS previous_month_gmv
  FROM monthly_counts
)

-- Step 4: Final output with MoM calculations
SELECT 
  TO_CHAR(month, 'YYYY-MM') AS month,
  operator_id AS marketplace,
  active_shops,
  previous_month_shops,
  
  -- Absolute change
  active_shops - COALESCE(previous_month_shops, 0) AS absolute_change,
  
  -- Percentage change
  CASE 
    WHEN previous_month_shops IS NULL THEN NULL
    WHEN previous_month_shops = 0 THEN NULL
    ELSE ROUND(((active_shops - previous_month_shops) * 100.0 / previous_month_shops), 2)
  END AS pct_change_mom,
  
  -- GMV metrics
  total_gmv,
  previous_month_gmv,
  ROUND(total_gmv - COALESCE(previous_month_gmv, 0), 2) AS gmv_change,
  
  -- Average GMV per shop
  ROUND(total_gmv / NULLIF(active_shops, 0), 2) AS avg_gmv_per_shop
  
FROM with_previous
ORDER BY operator_id, month;


-- ============================================
-- QUESTION 4: ADDITIONAL KPIs
-- ============================================

-- --------------------------------------------
-- KPI #1: SHOP RETENTION RATE
-- --------------------------------------------

WITH monthly_shops AS (
  SELECT DISTINCT
    DATE_TRUNC('month', order_created_datetime)::DATE AS month,
    operator_id,
    shop_id
  FROM fact_order_line
  WHERE 
    EXTRACT(YEAR FROM order_created_datetime) = 2024
    AND order_line_state NOT IN ('CANCELLED', 'REFUSED')
),

retention_calc AS (
  SELECT 
    current.month,
    current.operator_id,
    COUNT(DISTINCT current.shop_id) AS shops_current_month,
    COUNT(DISTINCT CASE 
      WHEN previous.shop_id IS NOT NULL THEN current.shop_id 
    END) AS shops_retained_from_previous,
    
    -- Retention rate
    ROUND(
      COUNT(DISTINCT CASE WHEN previous.shop_id IS NOT NULL THEN current.shop_id END) * 100.0 / 
      NULLIF(COUNT(DISTINCT current.shop_id), 0), 
      2
    ) AS retention_rate_pct,
    
    -- New shops (not in previous month)
    COUNT(DISTINCT CASE 
      WHEN previous.shop_id IS NULL THEN current.shop_id 
    END) AS new_shops,
    
    -- Churned shops (in previous month but not current)
    COUNT(DISTINCT previous.shop_id) - 
    COUNT(DISTINCT CASE WHEN current.shop_id IS NOT NULL THEN previous.shop_id END) AS churned_shops
    
  FROM monthly_shops current
  LEFT JOIN monthly_shops previous
    ON current.shop_id = previous.shop_id
    AND current.operator_id = previous.operator_id
    AND previous.month = current.month - INTERVAL '1 month'
  GROUP BY current.month, current.operator_id
)

SELECT 
  TO_CHAR(month, 'YYYY-MM') AS month,
  operator_id AS marketplace,
  shops_current_month,
  shops_retained_from_previous,
  new_shops,
  churned_shops,
  retention_rate_pct,
  
  -- Health indicator
  CASE 
    WHEN retention_rate_pct >= 85 THEN '🟢 Excellent'
    WHEN retention_rate_pct >= 75 THEN '🟡 Good'
    WHEN retention_rate_pct >= 65 THEN '🟠 Warning'
    ELSE '🔴 Critical'
  END AS health_status
  
FROM retention_calc
ORDER BY operator_id, month;


-- --------------------------------------------
-- KPI #2: AVERAGE ORDER VALUE (AOV) BY SHOP SEGMENT
-- --------------------------------------------

WITH shop_performance AS (
  SELECT 
    operator_id,
    shop_id,
    
    -- Performance metrics
    SUM(product_amount + COALESCE(product_amount_tax, 0)) AS total_gmv,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    
    -- AOV calculation
    SUM(product_amount + COALESCE(product_amount_tax, 0)) / 
      NULLIF(COUNT(DISTINCT order_id), 0) AS aov
    
  FROM fact_order_line
  WHERE 
    EXTRACT(YEAR FROM order_created_datetime) = 2024
    AND order_line_state NOT IN ('CANCELLED', 'REFUSED')
  GROUP BY operator_id, shop_id
),

shop_segments AS (
  SELECT 
    *,
    NTILE(5) OVER (PARTITION BY operator_id ORDER BY total_gmv DESC) AS gmv_quintile,
    
    -- Segment classification
    CASE 
      WHEN NTILE(5) OVER (PARTITION BY operator_id ORDER BY total_gmv DESC) = 1 
        THEN 'Top Performers (Top 20%)'
      WHEN NTILE(5) OVER (PARTITION BY operator_id ORDER BY total_gmv DESC) IN (2,3,4) 
        THEN 'Mid-Tier (20-80%)'
      ELSE 'Long Tail (Bottom 20%)'
    END AS segment
  FROM shop_performance
)

SELECT 
  operator_id AS marketplace,
  segment,
  
  -- Shop count
  COUNT(shop_id) AS shop_count,
  
  -- AOV metrics
  ROUND(MIN(aov), 2) AS min_aov,
  ROUND(AVG(aov), 2) AS avg_aov,
  ROUND(MAX(aov), 2) AS max_aov,
  ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY aov), 2) AS median_aov,
  
  -- GMV contribution
  ROUND(SUM(total_gmv), 2) AS segment_gmv,
  ROUND(SUM(total_gmv) * 100.0 / SUM(SUM(total_gmv)) OVER (PARTITION BY operator_id), 2) AS pct_of_total_gmv,
  
  -- Order metrics
  SUM(total_orders) AS segment_orders,
  SUM(unique_customers) AS segment_customers
  
FROM shop_segments
GROUP BY operator_id, segment
ORDER BY operator_id, 
  CASE segment
    WHEN 'Top Performers (Top 20%)' THEN 1
    WHEN 'Mid-Tier (20-80%)' THEN 2
    ELSE 3
  END;


-- --------------------------------------------
-- KPI #3: REFUND RATE & IMPACT ON GMV
-- --------------------------------------------

WITH order_line_analysis AS (
  SELECT 
    operator_id,
    shop_id,
    order_line_id,
    order_id,
    order_line_state,
    product_amount + COALESCE(product_amount_tax, 0) AS line_gmv,
    
    -- Categorize order line status
    CASE 
      WHEN order_line_state IN ('CANCELLED', 'REFUSED') THEN 'problematic'
      WHEN order_line_state IN ('CLOSED', 'RECEIVED') THEN 'successful'
      ELSE 'in_progress'
    END AS status_category
    
  FROM fact_order_line
  WHERE EXTRACT(YEAR FROM order_created_datetime) = 2024
),

shop_quality_metrics AS (
  SELECT 
    operator_id,
    shop_id,
    
    -- Total metrics
    COUNT(order_line_id) AS total_order_lines,
    SUM(line_gmv) AS gross_gmv,
    
    -- Successful orders
    COUNT(CASE WHEN status_category = 'successful' THEN 1 END) AS successful_lines,
    SUM(CASE WHEN status_category = 'successful' THEN line_gmv ELSE 0 END) AS net_gmv,
    
    -- Problematic orders
    COUNT(CASE WHEN status_category = 'problematic' THEN 1 END) AS problematic_lines,
    SUM(CASE WHEN status_category = 'problematic' THEN line_gmv ELSE 0 END) AS lost_gmv,
    
    -- Refund rate calculation
    ROUND(
      COUNT(CASE WHEN status_category = 'problematic' THEN 1 END) * 100.0 / 
      NULLIF(COUNT(order_line_id), 0), 
      2
    ) AS refund_rate_pct,
    
    -- GMV impact
    ROUND(
      SUM(CASE WHEN status_category = 'problematic' THEN line_gmv ELSE 0 END) * 100.0 / 
      NULLIF(SUM(line_gmv), 0), 
      2
    ) AS gmv_impact_pct
    
  FROM order_line_analysis
  GROUP BY operator_id, shop_id
)

SELECT 
  operator_id AS marketplace,
  shop_id,
  total_order_lines,
  successful_lines,
  problematic_lines,
  ROUND(gross_gmv, 2) AS gross_gmv,
  ROUND(net_gmv, 2) AS net_gmv,
  ROUND(lost_gmv, 2) AS lost_gmv,
  refund_rate_pct,
  gmv_impact_pct,
  
  -- Health status
  CASE 
    WHEN refund_rate_pct > 15 THEN '🔴 High Risk'
    WHEN refund_rate_pct > 8 THEN '🟡 Medium Risk'
    WHEN refund_rate_pct > 5 THEN '🟢 Healthy'
    ELSE '⭐ Excellent'
  END AS quality_status,
  
  -- Action recommendation
  CASE 
    WHEN refund_rate_pct > 15 THEN 'URGENT: Investigate immediately'
    WHEN refund_rate_pct > 8 THEN 'WARNING: Monitor closely, provide coaching'
    WHEN refund_rate_pct > 5 THEN 'GOOD: Continue monitoring'
    ELSE 'EXCELLENT: Benchmark for best practices'
  END AS recommended_action
  
FROM shop_quality_metrics
WHERE total_order_lines >= 10  -- Minimum volume for statistical relevance
ORDER BY refund_rate_pct DESC, lost_gmv DESC
LIMIT 100;


-- ============================================
-- BONUS: COMPREHENSIVE DASHBOARD QUERY
-- ============================================

-- This query provides a complete overview for Customer Success dashboard

WITH base_metrics AS (
  SELECT 
    operator_id,
    DATE_TRUNC('month', order_created_datetime)::DATE AS month,
    shop_id,
    
    -- GMV metrics
    SUM(product_amount + COALESCE(product_amount_tax, 0)) AS gmv,
    
    -- Order metrics
    COUNT(DISTINCT order_id) AS orders,
    COUNT(order_line_id) AS order_lines,
    SUM(product_quantity) AS products_sold,
    
    -- Commission metrics
    SUM(operator_commission_amount) AS commission,
    
    -- Quality metrics
    COUNT(CASE WHEN order_line_state IN ('CANCELLED', 'REFUSED') THEN 1 END) AS problematic_lines,
    
    -- Customer metrics
    COUNT(DISTINCT customer_id) AS unique_customers
    
  FROM fact_order_line
  WHERE EXTRACT(YEAR FROM order_created_datetime) = 2024
  GROUP BY operator_id, DATE_TRUNC('month', order_created_datetime), shop_id
)

SELECT 
  TO_CHAR(month, 'YYYY-MM') AS month,
  operator_id AS marketplace,
  
  -- Shop metrics
  COUNT(DISTINCT shop_id) AS active_shops,
  
  -- GMV metrics
  ROUND(SUM(gmv), 2) AS total_gmv,
  ROUND(AVG(gmv), 2) AS avg_gmv_per_shop,
  
  -- Order metrics
  SUM(orders) AS total_orders,
  ROUND(SUM(gmv) / NULLIF(SUM(orders), 0), 2) AS avg_order_value,
  
  -- Commission metrics
  ROUND(SUM(commission), 2) AS total_commission,
  ROUND(SUM(commission) * 100.0 / NULLIF(SUM(gmv), 0), 2) AS avg_commission_rate_pct,
  
  -- Quality metrics
  ROUND(SUM(problematic_lines) * 100.0 / NULLIF(SUM(order_lines), 0), 2) AS refund_rate_pct,
  
  -- Customer metrics
  SUM(unique_customers) AS total_customers,
  ROUND(SUM(unique_customers)::NUMERIC / NULLIF(COUNT(DISTINCT shop_id), 0), 2) AS avg_customers_per_shop
  
FROM base_metrics
GROUP BY month, operator_id
ORDER BY operator_id, month;


-- ============================================
-- END OF QUERIES
-- ============================================

-- NOTES:
-- 1. All queries use EXTRACT(YEAR FROM ...) for PostgreSQL compatibility
-- 2. COALESCE used for NULL handling in tax fields
-- 3. NULLIF prevents division by zero errors
-- 4. Queries are optimized with CTEs for readability and performance
-- 5. All monetary values rounded to 2 decimal places
-- 6. Health indicators use emoji for visual clarity in dashboards
