import sys
from database import DatabaseConnection

def display_clients(clients):
    if not clients:
        print("Клієнтів не знайдено.")
        return
    print("-" * 75)
    print(f"{'ID':<5} {'Ім\'я':<15} {'Прізвище':<15} {'Телефон':<18} {'Email':<20}")
    print("-" * 75)
    for c in clients:
        print(f"{c[0]:<5} {c[1]:<15} {c[2]:<15} {c[3]:<18} {str(c[4]):<20}")
    print("-" * 75)

def display_cars(cars):
    if not cars:
        print("Автомобілів не знайдено.")
        return
    print("-" * 85)
    print(f"{'ID':<5} {'Власник':<20} {'Марка':<12} {'Модель':<15} {'Рік':<6} {'Держномер':<12} {'Пробіг':<8}")
    print("-" * 85)
    for car in cars:
        print(f"{car[0]:<5} {car[1]:<20} {car[2]:<12} {car[3]:<15} {car[4]:<6} {car[5]:<12} {car[6]:<8}")
    print("-" * 85)

def display_orders(orders):
    if not orders:
        print("Замовлень не знайдено.")
        return
    print("-" * 95)
    print(f"{'№':<5} {'Дата':<19} {'Клієнт':<18} {'Авто':<18} {'Статус':<14} {'Сума (грн)':<12}")
    print("-" * 95)
    for o in orders:
        print(f"{o[0]:<5} {str(o[1])[:19]:<19} {o[2]:<18} {o[3]:<18} {o[4]:<14} {float(o[5]):<12.2f}")
    print("-" * 95)

def main():
    db = DatabaseConnection()
    db.connect()
    if not db.conn:
        print("Перевірте налаштування підключення у database.py")
        return

    while True:
        print("\n" + "="*50)
        print(" СИСТЕМА УПРАВЛІННЯ АВТОСЕРВІСОМ (AutoService CLI)")
        print("="*50)
        print("1. Переглянути всіх клієнтів (Read)")
        print("2. Додати нового клієнта (Create)")
        print("3. Оновити номер телефону клієнта (Update)")
        print("4. Видалити клієнта (Delete)")
        print("5. Переглянути автомобілі клієнтів")
        print("6. Додати авто клієнту")
        print("7. Переглянути замовлення-наряди")
        print("8. Створити нове замовлення через збережену процедуру")
        print("0. Вихід")
        print("="*50)

        choice = input("Оберіть пункт меню: ").strip()

        if choice == '1':
            cursor = db.execute_query("SELECT client_id, first_name, last_name, phone, email FROM clients ORDER BY client_id")
            if cursor:
                display_clients(cursor.fetchall())

        elif choice == '2':
            fn = input("Ім'я: ").strip()
            ln = input("Прізвище: ").strip()
            phone = input("Телефон (+380...): ").strip()
            email = input("Email: ").strip()
            query = "INSERT INTO clients (first_name, last_name, phone, email) VALUES (%s, %s, %s, %s) RETURNING client_id"
            cursor = db.execute_query(query, (fn, ln, phone, email))
            if cursor:
                print(f"✓ Клієнта успішно зареєстровано з ID: {cursor.fetchone()[0]}")

        elif choice == '3':
            cid = input("ID клієнта для оновлення: ").strip()
            new_phone = input("Новий телефон: ").strip()
            query = "UPDATE clients SET phone = %s WHERE client_id = %s"
            cursor = db.execute_query(query, (new_phone, cid))
            if cursor:
                print(f"✓ Телефон клієнта #{cid} оновлено!")

        elif choice == '4':
            cid = input("ID клієнта для видалення: ").strip()
            confirm = input(f"Ви впевнені, що хочете видалити клієнта #{cid} та всі його авто? (так/ні): ").strip().lower()
            if confirm == 'так':
                query = "DELETE FROM clients WHERE client_id = %s"
                cursor = db.execute_query(query, (cid,))
                if cursor:
                    print(f"✓ Клієнта #{cid} видалено з бази!")

        elif choice == '5':
            query = """
                SELECT c.car_id, cl.first_name || ' ' || cl.last_name, 
                       c.brand, c.model, c.year, c.license_plate, c.mileage
                FROM cars c
                JOIN clients cl ON c.client_id = cl.client_id
                ORDER BY c.car_id
            """
            cursor = db.execute_query(query)
            if cursor:
                display_cars(cursor.fetchall())

        elif choice == '6':
            cid = input("ID власника авто: ").strip()
            vin = input("VIN-код (17 символів): ").strip()
            brand = input("Марка: ").strip()
            model = input("Модель: ").strip()
            year = int(input("Рік випуску: "))
            plate = input("Держномер: ").strip()
            mileage = int(input("Пробіг (км): "))
            query = """
                INSERT INTO cars (client_id, vin, brand, model, year, license_plate, mileage)
                VALUES (%s, %s, %s, %s, %s, %s, %s) RETURNING car_id
            """
            cursor = db.execute_query(query, (cid, vin, brand, model, year, plate, mileage))
            if cursor:
                print(f"✓ Автомобіль успішно додано з ID: {cursor.fetchone()[0]}")

        elif choice == '7':
            query = """
                SELECT ro.order_id, ro.order_date, 
                       cl.first_name || ' ' || cl.last_name AS client,
                       c.brand || ' ' || c.model AS car,
                       ro.status, ro.total_cost
                FROM repair_orders ro
                JOIN cars c ON ro.car_id = c.car_id
                JOIN clients cl ON c.client_id = cl.client_id
                ORDER BY ro.order_id DESC
            """
            cursor = db.execute_query(query)
            if cursor:
                display_orders(cursor.fetchall())

        elif choice == '8':
            print("\n--- Виклик процедури create_repair_order ---")
            car_id = int(input("ID авто: "))
            mechanic_id = int(input("ID майстра: "))
            service_id = int(input("ID послуги: "))
            notes = input("Примітки: ").strip()
            query = "SELECT create_repair_order(%s, %s, %s, %s)"
            cursor = db.execute_query(query, (car_id, mechanic_id, notes, service_id))
            if cursor:
                order_id = cursor.fetchone()[0]
                print(f"✓ Замовлення-наряд створено через процедуру! Номер наряду: #{order_id}")

        elif choice == '0':
            print("Роботу завершено.")
            break
        else:
            print("Невірна опція, спробуйте ще раз.")

    db.disconnect()

if __name__ == "__main__":
    main()
