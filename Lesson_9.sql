/* Практическое задание по теме “Транзакции, переменные, представления”*/

/* Задание 1: В базе данных shop и sample присутствуют одни и те же таблицы, учебной базы данных. Переместите запись id = 1 из таблицы shop.users в таблицу sample.users. Используйте транзакции.*/

START TRANSACTION;
INSERT INTO sample.users (SELECT * FROM shop.users WHERE shop.users.id = 1);
COMMIT;

/* Задание 2: Создайте представление, которое выводит название name товарной позиции из таблицы products и соответствующее название каталога name из таблицы catalogs.*/

CREATE VIEW products_catalogs AS
	SELECT p.name AS product_name, c.name AS catalog_name
FROM products AS p
LEFT JOIN catalogs AS c
	ON p.catalog_id = c.id;
	
SELECT * FROM products_catalogs;

/* Задание 3: по желанию) Пусть имеется таблица с календарным полем created_at. В ней размещены разряженые календарные записи за август 2018 года '2018-08-01', '2016-08-04', '2018-08-16' и 2018-08-17. Составьте запрос, который выводит полный список дат за август, выставляя в соседнем поле значение 1, если дата присутствует в исходном таблице и 0, если она отсутствует.*/

-- Создадим и заполним таблицу tabl_aug

DROP TABLE IF EXISTS tabl_aug;
CREATE TABLE tabl_aug (
  id SERIAL PRIMARY KEY,
  created_at DATE);  
  
INSERT INTO tabl_aug VALUES
  (NULL, '2018-08-01'), (NULL, '2018-08-04'), (NULL, '2018-08-16'), (NULL, '2018-08-17');
  
SELECT * FROM tabl_aug;  

-- Создадим и заполним временную таблицу, состоящую из количества строк, соответствующего количеству дней в августе месяце

CREATE TEMPORARY TABLE aug_days (days INT);

INSERT INTO aug_days VALUES 
	(1), (2), (3), (4), (5), (6), (7), (8), (9), (10), 
	(11), (12),(13),(14), (15), (16), (17), (18), (19), (20),
	(21), (22), (23), (24), (25), (26), (27), (28), (29), (30), (31);
                            
-- создадим переменную, от которой начнётся отсчёт - последний день июля
                            
SET @start_aug = '2018-07-31';

-- Теперь делаем запрос

SELECT @start_aug + INTERVAL DAYS day AS august_month,
	   CASE WHEN tabl_aug.created_at is NULL THEN 0 ELSE 1 END AS value FROM aug_days
LEFT JOIN tabl_aug ON @start_aug + INTERVAL DAYS day = tabl_aug.created_at
ORDER BY august_month;	

/* Задание 4: (по желанию) Пусть имеется любая таблица с календарным полем created_at. Создайте запрос, который удаляет устаревшие записи из таблицы, оставляя только 5 самых свежих записей.*/

-- для решения создадим и заполним таблицу selection

DROP TABLE IF EXISTS selections;
CREATE TABLE selections(
	id SERIAL,
    created_at DATETIME DEFAULT NOW()
    );
 
 INSERT INTO `selections` VALUES   
('1','1999-10-14 18:47:39'),
('2','2021-09-04 16:08:30'),
('3','2015-07-10 22:07:03'),
('4','1991-05-12 20:32:08'),
('5','1978-09-10 14:36:01'),
('6','1992-04-15 01:27:31'),
('7','2003-02-03 04:56:27'),
('8','2017-04-24 09:30:19'),
('9','2020-02-07 20:53:55'),
('10','1973-05-11 03:21:40');     

-- Решение

PREPARE del_rows FROM "DELETE FROM selections ORDER BY created_at LIMIT ?"; 
SET @date = (SELECT COUNT(*)-5 FROM selections);
EXECUTE del_rows USING @date;

SELECT * FROM selections;


/* Практическое задание по теме “Администрирование MySQL” (эта тема изучается по вашему желанию)*/


/* Задание 1: Создайте двух пользователей которые имеют доступ к базе данных shop. Первому пользователю shop_read должны быть доступны только запросы на чтение данных, второму пользователю shop — любые операции в пределах базы данных shop.*/

USE shop;

-- создадим юзера shop_read, которому доступны только запросы на чтение данных с локального хоста

DROP USER IF EXISTS 'shop_read'@'localhost';
CREATE USER 'shop_read'@'localhost';
GRANT SELECT ON shop.* TO 'shop_read'@'localhost';

-- создадим юзера shop, которому доступны все операции в пределах базы данных shop с подключением к серверу с помощью учетной записи, которая аутентифицируется с помощью sha256_passwordплагина

DROP USER IF EXISTS 'shop'@'localhost';
CREATE USER 'shop'@'localhost' IDENTIFIED WITH sha256_password BY '123';
GRANT ALL ON shop.* TO 'shop'@'localhost';


-- запрос на обновление привилегий пользователей

FLUSH PRIVILEGES;

-- при проверке прав пользователей запросом, который приведён ниже, почему-то у созданных юзеров не применяются права

SELECT * FROM information_schema.user_privileges;

mysql> SELECT * FROM information_schema.user_privileges;
+--------------------------------+---------------+-------------------------+--------------+
| GRANTEE                        | TABLE_CATALOG | PRIVILEGE_TYPE          | IS_GRANTABLE |
+--------------------------------+---------------+-------------------------+--------------+
| 'root'@'localhost'             | def           | SELECT                  | YES          |
| 'root'@'localhost'             | def           | INSERT                  | YES          |
| 'root'@'localhost'             | def           | UPDATE                  | YES          |
| 'root'@'localhost'             | def           | DELETE                  | YES          |
| 'root'@'localhost'             | def           | CREATE                  | YES          |
| 'root'@'localhost'             | def           | DROP                    | YES          |
| 'root'@'localhost'             | def           | RELOAD                  | YES          |
| 'root'@'localhost'             | def           | SHUTDOWN                | YES          |
| 'debian-sys-maint'@'localhost' | def           | EVENT                   | YES          |
| 'debian-sys-maint'@'localhost' | def           | TRIGGER                 | YES          |
| 'debian-sys-maint'@'localhost' | def           | CREATE TABLESPACE       | YES          |
| 'shop'@'localhost'             | def           | USAGE                   | NO           |
| 'shop_reader'@'localhost'      | def           | USAGE                   | NO           |
+--------------------------------+---------------+-------------------------+--------------+
60 rows in set (0.00 sec)


-- поэтому создала ещё запрос на просмотр прав созданных пользователей

SHOW GRANTS FOR 'shop'@'localhost';
SHOW GRANTS FOR 'shop_reader'@'localhost';

/* Задание 2: (по желанию) Пусть имеется таблица accounts содержащая три столбца id, name, password, содержащие первичный ключ, имя пользователя и его пароль. Создайте представление username таблицы accounts, предоставляющий доступ к столбца id и name. Создайте пользователя user_read, который бы не имел доступа к таблице accounts, однако, мог бы извлекать записи из представления username.*/

USE shop;

-- создаём таблицу accounts
 
DROP TABLE IF EXISTS accounts;
CREATE TABLE accounts (
	id SERIAL PRIMARY KEY,
	name VARCHAR(45),
	password VARCHAR(45)
);

-- заполним таблицу 

INSERT INTO accounts (name, password) VALUES
	('Matrena', 'IHd2jd3nd8uU'),
	('Klava', '5fgh7JklO4P'),
	('Ivan', 'yU6thd4KL9'),
	('Matvey', 'fF6fk15BB8djd'),
	('Roman',  '12jfdyhfnIOd4'),
	('Nina', 'hf3Yidm889TsjX');


-- создаём представление

DROP VIEW IF EXISTS username;
CREATE OR REPLACE VIEW username(user_id, user_name) AS 
	SELECT id, name FROM accounts;
	
	
-- Создаем пользователя 'user_read'@'localhost'

DROP USER IF EXISTS 'user_read'@'localhost';
CREATE USER 'user_read'@'localhost' IDENTIFIED WITH sha256_password BY '123';
GRANT SELECT ON shop.username TO 'user_read'@'localhost';


-- в таблице accounts мы не видим созданного юзера, из чего делаем вывод, что доступа к этой таблице не имеет
SELECT * FROM accounts;
SELECT * FROM username;

-- но можем увидеть этого пользователя, если сделаем запрос на вывод его прав
SHOW GRANTS FOR 'user_read'@'localhost';


/*Практическое задание по теме “Хранимые процедуры и функции, триггеры"*/

/* Задание 1: Создайте хранимую функцию hello(), которая будет возвращать приветствие, в зависимости от текущего времени суток. С 6:00 до 12:00 функция должна возвращать фразу "Good morning", с 12:00 до 18:00 функция должна возвращать фразу "Good afternoon", с 18:00 до 00:00 — "Good evening", с 00:00 до 6:00 — "Good night".*/

USE shop;

DELIMITER //
DROP FUNCTION IF EXISTS hello//
CREATE FUNCTION hello ()
RETURNS VARCHAR(255) DETERMINISTIC
BEGIN
	DECLARE time_day TIME default CURTIME();	
	CASE 
		WHEN time_day BETWEEN '06:00:00' AND '12:00:00' THEN
			RETURN 'Good morning';
		WHEN time_day BETWEEN '12:00:00' AND '18:00:00' THEN
			RETURN 'Good afternoon';
		WHEN time_day BETWEEN '18:00:00' AND '00:00:00' THEN
			RETURN 'Good evening';
		ELSE
			RETURN 'Good night';		
	END CASE;
END//
DELIMITER ;
SELECT hello();


/* Задание 2: В таблице products есть два текстовых поля: name с названием товара и description с его описанием. Допустимо присутствие обоих полей или одно из них. Ситуация, когда оба поля принимают неопределенное значение NULL неприемлема. Используя триггеры, добейтесь того, чтобы одно из этих полей или оба поля были заполнены. При попытке присвоить полям NULL-значение необходимо отменить операцию.*/

USE shop;

DROP TRIGGER IF EXISTS trig_null;
delimiter //
CREATE TRIGGER trig_null BEFORE INSERT ON products
FOR EACH ROW
BEGIN
	IF(ISNULL(NEW.name) AND ISNULL(NEW.description)) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The operation is stopped, a NULL value is detected !'; -- Предупреждение о том, что операция остановлена, т.к. обнаружено значение NULL
	END IF;
END //
delimiter ;

INSERT INTO products (name, desription) VALUES
(NULL, 'Processor for desktop computers based on the platform Intel.');
INSERT INTO products (name, desription) VALUES
(NULL, NULL);
INSERT INTO products (name, desription) VALUES
('Intel Core i5-7400', NULL);


/* Задание 3: (по желанию) Напишите хранимую функцию для вычисления произвольного числа Фибоначчи. Числами Фибоначчи называется последовательность в которой число равно сумме двух предыдущих чисел. Вызов функции FIBONACCI(10) должен возвращать число 55.*/

DELIMITER //
DROP FUNCTION IF EXISTS FIBONACCI//
CREATE FUNCTION FIBONACCI(num INT)
RETURNS INT DETERMINISTIC
BEGIN
	DECLARE fs DOUBLE;
	SET fs = SQRT(5);
	RETURN (POW((1 + fs)/2.0, num) + POW((1 - fs)/2.0, num))/fs;
END//
DELIMITER ;

SELECT FIBONACCI(10);
