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

  // Autenticar usuário via JWT do Supabase
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

  // Verificar o JWT e obter o usuário
  const token = authHeader.replace("Bearer ", "");
  const { data: { user }, error: authError } = await supabase.auth.getUser(token);

  if (authError || !user) {
    return new Response(
      JSON.stringify({ error: "Invalid token" }),
      { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  // Buscar stripe_customer_id do usuário
  const { data: profile, error: profileError } = await supabase
    .from("profiles")
    .select("stripe_customer_id, email")
    .eq("id", user.id)
    .single();

  if (profileError || !profile) {
    return new Response(
      JSON.stringify({ error: "User profile not found" }),
      { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  let customerId = profile.stripe_customer_id;

  // Fallback: buscar customer no Stripe pelo email
  if (!customerId) {
    const email = profile.email || user.email;
    if (!email) {
      return new Response(
        JSON.stringify({ error: "No Stripe customer ID or email found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const searchResponse = await fetch(
      `https://api.stripe.com/v1/customers/search?query=email:'${encodeURIComponent(email)}'`,
      {
        headers: { Authorization: `Bearer ${stripeSecretKey}` },
      },
    );

    if (searchResponse.ok) {
      const searchData = await searchResponse.json();
      if (searchData.data && searchData.data.length > 0) {
        customerId = searchData.data[0].id;
        // Salvar para próximas vezes
        await supabase
          .from("profiles")
          .update({ stripe_customer_id: customerId })
          .eq("id", user.id);
      }
    }

    if (!customerId) {
      return new Response(
        JSON.stringify({ error: "Stripe customer not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }
  }

  try {
    // Buscar assinaturas do customer no Stripe (active, trialing, past_due)
    const subsResponse = await fetch(
      `https://api.stripe.com/v1/subscriptions?customer=${customerId}&limit=5`,
      {
        headers: {
          Authorization: `Bearer ${stripeSecretKey}`,
        },
      },
    );

    if (!subsResponse.ok) {
      const err = await subsResponse.json();
      return new Response(
        JSON.stringify({ error: "Failed to fetch subscriptions", details: err }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const subsData = await subsResponse.json();

    // Filtrar assinaturas canceláveis (active ou trialing)
    const cancelable = (subsData.data || []).filter(
      (s: { status: string; cancel_at_period_end: boolean }) =>
        (s.status === "active" || s.status === "trialing") && !s.cancel_at_period_end,
    );

    if (cancelable.length === 0) {
      // Verificar se já existe assinatura cancelada (cancel_at_period_end=true)
      const alreadyCancelled = (subsData.data || []).filter(
        (s: { status: string; cancel_at_period_end: boolean }) =>
          (s.status === "active" || s.status === "trialing") && s.cancel_at_period_end,
      );

      if (alreadyCancelled.length > 0) {
        const sub = alreadyCancelled[0];
        const endDate = sub.current_period_end
          ? new Date(sub.current_period_end * 1000).toISOString()
          : null;

        // Sincronizar estado no banco
        await supabase
          .from("profiles")
          .update({
            subscription_end_date: endDate,
            subscription_will_renew: false,
          })
          .eq("id", user.id);

        return new Response(
          JSON.stringify({
            success: true,
            already_cancelled: true,
            cancel_at_period_end: true,
            current_period_end: endDate,
          }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }

      return new Response(
        JSON.stringify({ error: "No active subscription found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const subscription = cancelable[0];

    // Cancelar no fim do período (usuário mantém acesso até expirar)
    const cancelResponse = await fetch(
      `https://api.stripe.com/v1/subscriptions/${subscription.id}`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${stripeSecretKey}`,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: "cancel_at_period_end=true",
      },
    );

    if (!cancelResponse.ok) {
      const err = await cancelResponse.json();
      return new Response(
        JSON.stringify({ error: "Failed to cancel subscription", details: err }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const cancelledSub = await cancelResponse.json();

    // Atualizar subscription_end_date no profiles (data de expiração do período)
    const endDate = cancelledSub.current_period_end
      ? new Date(cancelledSub.current_period_end * 1000).toISOString()
      : null;

    await supabase
      .from("profiles")
      .update({
        subscription_end_date: endDate,
        subscription_will_renew: false,
      })
      .eq("id", user.id);

    return new Response(
      JSON.stringify({
        success: true,
        cancel_at_period_end: true,
        current_period_end: endDate,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: "Internal error", message: String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
