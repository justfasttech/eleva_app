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

    let subscriptionStatus: string;

    switch (eventType) {
      case "INITIAL_PURCHASE":
      case "RENEWAL":
      case "UNCANCELLATION":
      case "NON_RENEWING_PURCHASE":
        subscriptionStatus = "premium";
        break;
      case "CANCELLATION":
      case "EXPIRATION":
      case "BILLING_ISSUE":
        subscriptionStatus = "free";
        break;
      default:
        return new Response(JSON.stringify({ ok: true, ignored: eventType }), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        });
    }

    const { error } = await supabase
      .from("profiles")
      .update({
        subscription_status: subscriptionStatus,
        subscription_end_date: expirationDate,
        revenuecat_id: event?.original_app_user_id ?? appUserId,
      })
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
