-- task 1
--Вам нужно проанализировать данные о продажах билетов, чтобы получить статистику в следующих разрезах:
--- По классам обслуживания (fare_conditions)
--- По месяцам вылета
--- По аэропортам вылета
--- По комбинациям: класс + месяц, класс + аэропорт, месяц + аэропорт
--- Общие итоги
--
--Используемые таблицы:
--- ticket_flights (информация о билетах)
--- flights (информация о рейсах)
--- airports (информация об аэропортах)

SELECT 
    tf.fare_conditions,  -- По классам обслуживания (fare_conditions)
    a.airport_name,      -- По аэропортам вылета
    date_trunc('month', f.scheduled_departure) AS month_track,  -- По месяцам вылета
    COUNT(tf.ticket_no) AS total_tickets,  -- Общее количество билетов
    ROUND(AVG(tf.amount), 2) AS average_amount  -- Средняя стоимость билетов
FROM 
    bookings.ticket_flights tf 
LEFT JOIN 
    bookings.flights f ON tf.flight_id = f.flight_id
LEFT JOIN 
    bookings.airports a ON f.departure_airport = a.airport_code
GROUP BY 
    GROUPING SETS (
        (tf.fare_conditions),
        (a.airport_name),
        (month_track),
        (tf.fare_conditions, a.airport_name),
        (tf.fare_conditions, month_track),
        (a.airport_name, month_track),
        ()  -- Общие итоги
    )
ORDER BY 
    a.airport_name,
    month_track,
    tf.fare_conditions;

-- task 2
--Рейсы с задержкой больше средней (CTE + подзапрос)
--Найдите рейсы, задержка которых превышает среднюю задержку по всем рейсам.
--Используемые таблицы:
--- flights

with average_delay as (
	select 
		avg(f.scheduled_departure - f.actual_departure) as avg_delay 
	from bookings.flights f
	where actual_departure is not null
)
select 
	flight_no,
	f.scheduled_departure as sheduled_time,
	f.actual_departure as aactual_time,
	(f.scheduled_departure - f.actual_departure) as delay
from bookings.flights f
where 
actual_departure is not null
and	(f.scheduled_departure - f.actual_departure) > (select avg_delay from average_delay)

-- task 3
--Создайте представление, которое содержит все рейсы, вылетающие из Москвы.

create view bookings.msw_flights as
SELECT 
    f.flight_id,
    f.flight_no,
    f.departure_airport,
    f.arrival_airport,
    f.scheduled_departure,
    f.actual_departure,
    f.status
FROM 
    bookings.flights f
WHERE 
    f.departure_airport IN ('SVO', 'DME', 'VKO');  
;
select * from bookings.msw_flights;

-- task 4
--Изучить тему временных таблиц - сделать все возможные операции с ней 
--(создать, заполнить, сджойнить, удалить) 

-- 1. Создание временной таблицы
CREATE TEMPORARY TABLE temp_flights (
    flight_id SERIAL PRIMARY KEY,
    departure_airport VARCHAR(100),
    arrival_airport VARCHAR(100),
    scheduled_departure TIMESTAMP,
    actual_departure TIMESTAMP
);

-- 2. Заполнение временной таблицы
INSERT INTO temp_flights (departure_airport, arrival_airport, scheduled_departure, actual_departure)
VALUES
('DME', 'ROV', '2023-04-14 10:05:00', '2023-04-14 10:05:00'),
('DME', 'UUS', '2024-05-28 12:22:00', NULL),
('VKO', 'PEE', '2025-12-05 14:40:00', '2025-12-05 14:45:00');

select * from temp_flights;

-- 3. Объединение временной таблицы с другой таблицей
SELECT f.flight_id, f.departure_airport, f.arrival_airport
FROM temp_flights tf
JOIN bookings.flights f ON tf.flight_id = f.flight_id
WHERE tf.actual_departure IS NOT NULL;

-- 4. Удаление временной таблицы
DROP TABLE IF EXISTS temp_flights;