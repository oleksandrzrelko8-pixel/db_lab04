import psycopg2

class DatabaseConnection:
    def __init__(self, dbname='autoservice', user='postgres',
                 password='password', host='localhost', port=5432):
        self.conn_params = {
            'dbname': dbname,
            'user': user,
            'password': password,
            'host': host,
            'port': port
        }
        self.conn = None

    def connect(self):
        try:
            self.conn = psycopg2.connect(**self.conn_params)
            print("✓ Успішне підключення до бази даних автосервісу")
        except Exception as e:
            print(f"✗ Помилка підключення: {e}")

    def disconnect(self):
        if self.conn:
            self.conn.close()
            print("З'єднання закрито")

    def execute_query(self, query, params=None):
        try:
            cursor = self.conn.cursor()
            cursor.execute(query, params)
            self.conn.commit()
            return cursor
        except Exception as e:
            if self.conn:
                self.conn.rollback()
            print(f"Помилка запиту: {e}")
            return None
