import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response("Method not allowed", {
      status: 405,
      headers: corsHeaders,
    });
  }

  const stripeSecretKey = Deno.env.get("STRIPE_SECRET_KEY");
  if (!stripeSecretKey) {
    return new Response(
      JSON.stringify({ error: "Stripe secret key not configured" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(
      JSON.stringify({ error: "Missing authorization" }),
      { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const token = authHeader.replace("Bearer ", "");
  const { data: { user }, error: authError } = await supabase.auth.getUser(token);

  if (authError || !user) {
    return new Response(
      JSON.stringify({ error: "Invalid token" }),
      { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  const { data: profile } = await supabase
    .from("profiles")
    .select("stripe_customer_id, email")
    .eq("id", user.id)
    .single();

  if (!profile) {
    return new Response(
      JSON.stringify({ error: "Profile not found" }),
      { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  let customerId = profile.stripe_customer_id;

  // Fallback: buscar pelo email no Stripe
  if (!customerId) {
    const email = profile.email || user.email;
    if (email) {
      const searchResponse = await fetch(
        `https://api.stripe.com/v1/customers/search?query=email:'${encodeURIComponent(email)}'`,
        { headers: { Authorization: `Bearer ${stripeSecretKey}` } },
      );
      if (searchResponse.ok) {
        const searchData = await searchResponse.json();
        if (searchData.data && searchData.data.length > 0) {
          customerId = searchData.data[0].id;
          await supabase
            .from("profiles")
            .update({ stripe_customer_id: customerId })
            .eq("id", user.id);
        }
      }
    }
  }

  if (!customerId) {
    await supabase.from("profiles").update({
      subscription_status: "free",
      subscription_period: null,
      subscription_end_date: null,
      subscription_will_renew: false,
    }).eq("id", user.id);

    return new Response(
      JSON.stringify({ status: "free", reason: "no_stripe_customer" }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  try {
    // Verificar assinaturas ativas no Stripe
    const activeResponse = await fetch(
      `https://api.stripe.com/v1/subscriptions?customer=${customerId}&status=active&limit=1`,
      { headers: { Authorization: `Bearer ${stripeSecretKey}` } },
    );

    if (activeResponse.ok) {
      const activeData = await activeResponse.json();
      if (activeData.data && activeData.data.length > 0) {
        const sub = activeData.data[0];
        const interval = sub.items?.data?.[0]?.price?.recurring?.interval;
        const endDate = sub.current_period_end
          ? new Date(sub.current_period_end * 1000).toISOString()
          : null;

        const willRenew = !sub.cancel_at_period_end;
        await supabase.from("profiles").update({
          subscription_status: "premium",
          subscription_period: interval === "year" ? "annual" : "monthly",
          subscription_end_date: endDate,
          subscription_will_renew: willRenew,
        }).eq("id", user.id);

        return new Response(
          JSON.stringify({
            status: "premium",
            cancel_at_period_end: sub.cancel_at_period_end || false,
            current_period_end: endDate,
            will_renew: willRenew,
          }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }
    }

    // Sem assinatura ativa — verificar se tem cancelada dentro do período
    const allResponse = await fetch(
      `https://api.stripe.com/v1/subscriptions?customer=${customerId}&limit=5`,
      { headers: { Authorization: `Bearer ${stripeSecretKey}` } },
    );

    if (allResponse.ok) {
      const allData = await allResponse.json();
      // Filtrar apenas subscriptions relevantes (excluir incomplete/incomplete_expired)
      const validSubs = (allData.data || []).filter(
        (s: { status: string }) =>
          s.status === "active" || s.status === "canceled" || s.status === "trialing" || s.status === "past_due",
      );
      if (validSubs.length > 0) {
        const sub = validSubs[0];
        if (sub.current_period_end) {
          const endDate = new Date(sub.current_period_end * 1000);
          if (endDate > new Date()) {
            // Cancelada mas dentro do período pago
            const interval = sub.items?.data?.[0]?.price?.recurring?.interval;
            await supabase.from("profiles").update({
              subscription_status: "premium",
              subscription_period: interval === "year" ? "annual" : "monthly",
              subscription_end_date: endDate.toISOString(),
              subscription_will_renew: false,
            }).eq("id", user.id);

            return new Response(
              JSON.stringify({
                status: "premium",
                cancel_at_period_end: true,
                current_period_end: endDate.toISOString(),
                will_renew: false,
              }),
              { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
            );
          }
        }
      }
    }

    await supabase.from("profiles").update({
      subscription_status: "free",
      subscription_period: null,
      subscription_end_date: null,
      subscription_will_renew: false,
    }).eq("id", user.id);

    return new Response(
      JSON.stringify({ status: "free", reason: "no_active_subscription" }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: "Internal error", message: String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
