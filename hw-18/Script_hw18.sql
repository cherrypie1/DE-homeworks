-- Задача 1: Вывести аэропорты, из которых выполняется менее 50 рейсов

select 
	a.airport_name,
	f.departure_airport,
	count(f.flight_no) as flights_count
from bookings.airports a 
inner join bookings.flights f on f.departure_airport = a.airport_code
group by f.departure_airport, a.airport_name
having count(f.flight_no) < 50 
;


-- Задача 2: Вывести среднюю стоимость билетов для каждого маршрута (город вылета - город прилета)

select 
	a_dep.city as departure_city,
	a_arr.city as arrival_city,
	round(avg(tf.amount), 2) as avg_cost_RUB
from bookings.ticket_flights tf 
inner join bookings.flights f on f.flight_id = tf.flight_id
inner join bookings.airports a_dep on a_dep.airport_code = f.departure_airport
inner join bookings.airports a_arr on a_arr.airport_code = f.arrival_airport
group by departure_city, arrival_city;