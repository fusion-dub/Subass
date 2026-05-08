CREATE OR REPLACE FUNCTION get_ach_rankings(
    ach_prefix TEXT, 
    target_id TEXT, 
    limit_count INT DEFAULT 30,
    page_num INT DEFAULT 1
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    top_users  JSONB;
    me_row JSONB;
    offset_val INT := (page_num - 1) * limit_count;
    total_count INT;
BEGIN
    WITH
    -- Агрегуємо значення по кожному користувачу для даного досягнення.
    -- Матчимо key = ach_prefix (точний) АБО key LIKE ach_prefix || '_%' (під-ключі).
    -- Це покриває і ach_4 (де є ach_4_kanji_count, ach_4_word_count, …)
    -- і ach_10 (де є лише ach_10_count).
    ach_stats AS (
        SELECT
            u.machine_id,
            COALESCE(NULLIF(u.dubber_name, ''), u.username) AS dubber_name,
            SUM((value#>>'{}')::float8) AS val
        FROM users u, jsonb_each(u.stats::jsonb)
        WHERE (
            (ach_prefix = 'ach_3' AND key IN ('ach_3_definition', 'ach_3_conjugation', 'ach_3_synonyms', 'ach_3_idioms', 'ach_3_word_usage'))
            OR (ach_prefix != 'ach_3' AND (key = ach_prefix OR key LIKE ach_prefix || '_%'))
          )
          AND key NOT LIKE '%_tracking'
          AND jsonb_typeof(value) = 'number'
        GROUP BY u.machine_id, COALESCE(NULLIF(u.dubber_name, ''), u.username)
    ),
    -- Ранжуємо за спаданням значення (тільки ті, хто > 0)
    -- Додаємо machine_id як tie-breaker для стабільності результатів
    ranked AS (
        SELECT
            machine_id,
            dubber_name,
            val,
            ROW_NUMBER() OVER (ORDER BY val DESC, machine_id ASC) AS rank
        FROM ach_stats
        WHERE val > 0
    )
    SELECT
        -- Поточна сторінка, з позначкою is_me для поточного користувача
        jsonb_agg(
            jsonb_build_object(
                'rank',         rank,
                'dubber_name',  dubber_name,
                'value',        val,
                'is_me',        (machine_id = target_id)
            ) ORDER BY rank
        ) FILTER (WHERE rank > offset_val AND rank <= offset_val + limit_count),

        -- Загальна кількість
        (SELECT COUNT(*) FROM ranked),

        -- Поточний користувач окремо, якщо він поза поточною сторінкою (тільки на 1-й сторінці)
        (
            SELECT jsonb_build_object(
                'rank',         rank,
                'dubber_name',  dubber_name,
                'value',        val,
                'is_me',        true
            )
            FROM ranked
            WHERE machine_id = target_id 
              AND (rank <= offset_val OR rank > offset_val + limit_count)
              AND page_num = 1
        )
    INTO top_users, total_count, me_row
    FROM ranked;

    RETURN jsonb_build_object(
        'leaderboard', COALESCE(top_users, '[]'::jsonb),
        'me',          me_row,   -- null якщо користувач в списку або не на 1-й сторінці
        'has_more',    (offset_val + limit_count < total_count),
        'total_count', COALESCE(total_count, 0),
        'page',        page_num
    );
END;
$$;
