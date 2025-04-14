--Задача 1: Анализ распределения мест в самолетах
--- Необходимо проанализировать распределение мест в самолетах по классам обслуживания. Рассчитать:
--- Общее количество мест в каждом самолете
--- Количество мест каждого класса
--- Процентное соотношение классов
--- Массив всех мест для каждого самолета

SELECT 
    s.aircraft_code,
    COUNT(s.seat_no) AS total_seats,
    SUM(CAST(s.fare_conditions = 'Economy' AS INTEGER)) AS econ_seats,
    SUM(CAST(s.fare_conditions = 'Business' AS INTEGER)) AS bus_seats,
    SUM(CAST(s.fare_conditions = 'Comfort' AS INTEGER)) AS com_seats,
    ARRAY_AGG(s.seat_no) AS all_seats,
    ROUND((SUM(CAST(s.fare_conditions = 'Economy' AS INTEGER)) * 100.0 / COUNT(s.seat_no)), 2) AS economy_percent,
    ROUND((SUM(CAST(s.fare_conditions = 'Business' AS INTEGER)) * 100.0 / COUNT(s.seat_no)), 2) AS business_percent,
    ROUND((SUM(CAST(s.fare_conditions = 'Comfort' AS INTEGER)) * 100.0 / COUNT(s.seat_no)), 2) AS comfort_percent
FROM 
    bookings.seats s
GROUP BY 
    s.aircraft_code;

--Задача 2: Анализ стоимости билетов по рейсам
--Для каждого рейса рассчитать:
--- Минимальную, максимальную и среднюю стоимость билета
--- Разницу между самым дорогим и самым дешевым билетом
--- Медианную стоимость билета
--- Массив всех цен на билеты
  
SELECT 
    flight_id,
    MIN(amount) AS min_price,
    MAX(amount) AS max_price,
    AVG(amount) AS avg_price,
    MAX(amount) - MIN(amount) AS price_diff,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY amount) AS median_price,
    ARRAY_AGG(amount ORDER BY amount) AS prices_array
FROM 
    bookings.ticket_flights 
GROUP BY 
    flight_id;

--Задача 3: Статистика по бронированиям по месяцам
--- Проанализировать бронирования по месяцам:
--- Количество бронирований
--- Общую сумму бронирований
--- Средний чек
--- Массив всех сумм бронирований для анализа распределения

SELECT 
    DATE_TRUNC('month', b.book_date) AS booking_month,
    COUNT(b.book_ref) AS total_bookings,
    SUM(b.total_amount) AS total_revenue,
    ROUND(AVG(b.total_amount),2) AS average_check,
    ARRAY_AGG(b.total_amount ORDER BY b.total_amount) AS booking_amounts_array
FROM 
    bookings.bookings b
GROUP BY 
    booking_month


--Задача 4: Анализ пассажиропотока по аэропортам
--- Рассчитать для каждого аэропорта:
--- Общее количество вылетов
--- Количество уникальных аэропортов назначения
--- Массив всех аэропортов назначения
SELECT 
    departure_airport,
    COUNT(flight_id) as flights_amount,
    COUNT(DISTINCT arrival_airport ) AS uniq_arr,
    ARRAY_AGG(DISTINCT arrival_airport ORDER BY arrival_airport) AS airports_array
FROM 
    bookings.flights
GROUP BY 
    departure_airport
ORDER BY 
    departure_airport;


