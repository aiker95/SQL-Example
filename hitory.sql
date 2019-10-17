/*
|*| Триггерная функция создания записей
|*| в таблице: "History", в которых хранится
|*| информация о изменениях БД.
*/
DECLARE				--|*|Объявляем переменные
col character varying[];	--|*|Массив для хранения названий столбцов изменяемой таблицы;
max_ctr integer;		--|*|Хранит размер массива "col";
_old_value character varying;	--|*|Для хранения старого значения поля изменяемой записи;
_new_value character varying;	--|*|Для хранения старого значения поля изменяемой записи;
_field_uuid character varying;	--|*|Для хранения UUIDа изменяемой записи.
BEGIN 
							--|*|Наполняем массив "col"
col:= (SELECT ARRAY(select a.attname  as colname  from pg_catalog.pg_attribute a inner join pg_catalog.pg_class c on a.attrelid = c.oid
where    c.relname = TG_TABLE_NAME
      	and a.attnum > 0
      	and a.attisdropped=false));  
							--|*|Узнаём сколько столбцов в таблице
max_ctr := array_length(col, 1);
							--|*|Сохраняем uuid строки
EXECUTE format('SELECT ($1).%s::text', col[1])
USING OLD INTO _field_uuid;		
							--|*|Цикл проверки обновления каждого столбца	
FOR ctr IN 2..max_ctr LOOP 	--|*|Начинаем со 2 столбца (1-й всегда UUID)
	IF (TG_OP = 'UPDATE') THEN
								--|*|Сохраняем старое значение столбца
	EXECUTE format('SELECT ($1).%s::text', col[ctr])
	USING OLD INTO _old_value; 
								--|*|Сохраняем новое значение столбца
	EXECUTE format('SELECT ($1).%s::text', col[ctr])
	USING NEW INTO _new_value; 
								--|*|Проверяем поля
		IF (ctr  <= max_ctr-3) THEN			--|*|Изменено поле данных
			IF  (_new_value is NULL)	THEN 	--|*|Если обнулилось
				 IF (_old_value is not null) THEN	--|*|и старое значение не нулевое, то создаём запись.
					INSERT INTO history.history(name_table, uuid_field, field_name, update_at, user_id, value, type) VALUES 
					(TG_TABLE_NAME, _field_uuid, col[ctr],        
					(SELECT now()), (SELECT user),	_old_value, 'Очищение');
				END IF;
										--|*|Если не обнулилось
			ELSE							--|*|Проверяем обновилось ли поле в столбце
				 IF (_old_value is null) THEN 	--|*|Если старое поле пустое
					INSERT INTO history.history (name_table, uuid_field, field_name, update_at, user_id, value, type)VALUES
					(TG_TABLE_NAME, _field_uuid, col[ctr],          
					(SELECT now()), (SELECT user),	_old_value, 'Изменение');
				 ELSE							--|*|Если старое не пустое
					IF (_old_value != _new_value) THEN 	--|*|и новое не совпадает со старым
						INSERT INTO history.history (name_table, uuid_field, field_name, update_at, user_id, value, type)VALUES
						(TG_TABLE_NAME, _field_uuid,col[ctr],          
						(SELECT now()), (SELECT user),	_old_value, 'Изменение');
					END IF;
				END IF;
			END IF;
		ELSIF (ctr  = max_ctr) THEN --|*|Изменено поле даты "Удаления записи"
			IF  (_new_value is null)	THEN --|*|Если обнулилось
				 IF (_old_value is not null) THEN	--|*|и старое значение не нулевое, то создаём запись.
					INSERT INTO history.history(name_table, uuid_field, field_name, update_at, user_id, value, type) VALUES 
					(TG_TABLE_NAME, _field_uuid, col[ctr],        
					(SELECT now()), (SELECT user),	_old_value, 'Востановление');
				END IF;
										--|*|Если не обнулилось
			ELSE							--|*|Проверяем обновилось ли поле в столбце
				 IF (_old_value is null) THEN 	--|*|Если старое поле пустое
					INSERT INTO history.history (name_table, uuid_field, field_name, update_at, user_id, value, type)VALUES
					(TG_TABLE_NAME, _field_uuid, col[ctr],          
					(SELECT now()), (SELECT user),	_old_value, 'Уничтожение');
				END IF;
			END IF;
		END IF;				 
	END IF;	
END LOOP;
RETURN NEW;
END;
