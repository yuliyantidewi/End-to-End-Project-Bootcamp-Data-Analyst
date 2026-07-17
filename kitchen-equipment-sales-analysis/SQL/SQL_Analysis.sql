#1. Mengambil total ongkos kirim yang dibayarkan pelanggan di seluruh pesanan sepanjang 2025 dan berapa rata-rata ongkos kirim per pesanan 
SELECT
    SUM(shipping_fee)as total_ongkos_kirim,
    AVG(shipping_fee)as rerata_ongkos_kirim
FROM `Toko_Peralatan_Dapur.orders`
WHERE EXTRACT(YEAR FROM sales_date)=2025;

#2 top 5 product berdasarkan status complete dan apakah berbeda dengan top 5 product berdasarkan revenue?
SELECT
product_name,
COUNT(order_id) as Total_Order,
SUM(quantity) as Total_QTY
FROM `Toko_Peralatan_Dapur.orders`
WHERE status_clean='complete'
GROUP BY product_name
ORDER BY Total_QTY DESC
Limit 5;

SELECT 
product_name,
COUNT(total_sales) as Total_Revenue
FROM `Toko_Peralatan_Dapur.orders`
GROUP BY product_name 
ORDER BY Total_Revenue DESC
Limit 5;

#3 Berapa jumlah pesanan dan total revenue complete dari Q4(Oktober-Desember)2025
SELECT
COUNT(DISTINCT(order_id)) AS Jumlah_Pesanan,
SUM(total_sales) AS Total_Revenue
FROM `Toko_Peralatan_Dapur.orders`
WHERE status_clean='complete'
 AND EXTRACT(YEAR FROM sales_date)=2025
 AND EXTRACT(MONTH FROM sales_date) BETWEEN 10 AND 12;

#4 Kota mana yang memiliki rata_rata ongkos kirim paling mahal dan berapa selisih dengan kota yang paling murah 
WITH avg_shipping AS (
  SELECT
    city_clean,
    AVG(shipping_fee) AS avg_shipping_fee
  FROM `Toko_Peralatan_Dapur.orders`
  WHERE city_clean IS NOT NULL
  GROUP BY city_clean
)
SELECT
  MAX(CASE WHEN rn_desc = 1 THEN city_clean END) AS kota_termahal,
  MAX(CASE WHEN rn_desc = 1 THEN avg_shipping_fee END) AS ongkos_termahal,
  MAX(CASE WHEN rn_asc = 1 THEN city_clean END) AS kota_termurah,
  MAX(CASE WHEN rn_asc = 1 THEN avg_shipping_fee END) AS ongkos_termurah,
  MAX(CASE WHEN rn_desc = 1 THEN avg_shipping_fee END) -
  MAX(CASE WHEN rn_asc = 1 THEN avg_shipping_fee END) AS selisih
FROM (
  SELECT *,
         ROW_NUMBER() OVER (ORDER BY avg_shipping_fee DESC) AS rn_desc,
         ROW_NUMBER() OVER (ORDER BY avg_shipping_fee ASC) AS rn_asc
  FROM avg_shipping
);

#5 berapa total nilai rupiah dari pesanan berstatus refund dan berapa presentasenya terhadap gross sales setahun?
WITH Sales_Summary AS(
SELECT 
SUM(CASE WHEN status_clean ='refund' THEN total_sales ELSE 0 END) AS total_refund,
SUM (total_sales) as gross_sales
FROM `Toko_Peralatan_Dapur.orders`
)
SELECT 
total_refund,
gross_sales,
ROUND((total_refund/gross_sales)*100,2) AS refund_precentage
FROM Sales_Summary;


#6 produk apa saja (5 teratas) dengan rata-rata qty per pesanan tertinggi dengan syarat minimal 50 pesanan completed
SELECT
    product_name,
    COUNT(DISTINCT order_id) AS total_orders,
    AVG(quantity) AS avg_quantity
FROM `Toko_Peralatan_Dapur.orders`
WHERE status_clean = 'complete'
GROUP BY product_name
HAVING COUNT(DISTINCT order_id) >= 50
ORDER BY avg_quantity DESC
LIMIT 5;

#7 untuk masing-masing kategori dari 3 kategori, bulan apa yang mencatat revenue completed tertinggi ?
SELECT 
category_clean,
EXTRACT(MONTH FROM sales_date) as bulan,
SUM(total_sales) as total_revenue
FROM `Toko_Peralatan_Dapur.orders`
WHERE status_clean = 'complete'
GROUP BY 
category_clean,
bulan 
ORDER BY 
category_clean,
total_revenue DESC;
 
#8 dari 57 product yang ada, berapa produk teratas yang menyumbang 80% dari total revenue completed ?
WITH sales_summary AS (
    SELECT 
    product_name,
    SUM(total_sales) AS gross_sales,
    SUM(CASE WHEN status_clean ='complete' THEN total_sales ELSE 0 END) AS total_sales_complete
    FROM `Toko_Peralatan_Dapur.orders`
    group by product_name
)
SELECT * FROM (
SELECT 
product_name, 
ROUND((total_sales_complete/gross_sales)*100,1) AS precentage
FROM sales_summary
)
WHERE precentage >= 80
order BY precentage DESC;

#9 Untuk pelanggan dengan lebih dari 5 completed, berapakah rata-rata jeda hari antara dua pesanan berturut-turut, dan siapa pelanggan dengan jeda rerata tersingkat?
WITH ordered_orders AS (
  SELECT 
    customer_name_clean,
    sales_date,
    LAG(sales_date) OVER(PARTITION BY customer_name_clean ORDER BY sales_date ASC) AS previous_sales_date
  FROM `Toko_Peralatan_Dapur.orders`
  WHERE status_clean = 'complete'
),
jeda_per_order AS (
  SELECT 
    customer_name_clean,
    DATE_DIFF(sales_date, previous_sales_date, DAY) AS jeda_hari
  FROM ordered_orders
)
SELECT 
  customer_name_clean AS nama_pelanggan,
  COUNT(jeda_hari) + 1 AS total_pesanan_complete,
  ROUND(AVG(jeda_hari), 1) AS rata_rata_jeda_hari
FROM jeda_per_order
GROUP BY customer_name_clean
HAVING total_pesanan_complete > 5
ORDER BY rata_rata_jeda_hari ASC;

#10 Produk apa yang memiliki refund rate tertinggi, dan berapa potensi revenue yang bisa diselamatkan jika refund rate product tersebut turun ke rata-rata toko (~5%)?
WITH Sales_Summary AS(
SELECT 
product_name,
SUM(CASE WHEN status_clean ='refund' THEN total_sales ELSE 0 END) AS total_refund,
SUM (total_sales) as gross_sales
FROM `Toko_Peralatan_Dapur.orders`
GROUP BY product_name
)
SELECT * FROM (
SELECT 
product_name,
ROUND((total_refund/gross_sales)*100,2) AS refund_precentage
FROM Sales_Summary
) 
WHERE refund_precentage > 5
ORDER BY refund_precentage DESC;







