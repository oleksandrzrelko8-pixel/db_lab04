-- ========================================================
-- Файл: 04_create_triggers.sql - Тригери автоматизації та аудиту
-- ========================================================

-- Таблиця для аудиту змін цін послуг
CREATE TABLE IF NOT EXISTS service_price_audit (
    audit_id SERIAL PRIMARY KEY,
    service_id INT NOT NULL,
    old_price DECIMAL(10,2),
    new_price DECIMAL(10,2),
    changed_by VARCHAR(50) DEFAULT CURRENT_USER,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Тригер 1: Логування змін цін на послуги
CREATE OR REPLACE FUNCTION log_service_price_change()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND OLD.base_price <> NEW.base_price THEN
        INSERT INTO service_price_audit (service_id, old_price, new_price, changed_by)
        VALUES (NEW.service_id, OLD.base_price, NEW.base_price, CURRENT_USER);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_audit_service_price ON services;
CREATE TRIGGER trg_audit_service_price
AFTER UPDATE ON services
FOR EACH ROW
EXECUTE FUNCTION log_service_price_change();

-- Тригер 2: Автоматичний перерахунок total_cost у наряді при додаванні/зміні робіт
CREATE OR REPLACE FUNCTION recalculate_order_total()
RETURNS TRIGGER AS $$
DECLARE
    v_target_order_id INT;
    v_calculated_total DECIMAL(10,2);
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_target_order_id := OLD.order_id;
    ELSE
        v_target_order_id := NEW.order_id;
    END IF;

    -- Розрахунок поточної суми всіх позицій
    SELECT COALESCE(SUM(price * quantity * (1 - discount_percent / 100)), 0)
    INTO v_calculated_total
    FROM order_details
    WHERE order_id = v_target_order_id;

    -- Оновлюємо суму в замовленні
    UPDATE repair_orders
    SET total_cost = v_calculated_total
    WHERE order_id = v_target_order_id;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_recalc_order_total ON order_details;
CREATE TRIGGER trg_recalc_order_total
AFTER INSERT OR UPDATE OR DELETE ON order_details
FOR EACH ROW
EXECUTE FUNCTION recalculate_order_total();
