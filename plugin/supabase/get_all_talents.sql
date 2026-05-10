-- SQL функція для отримання списку всіх талантів з пагінацією та фільтрацією
CREATE OR REPLACE FUNCTION get_all_talents(p_limit INT, p_offset INT, p_filters JSONB DEFAULT '{}'::jsonb)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
    v_total_count INT;
BEGIN
    -- Рахуємо загальну кількість з урахуванням фільтрів
    SELECT count(*) INTO v_total_count
    FROM users
    WHERE 
        (p_filters->>'voice' IS NULL OR dubber_voice = p_filters->>'voice')
        AND (p_filters->>'conditions' IS NULL OR dubber_conditions = p_filters->>'conditions')
        AND (p_filters->>'vocals' IS NULL OR dubber_vocals = p_filters->>'vocals')
        AND (p_filters->>'timbre' IS NULL OR p_filters->>'timbre' = '' OR EXISTS (
            SELECT 1 FROM unnest(string_to_array(p_filters->>'timbre', ',')) AS f_t
            WHERE dubber_timbre ILIKE '%' || f_t || '%'
        ))
        AND (p_filters->>'specialization' IS NULL OR p_filters->>'specialization' = '' OR EXISTS (
            SELECT 1 FROM unnest(string_to_array(p_filters->>'specialization', ',')) AS f_s
            WHERE dubber_specialization ILIKE '%' || f_s || '%'
        ))
        AND (p_filters->>'archetypes' IS NULL OR p_filters->>'archetypes' = '' OR EXISTS (
            SELECT 1 FROM unnest(string_to_array(p_filters->>'archetypes', ',')) AS f_a
            WHERE dubber_archetypes ILIKE '%' || f_a || '%'
        ));

    SELECT jsonb_build_object(
        'talents', COALESCE(jsonb_agg(t), '[]'::jsonb),
        'total_count', v_total_count
    ) INTO result
    FROM (
        SELECT 
            machine_id,
            dubber_name,
            dubber_voice,
            dubber_timbre,
            dubber_specialization,
            dubber_bio,
            dubber_equipment,
            dubber_archetypes,
            dubber_contact,
            dubber_vocals,
            dubber_conditions,
            last_active
        FROM users
        WHERE 
            (p_filters->>'voice' IS NULL OR dubber_voice = p_filters->>'voice')
            AND (p_filters->>'conditions' IS NULL OR dubber_conditions = p_filters->>'conditions')
            AND (p_filters->>'vocals' IS NULL OR dubber_vocals = p_filters->>'vocals')
            AND (p_filters->>'timbre' IS NULL OR p_filters->>'timbre' = '' OR EXISTS (
                SELECT 1 FROM unnest(string_to_array(p_filters->>'timbre', ',')) AS f_t
                WHERE dubber_timbre ILIKE '%' || f_t || '%'
            ))
            AND (p_filters->>'specialization' IS NULL OR p_filters->>'specialization' = '' OR EXISTS (
                SELECT 1 FROM unnest(string_to_array(p_filters->>'specialization', ',')) AS f_s
                WHERE dubber_specialization ILIKE '%' || f_s || '%'
            ))
        ORDER BY last_active DESC NULLS LAST, dubber_name ASC
        LIMIT p_limit
        OFFSET p_offset
    ) t;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
