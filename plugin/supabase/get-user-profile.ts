import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
    if (req.method === "OPTIONS") return new Response("ok");
    if (req.method !== "POST") return new Response("expected POST", { status: 405 });

    try {
        const { machine_id } = await req.json();
        if (!machine_id) return new Response("machine_id required", { status: 400 });

        const supabaseAdmin = createClient(
            Deno.env.get("SUPABASE_URL") ?? "",
            Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
        );

        // Викликаємо RPC для отримання деталей профілю
        const { data, error } = await supabaseAdmin
            .rpc("get_user_profile_details", { target_id: machine_id });

        if (error) throw error;
        if (!data) return new Response("profile not found", { status: 404 });

        return new Response(JSON.stringify({
            ok: true,
            profile: data
        }), {
            status: 200,
            headers: { "Content-Type": "application/json" }
        });

    } catch (err) {
        return new Response(JSON.stringify({ error: err.message }), { status: 500 });
    }
});
