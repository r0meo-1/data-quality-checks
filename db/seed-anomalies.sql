-- «Грязный» набор данных для демонстрации: содержит типичные дефекты целостности,
-- которые ловят проверки из checks/. В CI проверяется после чистого baseline.
--
-- Применение:
--   psql "$DATABASE_URL" -f db/schema.sql
--   psql "$DATABASE_URL" -f db/seed-anomalies.sql
--   bash scripts/run_checks.sh   # покажет нарушения

INSERT INTO customers (id, full_name, email, phone, created_at) VALUES
    (1, 'Иван Петров',    'ivan@example.com',  '+79110000001', '2025-01-10 09:00:00'),
    (2, 'Иван Петров',    'IVAN@example.com ', '+79110000001', '2025-01-11 09:00:00'), -- дубль email
    (3, 'Ольга Смирнова', 'olga@example.com',  '+79110000004', '2025-02-03 16:45:00');

INSERT INTO tours (id, title, country, price, seats_total) VALUES
    (1, 'Анталья, 7 ночей', 'Турция', 85000.00, 30),
    (2, 'Бутик-тур',        'Италия', 250000.00, 2);

INSERT INTO bookings (id, customer_id, tour_id, status, pax, amount, created_at) VALUES
    (1, 1,   1,   'paid',      2, 170000.00, '2025-03-01 10:00:00'), -- mismatch: оплачено меньше
    (2, 1,   1,   'paid',      2, 170000.00, '2025-03-02 10:00:00'), -- paid без succeeded платежа
    (3, 3,   2,   'confirmed', 5, 500000.00, '2025-03-03 10:00:00'), -- invalid status + pax > seats
    (4, 99,  1,   'new',       1,  85000.00, '2025-03-04 10:00:00'), -- orphan: нет клиента 99
    (5, 3,   1,   'refunded',  1,  85000.00, '2025-03-05 10:00:00'), -- refunded без refund-платежа
    (6, 3,   1,   'new',       1,      0.00, '2099-01-01 10:00:00'); -- нулевая сумма + дата в будущем

INSERT INTO payments (id, booking_id, amount, status, paid_at) VALUES
    (1, 1,   90000.00, 'succeeded', '2025-03-01 10:05:00'),  -- меньше суммы заявки (170000)
    (2, 2,  170000.00, 'failed',    '2025-03-02 10:05:00'),  -- не succeeded
    (3, 777, 50000.00, 'succeeded', '2025-03-02 11:00:00');  -- orphan: нет заявки 777
