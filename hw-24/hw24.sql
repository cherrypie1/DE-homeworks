--Задача 1: Анализ частоты полетов пассажиров
--Определить топ-10 пассажиров, которые чаще всего летают.
--Провести оптимизацию скрипта по необходимости
EXPLAIN ANALYZE
SELECT 
	t.passenger_id,
	count(tf.flight_id) AS flights_count
FROM bookings.tickets t 
JOIN bookings.ticket_flights tf ON tf.ticket_no = t.ticket_no
GROUP BY t.passenger_id
ORDER BY flights_count DESC
LIMIT 10;

--Limit  (cost=142472.10..142472.13 rows=10 width=20) (actual time=8743.790..8743.851 rows=10 loops=1)
--  ->  Sort  (cost=142472.10..143388.94 rows=366733 width=20) (actual time=8552.546..8552.606 rows=10 loops=1)
--        Sort Key: (count(tf.flight_id)) DESC
--        Sort Method: top-N heapsort  Memory: 26kB
--        ->  HashAggregate  (cost=120667.64..134547.14 rows=366733 width=20) (actual time=7986.070..8452.083 rows=366733 loops=1)
--              Group Key: t.passenger_id
--              Planned Partitions: 8  Batches: 9  Memory Usage: 8273kB  Disk Usage: 31840kB
--              ->  Hash Join  (cost=16934.49..53675.82 rows=1045726 width=16) (actual time=1443.222..7072.789 rows=1045726 loops=1)
--                    Hash Cond: (tf.ticket_no = t.ticket_no)
--                    ->  Seq Scan on ticket_flights tf  (cost=0.00..19233.26 rows=1045726 width=18) (actual time=0.590..3649.780 rows=1045726 loops=1)
--                    ->  Hash  (cost=9843.33..9843.33 rows=366733 width=26) (actual time=1430.443..1430.445 rows=366733 loops=1)
--                          Buckets: 131072  Batches: 4  Memory Usage: 6244kB
--                          ->  Seq Scan on tickets t  (cost=0.00..9843.33 rows=366733 width=26) (actual time=5.703..892.273 rows=366733 loops=1)
--Planning Time: 31.509 ms
--JIT:
--  Functions: 18
--  Options: Inlining false, Optimization false, Expressions true, Deforming true
--  Timing: Generation 30.783 ms, Inlining 0.000 ms, Optimization 40.184 ms, Emission 157.962 ms, Total 228.930 ms
--Execution Time: 8811.503 ms

CREATE INDEX idx_tickets_ticket_no ON bookings.tickets (ticket_no);
CREATE INDEX idx_ticket_flights_ticket_no ON bookings.ticket_flights (ticket_no);
CREATE INDEX idx_tickets_passenger_id ON bookings.tickets (passenger_id);

--Limit  (cost=142472.10..142472.13 rows=10 width=20) (actual time=2530.813..2530.821 rows=10 loops=1)
--  ->  Sort  (cost=142472.10..143388.94 rows=366733 width=20) (actual time=2509.724..2509.729 rows=10 loops=1)
--        Sort Key: (count(tf.flight_id)) DESC
--        Sort Method: top-N heapsort  Memory: 26kB
--        ->  HashAggregate  (cost=120667.64..134547.14 rows=366733 width=20) (actual time=2033.753..2426.442 rows=366733 loops=1)
--              Group Key: t.passenger_id
--              Planned Partitions: 8  Batches: 9  Memory Usage: 8273kB  Disk Usage: 31840kB
--              ->  Hash Join  (cost=16934.49..53675.82 rows=1045726 width=16) (actual time=212.920..1412.102 rows=1045726 loops=1)
--                    Hash Cond: (tf.ticket_no = t.ticket_no)
--                    ->  Seq Scan on ticket_flights tf  (cost=0.00..19233.26 rows=1045726 width=18) (actual time=0.024..207.001 rows=1045726 loops=1)
--                    ->  Hash  (cost=9843.33..9843.33 rows=366733 width=26) (actual time=210.159..210.160 rows=366733 loops=1)
--                          Buckets: 131072  Batches: 4  Memory Usage: 6244kB
--                          ->  Seq Scan on tickets t  (cost=0.00..9843.33 rows=366733 width=26) (actual time=0.091..75.493 rows=366733 loops=1)
--Planning Time: 0.769 ms
--JIT:
--  Functions: 18
--  Options: Inlining false, Optimization false, Expressions true, Deforming true
--  Timing: Generation 2.162 ms, Inlining 0.000 ms, Optimization 1.270 ms, Emission 24.265 ms, Total 27.697 ms
--Execution Time: 2540.922 ms

--8811.503 ms,109M(ticket_flights),59M(tickets) без индекса; 2540.922 ms,127M(ticket_flights),81M(tickets) с индексом
--Вывод: ускорилось примерно на 71.1%, затрачено памяти примерно 16.5%
drop index bookings.idx_tickets_ticket_no;
drop index bookings.idx_ticket_flights_ticket_no;
drop index bookings.idx_tickets_passenger_id;


--Задача 2 (усложнение задачи 5 из самостоятельного решения). Анализ загрузки самолетов по дням недели
--Определить, в какие дни недели самолеты загружены больше всего.

--Логика расчета. Шаги:
--- Используем данные о занятых местах (boarding_passes) и общем количестве мест (seats).
--- Группируем данные по дням недели.
--- Рассчитаем среднюю загрузку самолетов для каждого дня.
EXPLAIN ANALYZE
WITH total_seats AS (
    SELECT 
        aircraft_code, 
        COUNT(*) AS total_seats
    FROM bookings.seats
    GROUP BY aircraft_code
),
taken_seats AS (
    SELECT 
        tf.flight_id,
        COUNT(DISTINCT bp.seat_no) AS taken_seats
    FROM bookings.boarding_passes bp
    JOIN bookings.ticket_flights tf ON bp.ticket_no = tf.ticket_no
    GROUP BY tf.flight_id
),
aircraft_load AS (
    SELECT
        f.flight_id,
        f.scheduled_departure,
        ts.total_seats,
        COALESCE(os.taken_seats, 0) AS taken_seats,
        ROUND((COALESCE(os.taken_seats, 0)::NUMERIC / ts.total_seats) * 100, 2) AS load_percentage
    FROM bookings.flights f
    JOIN total_seats ts ON f.aircraft_code = ts.aircraft_code
    LEFT JOIN taken_seats os ON f.flight_id = os.flight_id
),
dow_load AS (
    SELECT 
        EXTRACT(DOW FROM f.scheduled_departure) AS day_of_week,
        ROUND(AVG(load_percentage), 2) AS avg_load_percentage
    FROM aircraft_load f
    GROUP BY EXTRACT(DOW FROM f.scheduled_departure)
)
SELECT 
    day_of_week, 
    avg_load_percentage
FROM dow_load
ORDER BY day_of_week;

--GroupAggregate  (cost=328404.15..329245.19 rows=10207 width=64) (actual time=7200.877..7242.220 rows=7 loops=1)
--  Group Key: (EXTRACT(dow FROM f.scheduled_departure))
--  ->  Sort  (cost=328404.15..328486.95 rows=33121 width=48) (actual time=7195.752..7201.475 rows=33121 loops=1)
--        Sort Key: (EXTRACT(dow FROM f.scheduled_departure))
--        Sort Method: quicksort  Memory: 2867kB
--        ->  Hash Join  (cost=310867.58..325917.52 rows=33121 width=48) (actual time=5934.540..7170.886 rows=33121 loops=1)
--              Hash Cond: (f.aircraft_code = ts.aircraft_code)
--              ->  Hash Right Join  (cost=310839.20..325678.45 rows=33121 width=20) (actual time=5896.882..7092.116 rows=33121 loops=1)
--                    Hash Cond: (tf.flight_id = f.flight_id)
--                    ->  GroupAggregate  (cost=309701.98..324349.44 rows=15191 width=12) (actual time=5880.322..7057.919 rows=15881 loops=1)
--                          Group Key: tf.flight_id
--                          ->  Sort  (cost=309701.98..314533.83 rows=1932741 width=7) (actual time=5880.127..6560.146 rows=1906184 loops=1)
--                                Sort Key: tf.flight_id, bp.seat_no
--                                Sort Method: external merge  Disk: 32960kB
--                                ->  Hash Join  (cost=20727.94..81477.39 rows=1932741 width=7) (actual time=322.812..1908.471 rows=1906184 loops=1)
--                                      Hash Cond: (tf.ticket_no = bp.ticket_no)
--                                      ->  Seq Scan on ticket_flights tf  (cost=0.00..19233.26 rows=1045726 width=18) (actual time=0.052..197.765 rows=1045726 loops=1)
--                                      ->  Hash  (cost=10084.86..10084.86 rows=579686 width=17) (actual time=321.068..321.070 rows=579686 loops=1)
--                                            Buckets: 131072  Batches: 8  Memory Usage: 4531kB
--                                            ->  Seq Scan on boarding_passes bp  (cost=0.00..10084.86 rows=579686 width=17) (actual time=0.011..106.162 rows=579686 loops=1)
--                    ->  Hash  (cost=723.21..723.21 rows=33121 width=16) (actual time=16.504..16.505 rows=33121 loops=1)
--                          Buckets: 65536  Batches: 1  Memory Usage: 2065kB
--                          ->  Seq Scan on flights f  (cost=0.00..723.21 rows=33121 width=16) (actual time=0.019..6.894 rows=33121 loops=1)
--              ->  Hash  (cost=28.27..28.27 rows=9 width=12) (actual time=37.490..37.492 rows=9 loops=1)
--                    Buckets: 1024  Batches: 1  Memory Usage: 9kB
--                    ->  Subquery Scan on ts  (cost=28.09..28.27 rows=9 width=12) (actual time=37.476..37.481 rows=9 loops=1)
--                          ->  HashAggregate  (cost=28.09..28.18 rows=9 width=12) (actual time=37.471..37.474 rows=9 loops=1)
--                                Group Key: seats.aircraft_code
--                                Batches: 1  Memory Usage: 24kB
--                                ->  Seq Scan on seats  (cost=0.00..21.39 rows=1339 width=4) (actual time=0.023..0.152 rows=1339 loops=1)
--Planning Time: 1.229 ms
--JIT:
--  Functions: 40
--  Options: Inlining false, Optimization false, Expressions true, Deforming true
--  Timing: Generation 3.155 ms, Inlining 0.000 ms, Optimization 1.601 ms, Emission 35.567 ms, Total 40.323 ms
--Execution Time: 7256.781 ms

CREATE INDEX idx_ticket_flights_ticket_no_flight_id
  ON bookings.ticket_flights (ticket_no, flight_id);
CREATE INDEX idx_boarding_passes_ticket_no_seat_no
  on bookings.boarding_passes (ticket_no, seat_no);
CREATE INDEX idx_flights_aircraft_code_flight_id_scheduled_departure
  ON bookings.flights (aircraft_code, flight_id, scheduled_departure);
CREATE INDEX idx_seats_aircraft_code
  ON bookings.seats (aircraft_code);

--GroupAggregate  (cost=328404.15..329245.19 rows=10207 width=64) (actual time=6027.777..6047.405 rows=7 loops=1)
--  Group Key: (EXTRACT(dow FROM f.scheduled_departure))
--  ->  Sort  (cost=328404.15..328486.95 rows=33121 width=48) (actual time=6025.408..6028.088 rows=33121 loops=1)
--        Sort Key: (EXTRACT(dow FROM f.scheduled_departure))
--        Sort Method: quicksort  Memory: 2867kB
--        ->  Hash Join  (cost=310867.58..325917.52 rows=33121 width=48) (actual time=5040.906..6012.522 rows=33121 loops=1)
--              Hash Cond: (f.aircraft_code = ts.aircraft_code)
--              ->  Hash Right Join  (cost=310839.20..325678.45 rows=33121 width=20) (actual time=4959.204..5908.342 rows=33121 loops=1)
--                    Hash Cond: (tf.flight_id = f.flight_id)
--                    ->  GroupAggregate  (cost=309701.98..324349.44 rows=15191 width=12) (actual time=4913.437..5851.408 rows=15881 loops=1)
--                          Group Key: tf.flight_id
--                          ->  Sort  (cost=309701.98..314533.83 rows=1932741 width=7) (actual time=4913.259..5452.016 rows=1906184 loops=1)
--                                Sort Key: tf.flight_id, bp.seat_no
--                                Sort Method: external merge  Disk: 32960kB
--                                ->  Hash Join  (cost=20727.94..81477.39 rows=1932741 width=7) (actual time=347.545..1661.445 rows=1906184 loops=1)
--                                      Hash Cond: (tf.ticket_no = bp.ticket_no)
--                                      ->  Seq Scan on ticket_flights tf  (cost=0.00..19233.26 rows=1045726 width=18) (actual time=0.092..184.166 rows=1045726 loops=1)
--                                      ->  Hash  (cost=10084.86..10084.86 rows=579686 width=17) (actual time=345.344..345.345 rows=579686 loops=1)
--                                            Buckets: 131072  Batches: 8  Memory Usage: 4531kB
--                                            ->  Seq Scan on boarding_passes bp  (cost=0.00..10084.86 rows=579686 width=17) (actual time=0.068..116.458 rows=579686 loops=1)
--                    ->  Hash  (cost=723.21..723.21 rows=33121 width=16) (actual time=45.536..45.536 rows=33121 loops=1)
--                          Buckets: 65536  Batches: 1  Memory Usage: 2065kB
--                          ->  Seq Scan on flights f  (cost=0.00..723.21 rows=33121 width=16) (actual time=0.055..20.570 rows=33121 loops=1)
--              ->  Hash  (cost=28.27..28.27 rows=9 width=12) (actual time=81.667..81.668 rows=9 loops=1)
--                    Buckets: 1024  Batches: 1  Memory Usage: 9kB
--                    ->  Subquery Scan on ts  (cost=28.09..28.27 rows=9 width=12) (actual time=81.640..81.649 rows=9 loops=1)
--                          ->  HashAggregate  (cost=28.09..28.18 rows=9 width=12) (actual time=81.630..81.636 rows=9 loops=1)
--                                Group Key: seats.aircraft_code
--                                Batches: 1  Memory Usage: 24kB
--                                ->  Seq Scan on seats  (cost=0.00..21.39 rows=1339 width=4) (actual time=0.039..0.345 rows=1339 loops=1)
--Planning Time: 2.028 ms
--JIT:
--  Functions: 40
--  Options: Inlining false, Optimization false, Expressions true, Deforming true
--  Timing: Generation 7.114 ms, Inlining 0.000 ms, Optimization 2.766 ms, Emission 77.855 ms, Total 87.735 ms
--Execution Time: 6061.396 ms

--7256.781 ms,80M(boarding_passes),4.8M(flights),109M(ticket_flights) без индекса; 6061.396 ms,103M(boarding_passes),5.8M(flights),149M(ticket_flights)
--Вывод: ускорилось примерно на 16.5%, затрачено памяти примерно 28.8%
DROP INDEX bookings.idx_ticket_flights_ticket_no_flight_id;
DROP INDEX bookings.idx_boarding_passes_ticket_no_seat_no;
DROP INDEX bookings.idx_flights_aircraft_code_flight_id_scheduled_departure;
DROP INDEX bookings.idx_seats_aircraft_code;


--Задача 3. Узнать что такое GroupAggregate и придумать пример имитации его

EXPLAIN ANALYZE
WITH taken_seats AS (
    SELECT 
        tf.flight_id,
        ARRAY_AGG(DISTINCT bp.seat_no) AS occupied_seats
    FROM 
        bookings.boarding_passes bp
    JOIN 
        bookings.ticket_flights tf ON bp.ticket_no = tf.ticket_no
    GROUP BY 
        tf.flight_id
)
SELECT 
    flight_id,
    occupied_seats
FROM 
    taken_seats;