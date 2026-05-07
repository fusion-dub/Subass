CREATE OR REPLACE FUNCTION get_user_rankings(target_id TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSONB;
    total_count INT;
    overall_percentile FLOAT;
BEGIN
    -- 1. Отримуємо загальну кількість користувачів
    SELECT count(*) INTO total_count FROM users;

    WITH 
    -- 2. Розгортаємо stats у пласку таблицю з агрегацією для ach_4_
    all_stats AS (
        SELECT 
            machine_id, 
            CASE 
                WHEN key IN ('ach_3_definition', 'ach_3_conjugation', 'ach_3_synonyms', 'ach_3_idioms', 'ach_3_word_usage') THEN 'ach_3_count'
                WHEN key LIKE 'ach_4_%' THEN 'ach_4_count' 
                ELSE key 
            END as key, 
            SUM((value#>>'{}')::float8) as val
        FROM users, jsonb_each(stats::jsonb)
        WHERE key NOT LIKE '%_tracking'
          AND jsonb_typeof(value) = 'number'
        GROUP BY 1, 2
    ),
    -- 3. Значення для нашого користувача
    my_keys AS (
        SELECT key, val FROM all_stats WHERE machine_id = target_id
    ),
    -- 4. Рахуємо позицію (навіть для 0, але потім відфільтруємо)
    rankings AS (
        SELECT 
            a.key,
            a.val as my_value,
            (SELECT count(*) FROM all_stats b WHERE b.key = a.key AND (b.val > a.val OR (b.val = a.val AND b.machine_id < target_id))) + 1 as pos,
            (SELECT count(*) FROM all_stats b WHERE b.key = a.key AND b.val > 0) as competitors
        FROM my_keys a
    ),
    -- 5. Рахуємо популярність (скільки людей мають > 0)
    global_popularity AS (
        SELECT 
            key, 
            count(*) as unlocked_by
        FROM all_stats
        WHERE val > 0
        GROUP BY key
    )
    -- 6. Формуємо фінальний JSON
    SELECT jsonb_object_agg(
        gp.key,
        CASE 
            WHEN r.key IS NOT NULL AND r.my_value > 0 THEN 
                jsonb_build_object(
                    'position', r.pos,
                    'total_competitors', r.competitors
                )
            ELSE 
                jsonb_build_object(
                    'unlocked_by', gp.unlocked_by,
                    'total_users', total_count
                )
        END
    ) INTO result
    FROM global_popularity gp
    LEFT JOIN rankings r ON r.key = gp.key;

    -- 7. Рахуємо загальний відсоток (краще за N% користувачів по всім досягненням)
    WITH all_stats AS (
        SELECT
            machine_id,
            CASE 
                WHEN key IN ('ach_3_definition', 'ach_3_conjugation', 'ach_3_synonyms', 'ach_3_idioms', 'ach_3_word_usage') THEN 'ach_3_count'
                WHEN key LIKE 'ach_4_%' THEN 'ach_4_count' 
                ELSE key 
            END AS key,
            SUM((value#>>'{}'  )::float8) AS val
        FROM users, jsonb_each(stats::jsonb)
        WHERE key NOT LIKE '%_tracking'
          AND jsonb_typeof(value) = 'number'
        GROUP BY 1, 2
    )
    SELECT
        CASE WHEN sum(competitors) > 0
        THEN round((sum(competitors - pos)::float / sum(competitors) * 100)::numeric, 1)
        ELSE 0
        END
    INTO overall_percentile
    FROM (
        SELECT
            a.key,
            (SELECT count(*) FROM all_stats b WHERE b.key = a.key AND (b.val > a.val OR (b.val = a.val AND b.machine_id < target_id))) + 1 AS pos,
            (SELECT count(*) FROM all_stats b WHERE b.key = a.key AND b.val > 0) AS competitors
        FROM (SELECT key, val FROM all_stats WHERE machine_id = target_id) a
        WHERE a.val > 0
    ) r;

    result := result || jsonb_build_object('overall_percentile', overall_percentile);

    RETURN result;
END;
$$;
