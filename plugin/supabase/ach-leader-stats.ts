import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { z } from "npm:zod";

const PayloadSchema = z.object({
  machine_id: z.string().min(1),
  ach_prefix:  z.string().min(1),
  limit_count: z.number().int().positive().optional(),
});

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok");
  if (req.method !== "POST") return new Response("expected POST", { status: 405 });

  try {
    const body = await req.json();
    const parsed = PayloadSchema.safeParse(body);
    if (!parsed.success) {
      return new Response(JSON.stringify({ error: parsed.error.flatten() }), { status: 400 });
    }

    const { machine_id, ach_prefix, limit_count } = parsed.data;

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const rpcParams: Record<string, unknown> = {
      target_id:  machine_id,
      ach_prefix,
    };
    if (limit_count !== undefined) rpcParams.limit_count = limit_count;

    const { data, error: rpcError } = await supabaseAdmin
      .rpc("get_ach_rankings", rpcParams);

    if (rpcError) throw rpcError;

    return new Response(JSON.stringify({ ok: true, ...data }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });

  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500 });
  }
});
