-- ========================================================
-- Файл: 03_create_procedures.sql - Збережені процедури / функції
-- ========================================================

-- Процедура 1: Створення нового замовлення-наряду з перевіркою існування авто
CREATE OR REPLACE FUNCTION create_repair_order(
    p_car_id INT,
    p_mechanic_id INT,
    p_notes TEXT,
    p_service_id INT
) RETURNS INT AS $$
DECLARE
    v_order_id INT;
    v_service_price DECIMAL(10,2);
BEGIN
    -- Отримуємо базову ціну послуги
    SELECT base_price INTO v_service_price FROM services WHERE service_id = p_service_id;
    
    -- Створюємо наряд
    INSERT INTO repair_orders (car_id, mechanic_id, status, notes, total_cost)
    VALUES (p_car_id, p_mechanic_id, 'Pending', p_notes, COALESCE(v_service_price, 0))
    RETURNING order_id INTO v_order_id;
    
    -- Додаємо первинну послугу в деталізацію
    IF v_service_price IS NOT NULL THEN
        INSERT INTO order_details (order_id, service_id, price, quantity, discount_percent)
        VALUES (v_order_id, p_service_id, v_service_price, 1, 0);
    END IF;
    
    RETURN v_order_id;
END;
$$ LANGUAGE plpgsql;

-- Процедура 2: Завершення замовлення та надання персональної знижки клієнту
CREATE OR REPLACE FUNCTION complete_repair_order(
    p_order_id INT,
    p_discount_percent DECIMAL DEFAULT 0
) RETURNS TABLE(order_id INT, status VARCHAR, final_total DECIMAL) AS $$
DECLARE
    v_new_total DECIMAL(10,2);
BEGIN
    -- Застосовуємо знижку до всіх позицій
    UPDATE order_details
    SET discount_percent = p_discount_percent
    WHERE order_details.order_id = p_order_id;

    -- Розраховуємо фінальну суму
    SELECT COALESCE(SUM(price * quantity * (1 - discount_percent / 100)), 0)
    INTO v_new_total
    FROM order_details
    WHERE order_details.order_id = p_order_id;

    -- Фіксуємо дату завершення та новий статус
    RETURN QUERY
    UPDATE repair_orders r
    SET status = 'Completed',
        completion_date = CURRENT_TIMESTAMP,
        total_cost = v_new_total
    WHERE r.order_id = p_order_id
    RETURNING r.order_id, r.status, r.total_cost;
END;
$$ LANGUAGE plpgsql;

-- Процедура 3: Отримання повної аналітики по клієнту
CREATE OR REPLACE FUNCTION get_client_repair_history(p_client_id INT)
RETURNS TABLE(
    client_name TEXT,
    car_info TEXT,
    total_orders BIGINT,
    total_spent DECIMAL,
    last_visit TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cl.first_name || ' ' || cl.last_name AS client_name,
        c.brand || ' ' || c.model || ' (' || c.license_plate || ')' AS car_info,
        COUNT(ro.order_id) AS total_orders,
        COALESCE(SUM(ro.total_cost), 0) AS total_spent,
        MAX(ro.order_date) AS last_visit
    FROM clients cl
    JOIN cars c ON cl.client_id = c.client_id
    LEFT JOIN repair_orders ro ON c.car_id = ro.car_id
    WHERE cl.client_id = p_client_id
    GROUP BY cl.client_id, cl.first_name, cl.last_name, c.brand, c.model, c.license_plate;
END;
$$ LANGUAGE plpgsql;
