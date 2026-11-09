-- ========================================================
-- Файл: 05_create_views.sql - Аналітичні представлення (VIEW)
-- ========================================================

-- Представлення 1: Детальна інформація про поточні та активні замовлення-наряди
CREATE OR REPLACE VIEW v_active_repair_orders AS
SELECT 
    ro.order_id,
    ro.order_date,
    ro.status,
    cl.first_name || ' ' || cl.last_name AS client_name,
    cl.phone AS client_phone,
    c.brand || ' ' || c.model AS car_model,
    c.license_plate,
    m.first_name || ' ' || m.last_name AS mechanic_name,
    m.specialization AS mechanic_role,
    ro.total_cost
FROM repair_orders ro
JOIN cars c ON ro.car_id = c.car_id
JOIN clients cl ON c.client_id = cl.client_id
JOIN mechanics m ON ro.mechanic_id = m.mechanic_id
WHERE ro.status IN ('Pending', 'In Progress')
ORDER BY ro.order_date DESC;

-- Представлення 2: Показники ефективності роботи автомайстрів
CREATE OR REPLACE VIEW v_mechanic_performance AS
SELECT 
    m.mechanic_id,
    m.first_name || ' ' || m.last_name AS mechanic_name,
    m.specialization,
    COUNT(ro.order_id) AS total_orders,
    COUNT(CASE WHEN ro.status = 'Completed' THEN 1 END) AS completed_orders,
    COALESCE(SUM(CASE WHEN ro.status = 'Completed' THEN ro.total_cost ELSE 0 END), 0) AS revenue_generated,
    COALESCE(ROUND(AVG(CASE WHEN ro.status = 'Completed' THEN ro.total_cost END), 2), 0) AS avg_ticket
FROM mechanics m
LEFT JOIN repair_orders ro ON m.mechanic_id = ro.mechanic_id
GROUP BY m.mechanic_id, m.first_name, m.last_name, m.specialization
ORDER BY revenue_generated DESC;
