-- SQL команда для отримання деталей профілю
CREATE OR REPLACE FUNCTION get_user_profile_details(target_id TEXT)
RETURNS JSONB AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'dubber_name', dubber_name,
        'dubber_bio', dubber_bio,
        'dubber_contact', dubber_contact,
        'dubber_samples', dubber_samples,
        'dubber_equipment', dubber_equipment,
        'dubber_conditions', dubber_conditions,
        'dubber_specialization', dubber_specialization,
        'dubber_voice', dubber_voice,
        'dubber_timbre', dubber_timbre,
        'last_active', last_active
    ) INTO result
    FROM users
    WHERE machine_id = target_id;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
