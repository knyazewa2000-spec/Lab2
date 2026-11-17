-- 1. Выбрать все предметы одежды, которые невозможно применить к персонажам до 15 уровня.
SELECT i.*
FROM "Items" i
WHERE i.item_type ILIKE '%одеж%'
  AND EXISTS (
      SELECT 1
      FROM "Item_Usage" u
      WHERE u.item_id = i.item_cod
        AND u.is_usable = TRUE
        AND u.min_character_level > 15
  )
  AND NOT EXISTS (
      SELECT 1
      FROM "Item_Usage" u
      WHERE u.item_id = i.item_cod
        AND u.is_usable = TRUE
        AND u.min_character_level <= 15
  );


-- 2. Выбрать все щиты, относящиеся к редким предметам, которые можно обменять или продать.
SELECT *
FROM "Items"
WHERE item_type ILIKE '%щит%'
  AND rarity ILIKE '%редк%'
  AND (is_exchangeable = TRUE OR is_sellable = TRUE);


-- 3. Создать таблицу, содержащую данные 1 запроса с указанием минимальных уровней персонажей и пользователей для их применения.
DROP TABLE IF EXISTS variant39;

SELECT i.item_cod, i.name, i.price, i.description,
       u.character_id, u.min_user_level, u.min_character_level
INTO variant39
FROM "Items" i
JOIN "Item_Usage" u ON i.item_cod = u.item_id
WHERE i.item_type ILIKE '%одеж%'
  AND u.is_usable = TRUE
  AND u.min_character_level > 15
  AND NOT EXISTS (
      SELECT 1
      FROM "Item_Usage" u2
      WHERE u2.item_id = i.item_cod
        AND u2.is_usable = TRUE
        AND u2.min_character_level <= 15
  );


-- 4. Добавить в созданную таблицу предметы, для которых минимальный уровень пользователя и персонажа для их применения совпадают.
INSERT INTO variant39
SELECT i.item_cod, i.name, i.price, i.description,
       u.character_id, u.min_user_level, u.min_character_level
FROM "Items" i
JOIN "Item_Usage" u ON i.item_cod = u.item_id
WHERE u.min_user_level = u.min_character_level
  AND NOT EXISTS (
      SELECT 1
      FROM variant39 v
      WHERE v.item_cod = i.item_cod
        AND v.character_id = u.character_id
  );


-- 5. В созданной таблице уменьшить на 10% стоимость всех предметов, в характеристиках которых отсутствует упоминание об одноразовом применении.
UPDATE variant39
SET price = price * 0.9
WHERE COALESCE(description, '') NOT ILIKE '%одноразов%';


-- 6. Удалить из созданной таблицы все предметы, которые не применяются ни к одному из персонажей.
DELETE FROM variant39 v
WHERE NOT EXISTS (
    SELECT 1
    FROM "Item_Usage" u
    WHERE u.item_id = v.item_cod
      AND u.is_usable = TRUE
);


-- 7. Посчитать суммарную стоимость предметов с возможностью продажи, которые можно применить к каждому из персонажей.
SELECT c.character_id,
       COALESCE(SUM(i.price), 0) AS total_price
FROM (
    SELECT DISTINCT character_id
    FROM "Item_Usage"
) c
LEFT JOIN "Item_Usage" u
    ON c.character_id = u.character_id
   AND u.is_usable = TRUE
LEFT JOIN "Items" i
    ON u.item_id = i.item_cod
   AND i.is_sellable = TRUE
GROUP BY c.character_id
ORDER BY c.character_id;


-- Проверка созданной таблицы
SELECT * FROM variant39;
