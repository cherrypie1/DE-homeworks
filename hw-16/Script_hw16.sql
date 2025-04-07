-- Создание таблицы 
CREATE TABLE promocodes (
    promo_id INTEGER PRIMARY KEY AUTOINCREMENT,
    code VARCHAR(50) UNIQUE NOT NULL,
    discount_percent INT CHECK (discount_percent BETWEEN 1 AND 100),
    valid_from DATETIME DEFAULT current_timestamp,
    valid_to DATETIME NOT NULL,
    max_uses INTEGER,
    used_count INTEGER DEFAULT 0,
    is_active TINYINT DEFAULT 1,
    created_by INTEGER,
    FOREIGN KEY (created_by) REFERENCES users(id) 
);


-- Заполнение таблицы 
INSERT INTO promocodes (code, discount_percent, valid_from, valid_to, max_uses, created_by) 
VALUES
	('SUMMER10', 10, '2025-06-01', '2025-08-31', 100, 1),
	('WELCOME20', 20, '2026-01-01', '2026-12-31', NULL, 2),
	('BLACKFRIDAY30', 30, '2025-11-24', '2025-11-27', 500, 3),
	('NEWYEAR15', 15, '2025-12-20', '2025-01-10', 200, 4),
	('FLASH25', 25, '2025-04-01', '2025-10-07', 50, 5),
	('LOYALTY5', 5, '2024-01-01', '2024-02-01', NULL, 6),
	('MEGA50', 50, '2025-09-01', '2025-09-30', 10, 7),
	('AUTUMN20', 20, '2025-09-01', '2025-11-30', 300, 8),
	('SPRING10', 10, '2026-03-01', '2026-05-31', 150, 9),
	('VIP40', 40, '2023-07-01', '2023-07-31', 20, 10)
;

-- Анализ по группам скидок
SELECT 
    CASE 
        WHEN discount_percent BETWEEN 1 AND 10 THEN '1-10%'
        WHEN discount_percent BETWEEN 11 AND 20 THEN '11-20%'
        WHEN discount_percent BETWEEN 21 AND 30 THEN '21-30%'
        WHEN discount_percent BETWEEN 31 AND 40 THEN '31-40%'
        WHEN discount_percent BETWEEN 41 AND 50 THEN '41-50%'
        ELSE 'Unknown'
    END AS discount_range,
    COUNT(*) AS promo_count,
    MIN(discount_percent) AS min_discount,
    MAX(discount_percent) AS max_discount,
    COUNT(CASE WHEN max_uses IS NOT NULL THEN 1 END) AS limited_uses
FROM promocodes
GROUP BY discount_range
;

-- Анализ по времени действия
SELECT 
    CASE 
        WHEN DATE('now') BETWEEN valid_from AND valid_to THEN 'Активные'
        WHEN valid_to < DATE('now') THEN 'Истекшие'
        WHEN valid_from > DATE('now') THEN 'Не начавшиеся'
        ELSE 'Unknown'
    END AS promo_status,
    COUNT(*) AS promo_count,
    AVG(discount_percent) AS avg_discount,
    COUNT(CASE WHEN max_uses IS NOT NULL THEN 1 END) AS limited_uses
FROM promocodes
GROUP BY promo_status
;