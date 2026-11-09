-- ========================================================
-- Файл: queries.sql - Складні аналітичні SQL-запити
-- ========================================================

-- Запит 1: Топ послуг за популярністю та загальним доходом автосервісу
SELECT 
    s.service_name,
    s.category,
    COUNT(od.detail_id) AS times_ordered,
    SUM(od.quantity) AS total_units,
    ROUND(SUM(od.price * od.quantity * (1 - od.discount_percent / 100)), 2) AS total_revenue
FROM services s
JOIN order_details od ON s.service_id = od.service_id
GROUP BY s.service_id, s.service_name, s.category
ORDER BY total_revenue DESC;

-- Запит 2: Рейтинг брендів автомобілів за середньою вартістю ремонту
SELECT 
    c.brand,
    COUNT(DISTINCT c.car_id) AS cars_serviced,
    COUNT(ro.order_id) AS total_repairs,
    ROUND(AVG(ro.total_cost), 2) AS avg_repair_cost,
    SUM(ro.total_cost) AS total_brand_revenue
FROM cars c
JOIN repair_orders ro ON c.car_id = ro.car_id
WHERE ro.status = 'Completed'
GROUP BY c.brand
ORDER BY avg_repair_cost DESC;

-- Запит 3: Клієнти, загальні витрати яких перевищують середній чек по сервісу
SELECT 
    cl.client_id,
    cl.first_name || ' ' || cl.last_name AS client_name,
    cl.phone,
    COUNT(ro.order_id) AS orders_count,
    SUM(ro.total_cost) AS total_spent
FROM clients cl
JOIN cars c ON cl.client_id = c.client_id
JOIN repair_orders ro ON c.car_id = ro.car_id
WHERE ro.status = 'Completed'
GROUP BY cl.client_id, cl.first_name, cl.last_name, cl.phone
HAVING SUM(ro.total_cost) > (
    SELECT AVG(total_cost) FROM repair_orders WHERE status = 'Completed'
)
ORDER BY total_spent DESC;
