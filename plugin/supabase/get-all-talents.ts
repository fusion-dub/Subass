import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
    if (req.method === "OPTIONS") return new Response("ok");
    if (req.method !== "POST") return new Response("expected POST", { status: 405 });

    try {
        const { limit = 20, offset = 0, filters = {} } = await req.json();

        const supabaseAdmin = createClient(
            Deno.env.get("SUPABASE_URL") ?? "",
            Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
        );

        // Викликаємо RPC для отримання списку талантів
        const { data, error } = await supabaseAdmin
            .rpc("get_all_talents", { 
                p_limit: limit, 
                p_offset: offset,
                p_filters: filters
            });

        if (error) throw error;

        return new Response(JSON.stringify({
            ok: true,
            data: data
        }), {
            status: 200,
            headers: { "Content-Type": "application/json" }
        });

    } catch (err) {
        return new Response(JSON.stringify({ error: err.message }), { status: 500 });
    }
});
