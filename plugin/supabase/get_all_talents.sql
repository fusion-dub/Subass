-- SQL функція для отримання списку всіх талантів з пагінацією
CREATE OR REPLACE FUNCTION get_all_talents(p_limit INT, p_offset INT)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'talents', COALESCE(jsonb_agg(t), '[]'::jsonb),
        'total_count', (SELECT count(*) FROM users)
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
            last_active
        FROM users
        ORDER BY last_active DESC NULLS LAST, dubber_name ASC
        LIMIT p_limit
        OFFSET p_offset
    ) t;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
