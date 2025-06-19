--задание 23:
--Задача 1:
--Необходимо оптимизировать выборку данных по номеру места (bookings.boarding_passes.seat_no) 
--с помощью индекса и сравнить результаты до добавления индекса и после (время выполнения и объем таблицы в %)

EXPLAIN ANALYZE --50-80ms,80M без индекса; 2-4ms,84M с индексом ускорилось на 95.3% и на 5% больше занимает
SELECT * 
FROM bookings.boarding_passes 
WHERE seat_no = '10B';

CREATE INDEX idx_boarding_passes_seat_no ON bookings.boarding_passes (seat_no);

DROP INDEX bookings.idx_boarding_passes_seat_no;

--Задача 2:
--1. Проанализировать производительность запроса без индексов.


 --100-200ms без индекса; 0.5-3ms с индексом ускорилось на 98.8%
EXPLAIN ANALYZE 
SELECT bp.boarding_no, t.passenger_id
FROM bookings.boarding_passes bp
JOIN bookings.tickets t ON bp.ticket_no = t.ticket_no
JOIN bookings.seats s ON bp.seat_no = s.seat_no
JOIN bookings.bookings b ON t.book_ref = b.book_ref
WHERE 
  t.passenger_id IN ('0856 579180', '4723 695013')
  AND bp.boarding_no < 100;

--2. Добавить индексы для ускорения JOIN и фильтрации.

CREATE INDEX idx_tickets_ticket_no ON bookings.tickets (ticket_no);
CREATE INDEX idx_seats_seat_no ON bookings.seats (seat_no); 
CREATE INDEX idx_boarding_passes_boarding_no ON bookings.boarding_passes (boarding_no);
CREATE INDEX idx_tickets_passenger_id ON bookings.tickets (passenger_id);

DROP INDEX bookings.idx_tickets_ticket_no;
DROP INDEX bookings.idx_seats_seat_no;
DROP INDEX bookings.idx_boarding_passes_boarding_no;
DROP INDEX bookings.idx_tickets_passenger_id;
