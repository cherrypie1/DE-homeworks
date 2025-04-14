CREATE TABLE authors (
    author_id INT PRIMARY KEY,
    full_name VARCHAR(120) NOT NULL,
    birth_year INT,
    country VARCHAR(50),
    biography TEXT
);

CREATE TABLE books (
    book_id INT PRIMARY KEY,
    title VARCHAR(130) NOT NULL,
    publication_year INT,
    author_id INT,
    available_copies INT,
    status VARCHAR(50),
    FOREIGN KEY (author_id) REFERENCES authors(author_id)
);

CREATE TABLE readers (
    reader_id INT PRIMARY KEY,
    full_name VARCHAR(120) NOT NULL,
    ticket_number VARCHAR(50),
    registration_date DATE,
    contact_phone VARCHAR(20),
    email VARCHAR(100)
);

INSERT INTO authors (author_id, full_name, birth_year, country, biography) VALUES
(1, 'abcd', 1888, 'Россия', 'bcd'),
(2, 'efgh', 1821, 'Россия', 'fgt'),
(3, 'fdgsr', 1812, 'Великобритания', ' hgfxvb'),
(4, 'iokghhcv', 1999, 'Беларусь', 'igfgghttfrg'),
(5, 'dftkil', 1987, 'Великобритания', 'kjhgmghb');

INSERT INTO books (book_id, title, publication_year, author_id, available_copies, status) VALUES
(1, 'lllll', 1869, 1, 5, 'доступна'),
(2, 'uuuuu', 1866, 2, 2, 'на руках'),
(3, 'ttttt', 1837, 3, 3, 'доступна'),
(4, 'bbbbb', 1876, 4, 4, 'доступна'),
(5, 'vvvvv', 1813, 5, 1, 'в ремонте');

INSERT INTO readers (reader_id, full_name, ticket_number, registration_date, contact_phone, email) VALUES
(1, 'Иван Иванов', '0001', '2025-01-15', '+375 29 111 11 11', 'ivan@example.com'),
(2, 'Петр Петров', '0002', '2025-02-20', '+375 33 222 22 22', 'petr@gmail.com'),
(3, 'Сергей Сергеевич', '0003', '2025-03-10', '+375 44 333 33 33', 'sergey@yandex.com'),
(4, 'Анна Смирнова', '0004', '2025-01-25', '+375 17 444 44 44', 'anna@example.com'),
(5, 'Ольга Смирнова', '0005', '2025-04-01', '+375 29 555 55 55', 'olga@example.com');


SELECT * FROM books WHERE author_id = 2;


SELECT * FROM books WHERE status = 'доступна';


SELECT * FROM readers WHERE registration_date BETWEEN '2025-01-01' AND '2025-03-31';