import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const WEBHOOK_AUTH_TOKEN = Deno.env.get("REVENUECAT_WEBHOOK_TOKEN") ?? "";

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const authHeader = req.headers.get("authorization") ?? "";
  if (authHeader !== `Bearer ${WEBHOOK_AUTH_TOKEN}`) {
    return new Response("Unauthorized", { status: 401 });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
  );

  try {
    const body = await req.json();
    const event = body.event;
    const appUserId = event?.app_user_id;

    if (!appUserId) {
      return new Response("Missing app_user_id", { status: 400 });
    }

    const eventType = event?.type;
    const expirationDate = event?.expiration_at_ms
      ? new Date(event.expiration_at_ms).toISOString()
      : null;

    // Inferir período pela duração (>180 dias = annual)
    let subscriptionPeriod: string | null = null;
    if (event?.expiration_at_ms && event?.purchase_date_ms) {
      const durationDays =
        (event.expiration_at_ms - event.purchase_date_ms) / (1000 * 60 * 60 * 24);
      subscriptionPeriod = durationDays > 180 ? "annual" : "monthly";
    }

    let updateData: Record<string, unknown>;

    switch (eventType) {
      case "INITIAL_PURCHASE":
      case "RENEWAL":
      case "UNCANCELLATION":
      case "NON_RENEWING_PURCHASE":
        updateData = {
          subscription_status: "premium",
          subscription_will_renew: true,
          subscription_end_date: expirationDate,
          revenuecat_id: event?.original_app_user_id ?? appUserId,
          ...(subscriptionPeriod ? { subscription_period: subscriptionPeriod } : {}),
        };
        break;
      case "CANCELLATION":
        // Usuário desativou renovação — mantém premium até expirar
        updateData = {
          subscription_status: "premium",
          subscription_will_renew: false,
          subscription_end_date: expirationDate,
          revenuecat_id: event?.original_app_user_id ?? appUserId,
        };
        break;
      case "EXPIRATION":
      case "BILLING_ISSUE":
        updateData = {
          subscription_status: "free",
          subscription_will_renew: false,
          subscription_end_date: null,
          subscription_period: null,
          revenuecat_id: event?.original_app_user_id ?? appUserId,
        };
        break;
      default:
        return new Response(JSON.stringify({ ok: true, ignored: eventType }), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        });
    }

    const { error } = await supabase
      .from("profiles")
      .update(updateData)
      .eq("id", appUserId);

    if (error) {
      console.error("Supabase update error:", error);
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    return new Response(
      JSON.stringify({ ok: true, status: subscriptionStatus }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("Webhook error:", err);
    return new Response(JSON.stringify({ error: "Internal error" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
