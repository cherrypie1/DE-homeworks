--Задание 3.1: Анализ задержек рейсов по аэропорту
--Задача: Для указанного аэропорта (по коду аэропорта) 
--вывести статистику задержек.
--Таблица: flights
SELECT 
    departure_airport,
    ROUND(AVG(EXTRACT(EPOCH FROM (actual_departure - scheduled_departure))),2) AS avg_delay,
    MAX(EXTRACT(EPOCH FROM (actual_departure - scheduled_departure))) AS max_delay,
    MIN(EXTRACT(EPOCH FROM (actual_departure - scheduled_departure))) AS min_delay
FROM 
    bookings.flights
WHERE 
    departure_airport = 'PEE' 
    AND actual_departure IS NOT NULL
GROUP BY 
    departure_airport;

--Задание 3.2: Обернуть в функцию c вводом кода аэропорта
CREATE OR REPLACE FUNCTION bookings.delays_stat(airport_code bpchar)
RETURNS TABLE (
	departure_airport bpchar,
    avg_delay NUMERIC,
    max_delay NUMERIC,
    min_delay NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
		f.departure_airport,
        ROUND(AVG(EXTRACT(EPOCH FROM (f.actual_departure - f.scheduled_departure))),2) AS avg_delay,
        MAX(EXTRACT(EPOCH FROM (f.actual_departure - f.scheduled_departure))) AS max_delay,
        MIN(EXTRACT(EPOCH FROM (f.actual_departure - f.scheduled_departure))) AS min_delay
    FROM 
        bookings.flights f
    WHERE 
        f.departure_airport = delays_stat.airport_code
        AND f.arrival_airport IS NOT NULL
    GROUP BY 
        f.departure_airport;
END;
$$ LANGUAGE plpgsql;


select * from bookings.delays_stat('PEE'); 

--Задание 4.1: Рейсы с заполняемостью выше средней
--Задача: Найти рейсы, где количество проданных билетов превышает
--среднее по всем рейсам.
--Таблица: flights

SELECT 
    f.flight_id,
    f.departure_airport,
    f.arrival_airport,
    COUNT(tf.ticket_no) AS tickets_sold
FROM 
    bookings.ticket_flights tf
JOIN 
    bookings.flights f ON f.flight_id = tf.flight_id
GROUP BY 
    f.flight_id, f.departure_airport, f.arrival_airport
HAVING 
    COUNT(ticket_no) > (
        SELECT AVG(ticket_count)
        FROM (
            SELECT COUNT(ticket_no) AS ticket_count
            FROM bookings.ticket_flights
            GROUP BY flight_id
        ) AS avg_tickets
    );

--Задание 4.2: Создать функцию с вводом параметра минимального процента 
--заполняемости и выводом всех рейсов удовлетворяющих этому проценту
CREATE OR REPLACE FUNCTION bookings.flights_above_fill_rate(capacity numeric, min_fill_rate NUMERIC) --capacity(вместительность самолета)min_fill_rate(минимальный процент заполненности)
RETURNS TABLE (
    flight_id INT,
    departure_airport CHAR(3),  
    arrival_airport CHAR(3),  
    fill_rate NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        f.flight_id,  
        f.departure_airport,
        f.arrival_airport,
        ROUND((COUNT(tf.ticket_no) * 100.0 / capacity),2) AS fill_rate_percent  
    FROM 
        bookings.flights f
    LEFT JOIN 
        bookings.ticket_flights tf ON f.flight_id = tf.flight_id
    GROUP BY 
        f.flight_id, f.departure_airport, f.arrival_airport
    HAVING 
        (COUNT(tf.ticket_no) * 100.0 / capacity) > min_fill_rate; 
END;
$$ LANGUAGE plpgsql;

select * from bookings.flights_above_fill_rate(254, 45); --для вместимости самолета было выбрано 254 мест, такое количество билетов было продано на рейс flight_id = 3 495 

DROP FUNCTION bookings.flights_above_fill_rate(numeric, numeric);

--Доп. задание: Посмотреть циклы foreach и while в функциях
CREATE OR REPLACE FUNCTION bookings.flights_fill_rate(flight_ids INT[])
RETURNS TABLE (
    flight_id INT,
    fill_rate NUMERIC
) AS $$
DECLARE
    current_flight_id INT;
BEGIN
    FOREACH current_flight_id IN ARRAY flight_ids                          --foreach
    LOOP
        RETURN QUERY
        SELECT 
            f.flight_id,
            ROUND((COUNT(tf.ticket_no) * 100.0 / 158), 2) AS fill_rate
        FROM 
            bookings.flights f
        LEFT JOIN 
            bookings.ticket_flights tf ON f.flight_id = tf.flight_id
        WHERE 
            f.flight_id = current_flight_id
        GROUP BY 
            f.flight_id;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

select * from bookings.flights_fill_rate(ARRAY[26264,5468,8057]);


CREATE OR REPLACE FUNCTION bookings.flights_fill_rates(flight_ids INT[])
RETURNS TABLE (
    flight_id INT,
    fill_rate NUMERIC
) AS $$
DECLARE
    current_index INT := 1;  
    current_flight_id INT;    
BEGIN
    WHILE current_index <= array_length(flight_ids, 1) LOOP             --while
        current_flight_id := flight_ids[current_index];  

        RETURN QUERY
        SELECT 
            f.flight_id,
            ROUND((COUNT(tf.ticket_no) * 100.0 / 158), 2) AS fill_rate
        FROM 
            bookings.flights f
        LEFT JOIN 
            bookings.ticket_flights tf ON f.flight_id = tf.flight_id
        WHERE 
            f.flight_id = current_flight_id
        GROUP BY 
            f.flight_id;

        current_index := current_index + 1;  
    END LOOP;
END;
$$ LANGUAGE plpgsql;


select * from bookings.flights_fill_rates(ARRAY[26264,5468,8057]);
