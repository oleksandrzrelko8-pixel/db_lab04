from flask import Flask, render_template, request, redirect, url_for, flash
import psycopg2

app = Flask(__name__)
app.secret_key = 'autoservice_secret_key_lab04'

DB_PARAMS = {
    'dbname': 'autoservice',
    'user': 'postgres',
    'password': 'password',
    'host': 'localhost',
    'port': 5432
}

def get_db():
    return psycopg2.connect(**DB_PARAMS)

@app.route('/')
def index():
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT COUNT(*) FROM clients")
    total_clients = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM cars")
    total_cars = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM repair_orders WHERE status IN ('Pending', 'In Progress')")
    active_orders = cur.fetchone()[0]
    cur.execute("SELECT COALESCE(SUM(total_cost), 0) FROM repair_orders WHERE status = 'Completed'")
    total_revenue = cur.fetchone()[0]
    
    # Останні наряди
    cur.execute("SELECT * FROM v_active_repair_orders LIMIT 5")
    recent_orders = cur.fetchall()
    
    cur.close()
    conn.close()
    return render_template('index.html', clients=total_clients, cars=total_cars, 
                           active_orders=active_orders, revenue=total_revenue, orders=recent_orders)

@app.route('/clients', methods=['GET', 'POST'])
def clients():
    conn = get_db()
    cur = conn.cursor()
    if request.method == 'POST':
        fn = request.form['first_name']
        ln = request.form['last_name']
        phone = request.form['phone']
        email = request.form['email']
        cur.execute("INSERT INTO clients (first_name, last_name, phone, email) VALUES (%s, %s, %s, %s)",
                    (fn, ln, phone, email))
        conn.commit()
        flash('Клієнта успішно зареєстровано!', 'success')
        cur.close()
        conn.close()
        return redirect(url_for('clients'))

    cur.execute("SELECT client_id, first_name, last_name, phone, email, created_at FROM clients ORDER BY client_id DESC")
    clients_list = cur.fetchall()
    cur.close()
    conn.close()
    return render_template('clients.html', clients=clients_list)

@app.route('/cars')
def cars():
    conn = get_db()
    cur = conn.cursor()
    cur.execute("""
        SELECT c.car_id, c.brand, c.model, c.year, c.license_plate, c.mileage,
               cl.first_name || ' ' || cl.last_name AS owner_name, cl.phone
        FROM cars c
        JOIN clients cl ON c.client_id = cl.client_id
        ORDER BY c.car_id DESC
    """)
    cars_list = cur.fetchall()
    cur.close()
    conn.close()
    return render_template('cars.html', cars=cars_list)

@app.route('/orders')
def orders():
    conn = get_db()
    cur = conn.cursor()
    cur.execute("""
        SELECT ro.order_id, ro.order_date, ro.status, ro.total_cost,
               cl.first_name || ' ' || cl.last_name AS client_name,
               c.brand || ' ' || c.model AS car_title, c.license_plate,
               m.first_name || ' ' || m.last_name AS mechanic_name
        FROM repair_orders ro
        JOIN cars c ON ro.car_id = c.car_id
        JOIN clients cl ON c.client_id = cl.client_id
        JOIN mechanics m ON ro.mechanic_id = m.mechanic_id
        ORDER BY ro.order_id DESC
    """)
    orders_list = cur.fetchall()
    cur.close()
    conn.close()
    return render_template('orders.html', orders=orders_list)

@app.route('/orders/add', methods=['GET', 'POST'])
def add_order():
    conn = get_db()
    cur = conn.cursor()
    if request.method == 'POST':
        car_id = int(request.form['car_id'])
        mechanic_id = int(request.form['mechanic_id'])
        service_id = int(request.form['service_id'])
        notes = request.form['notes']
        
        # Виклик збереженої процедури
        cur.execute("SELECT create_repair_order(%s, %s, %s, %s)",
                    (car_id, mechanic_id, notes, service_id))
        order_id = cur.fetchone()[0]
        conn.commit()
        flash(f'Замовлення-наряд #{order_id} успішно відкрито через збережену процедуру!', 'success')
        cur.close()
        conn.close()
        return redirect(url_for('orders'))

    cur.execute("SELECT c.car_id, c.brand || ' ' || c.model || ' (' || c.license_plate || ') - ' || cl.last_name FROM cars c JOIN clients cl ON c.client_id = cl.client_id")
    cars_options = cur.fetchall()
    cur.execute("SELECT mechanic_id, first_name || ' ' || last_name || ' (' || specialization || ')' FROM mechanics")
    mechanics_options = cur.fetchall()
    cur.execute("SELECT service_id, service_name || ' (' || base_price || ' грн)' FROM services")
    services_options = cur.fetchall()
    
    cur.close()
    conn.close()
    return render_template('add_order.html', cars=cars_options, mechanics=mechanics_options, services=services_options)

@app.route('/orders/complete/<int:order_id>')
def complete_order(order_id):
    conn = get_db()
    cur = conn.cursor()
    # Виклик процедури завершення
    cur.execute("SELECT * FROM complete_repair_order(%s, 5.0)", (order_id,)) # 5% знижка
    conn.commit()
    flash(f'Замовлення #{order_id} успішно закрито з персональною знижкою 5%!', 'success')
    cur.close()
    conn.close()
    return redirect(url_for('orders'))

@app.route('/analytics')
def analytics():
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT * FROM v_mechanic_performance")
    performance = cur.fetchall()
    cur.close()
    conn.close()
    return render_template('analytics.html', performance=performance)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
