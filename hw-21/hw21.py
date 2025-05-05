import psycopg2
import csv


def get_connection():
    return psycopg2.connect(
        host='localhost',
        port=5432,
        database='demo',
        user='postgres',
        password='postgres'
    )
# --Задача 1. Экспорт расписания рейсов по конкретному маршруту.
# --Нужно создать функцию на Python, которая выгружает в CSV-файл расписание рейсов между двумя городами
# (например, Москва и Санкт-Петербург). Функция должна включать:
# --- Номер рейса
# --- Время вылета и прилета
# --- Тип самолета
# --- Среднюю цену билета
# --  SELECT сделать без использования pandas!


def export_flights(departure_city: str, arrival_city: str, file_path, connection):
    query = """
        select 
            a2.airport_name as departure_city,
            a3.airport_name as arrival_city,
            f.status,
            f.flight_id,
            f.flight_no,
            f.scheduled_departure,
            f.scheduled_arrival,
            a.model,
            round(avg(tf.amount), 2) as avg_amount
        from bookings.flights f
        join bookings.aircrafts a on a.aircraft_code =f.aircraft_code
        join bookings.ticket_flights tf on tf.flight_id = f.flight_id
        join bookings.airports a2 on a2.airport_code = f.departure_airport 
        join bookings.airports a3 on a3.airport_code = f.arrival_airport
        WHERE a2.airport_name = %s
        and a3.airport_name = %s
        group by f.flight_id, f.flight_no, f.scheduled_departure, f.scheduled_arrival, a.model, f.status, a2.airport_name, a3.airport_name;          
    """
    try:
        with connection.cursor() as cursor:
            cursor.execute(query, (departure_city, arrival_city))
            results = cursor.fetchall()
            if not results:
                print("Нет данных для экспорта.")
                return

            with open(file_path, mode='w', newline='', encoding='utf-8') as file:
                writer = csv.writer(file)
                writer.writerow(
                    ['Departure City', 'Arrival City', 'Status', 'Flight ID', 'Flight No', 'Scheduled Departure', 'Scheduled Arrival',
                     'Model', 'Average Amount'])
                writer.writerows(results)

            print(f"Данные экспортированы в {file_path}")

    except (psycopg2.Error, IOError) as e:
        print(f"Произошла ошибка при экспорте данных: {e}")


# --Задача 2. Массовое обновление статусов рейсов
# --Создать функцию для пакетного обновления статусов рейсов (например, "Задержан" или "Отменен"). Функция должна:
# --- Принимать список рейсов и их новых статусов
# --- Подтверждать количество обновленных записей
# --- Обрабатывать ошибки (например, несуществующие рейсы)
def update_flights_status(updates: list, conn):
    query = """
        update bookings.flights
        set status = %s
        where flight_id = %s;
    """
    try:
        cursor = conn.cursor()
        updates_tuples = [(update["new_status"], update["flight_id"]) for update in updates]
        cursor.executemany(query, updates_tuples)
        conn.commit()
        if cursor.rowcount == 0:
            print("Ни одна запись не была обновлена. Проверьте корректность ID рейсов.")
        else:
            print(f"Обновлено записей: {cursor.rowcount}")
    except Exception as e:
        print(f"Ошибка при обновлении статусов рейсов: {e}")


if __name__ == '__main__':
    conn = get_connection()
    # входные данные:
    departure_name = 'Мурманск'
    arrival_name = 'Внуково'
    updates = [
        {"flight_id": 15591, "new_status": "Delayed"},
        {"flight_id": 15588, "new_status": "Cancelled"}
    ]
    path = departure_name + '_to_' + arrival_name + '.csv'
    try:
        export_flights(departure_name, arrival_name, path, conn)
        update_flights_status(updates, conn)
    finally:
        conn.close()