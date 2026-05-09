import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { z } from "npm:zod";

const PayloadSchema = z.object({
    machine_id: z.string().min(1),
    username: z.string().min(1),
    dubber_name: z.string().min(1),
    dubber_bio: z.string().optional(),
    dubber_contact: z.string().optional(),
    dubber_samples: z.string().optional(),
    dubber_equipment: z.string().optional(),
    dubber_conditions: z.string().optional(),
    dubber_voice: z.string().optional(),
    dubber_timbre: z.string().optional(),
    script_title: z.string().min(1),
    os: z.string().min(1),
    last_active: z.string().min(1),
    stats: z.record(z.any()),
});

Deno.serve(async (req: Request) => {
    if (req.method === "OPTIONS") return new Response("ok");
    if (req.method !== "POST") return new Response("expected POST", { status: 405 });

    try {
        const body = await req.json();
        const parsed = PayloadSchema.safeParse(body);
        if (!parsed.success) return new Response("invalid payload", { status: 400 });

        const supabaseAdmin = createClient(
            Deno.env.get("SUPABASE_URL") ?? "",
            Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
        );

        const userData = parsed.data;

        // 1. Зберігаємо дані
        const { error: upsertError } = await supabaseAdmin
            .from("users")
            .upsert({
                machine_id: userData.machine_id,
                username: userData.username,
                script_title: userData.script_title,
                dubber_name: userData.dubber_name,
                dubber_bio: userData.dubber_bio,
                dubber_contact: userData.dubber_contact,
                dubber_samples: userData.dubber_samples,
                dubber_equipment: userData.dubber_equipment,
                dubber_conditions: userData.dubber_conditions,
                dubber_voice: userData.dubber_voice,
                dubber_timbre: userData.dubber_timbre,
                os: userData.os,
                last_active: userData.last_active,
                stats: userData.stats,
            }, { onConflict: "machine_id" });

        if (upsertError) throw upsertError;

        // 2. Викликаємо Postgres RPC для розрахунку рейтингів
        const { data: rankings, error: rpcError } = await supabaseAdmin
            .rpc("get_user_rankings", { target_id: userData.machine_id });

        if (rpcError) throw rpcError;

        return new Response(JSON.stringify({
            ok: true,
            rankings
        }), {
            status: 200,
            headers: { "Content-Type": "application/json" }
        });

    } catch (err) {
        return new Response(JSON.stringify({ error: err.message }), { status: 500 });
    }
});
