-- ========================================================
-- Лабораторна робота 04. Предметна область: Автосервіс
-- Файл: 01_create_tables.sql - Створення структури таблиць (3NF)
-- ========================================================

DROP TABLE IF EXISTS order_details CASCADE;
DROP TABLE IF EXISTS repair_orders CASCADE;
DROP TABLE IF EXISTS services CASCADE;
DROP TABLE IF EXISTS mechanics CASCADE;
DROP TABLE IF EXISTS cars CASCADE;
DROP TABLE IF EXISTS clients CASCADE;
DROP TABLE IF EXISTS service_price_audit CASCADE;

-- 1. Таблиця клієнтів (власників авто)
CREATE TABLE clients (
    client_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Таблиця автомобілів клієнтів
CREATE TABLE cars (
    car_id SERIAL PRIMARY KEY,
    client_id INT NOT NULL REFERENCES clients(client_id) ON DELETE CASCADE,
    vin VARCHAR(17) UNIQUE NOT NULL,
    brand VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    year INT CHECK (year >= 1980 AND year <= EXTRACT(YEAR FROM CURRENT_DATE)),
    license_plate VARCHAR(15) UNIQUE NOT NULL,
    mileage INT CHECK (mileage >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Таблиця автомайстрів
CREATE TABLE mechanics (
    mechanic_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    specialization VARCHAR(50) NOT NULL, -- Моторист, Електрик, Ходовик, Діагност
    phone VARCHAR(20) NOT NULL,
    hourly_rate DECIMAL(10,2) CHECK (hourly_rate > 0),
    hire_date DATE DEFAULT CURRENT_DATE
);

-- 4. Таблиця каталогу послуг
CREATE TABLE services (
    service_id SERIAL PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL, -- Діагностика, ТО, Ходова частина, Двигун, Електрика
    base_price DECIMAL(10,2) CHECK (base_price >= 0),
    duration_hours DECIMAL(4,2) CHECK (duration_hours > 0),
    description TEXT
);

-- 5. Таблиця замовлень-нарядів на ремонт
CREATE TABLE repair_orders (
    order_id SERIAL PRIMARY KEY,
    car_id INT NOT NULL REFERENCES cars(car_id) ON DELETE RESTRICT,
    mechanic_id INT NOT NULL REFERENCES mechanics(mechanic_id) ON DELETE RESTRICT,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completion_date TIMESTAMP,
    status VARCHAR(20) DEFAULT 'Pending' CHECK (status IN ('Pending', 'In Progress', 'Completed', 'Cancelled')),
    total_cost DECIMAL(10,2) DEFAULT 0 CHECK (total_cost >= 0),
    notes TEXT
);

-- 6. Деталізація робіт замовлення-наряду (зв'язок багатьох робіт із замовленням)
CREATE TABLE order_details (
    detail_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL REFERENCES repair_orders(order_id) ON DELETE CASCADE,
    service_id INT NOT NULL REFERENCES services(service_id) ON DELETE RESTRICT,
    price DECIMAL(10,2) CHECK (price >= 0),
    quantity INT DEFAULT 1 CHECK (quantity > 0),
    discount_percent DECIMAL(5,2) DEFAULT 0 CHECK (discount_percent >= 0 AND discount_percent <= 100)
);

-- Індекси для прискорення запитів
CREATE INDEX idx_cars_client_id ON cars(client_id);
CREATE INDEX idx_orders_car_id ON repair_orders(car_id);
CREATE INDEX idx_orders_mechanic_id ON repair_orders(mechanic_id);
CREATE INDEX idx_orders_status ON repair_orders(status);
CREATE INDEX idx_details_order_id ON order_details(order_id);
