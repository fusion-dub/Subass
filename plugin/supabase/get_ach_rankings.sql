CREATE OR REPLACE FUNCTION get_ach_rankings(ach_prefix TEXT, target_id TEXT, limit_count INT DEFAULT 30)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    top_users  JSONB;
    me_row JSONB;
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
        WHERE (key = ach_prefix OR key LIKE ach_prefix || '_%')
          AND key NOT LIKE '%_tracking'
          AND jsonb_typeof(value) = 'number'
        GROUP BY u.machine_id, COALESCE(NULLIF(u.dubber_name, ''), u.username)
    ),
    -- Ранжуємо за спаданням значення (тільки ті, хто > 0)
    ranked AS (
        SELECT
            machine_id,
            dubber_name,
            val,
            ROW_NUMBER() OVER (ORDER BY val DESC NULLS LAST) AS rank
        FROM ach_stats
        WHERE val > 0
    )
    SELECT
        -- Топ-30, з позначкою is_me для поточного користувача
        jsonb_agg(
            jsonb_build_object(
                'rank',         rank,
                'dubber_name',  dubber_name,
                'value',        val,
                'is_me',        (machine_id = target_id)
            ) ORDER BY rank
        ) FILTER (WHERE rank <= limit_count),

        -- Поточний користувач окремо, якщо він поза топ-30
        (
            SELECT jsonb_build_object(
                'rank',         rank,
                'dubber_name',  dubber_name,
                'value',        val,
                'is_me',        true
            )
            FROM ranked
            WHERE machine_id = target_id AND rank > limit_count
        )
    INTO top_users, me_row
    FROM ranked;

    RETURN jsonb_build_object(
        'leaderboard', COALESCE(top_users, '[]'::jsonb),
        'me',          me_row   -- null якщо користувач в топ-30
    );
END;
$$;
