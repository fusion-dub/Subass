import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { z } from "npm:zod";

const PayloadSchema = z.object({
  machine_id: z.string().min(1),
  username: z.string().min(1),
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
