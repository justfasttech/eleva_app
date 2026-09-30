import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cryptoKey = async (secret: string) => {
  const encoder = new TextEncoder();
  return await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign", "verify"],
  );
};

async function verifyStripeSignature(
  payload: string,
  header: string,
  secret: string,
): Promise<boolean> {
  const parts = header.split(",").reduce(
    (acc, part) => {
      const [key, value] = part.split("=");
      if (key === "t") acc.timestamp = value;
      if (key === "v1") acc.signatures.push(value);
      return acc;
    },
    { timestamp: "", signatures: [] as string[] },
  );

  if (!parts.timestamp || parts.signatures.length === 0) return false;

  const tolerance = 300; // 5 minutos
  const now = Math.floor(Date.now() / 1000);
  if (Math.abs(now - parseInt(parts.timestamp)) > tolerance) return false;

  const signedPayload = `${parts.timestamp}.${payload}`;
  const key = await cryptoKey(secret);
  const encoder = new TextEncoder();
  const signatureBuffer = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(signedPayload),
  );
  const computed = Array.from(new Uint8Array(signatureBuffer))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");

  return parts.signatures.some((sig) => sig === computed);
}

serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const stripeWebhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET");
  if (!stripeWebhookSecret) {
    return new Response("Webhook secret not configured", { status: 500 });
  }

  const signature = req.headers.get("stripe-signature");
  if (!signature) {
    return new Response("No signature", { status: 400 });
  }

  const body = await req.text();
  const valid = await verifyStripeSignature(body, signature, stripeWebhookSecret);
  if (!valid) {
    return new Response("Invalid signature", { status: 400 });
  }

  const event = JSON.parse(body);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  if (event.type === "checkout.session.completed") {
    const session = event.data.object;
    const userId = session.client_reference_id;
    if (!userId) {
      return new Response(JSON.stringify({ error: "No client_reference_id" }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    const mode = session.mode; // "subscription" ou "payment"
    if (mode !== "subscription") {
      return new Response(JSON.stringify({ skipped: true }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Determinar periodo baseado no intervalo do Stripe
    let period = "monthly";
    const lineItems = session.line_items?.data;
    if (lineItems && lineItems.length > 0) {
      const interval = lineItems[0]?.price?.recurring?.interval;
      if (interval === "year") period = "annual";
    }

    const updateData: Record<string, unknown> = {
      subscription_status: "premium",
      subscription_period: period,
      subscription_end_date: session.current_period_end
        ? new Date(session.current_period_end * 1000).toISOString()
        : null,
    };
    if (session.customer) {
      updateData.stripe_customer_id = session.customer;
    }

    await supabase.from("profiles").update(updateData).eq("id", userId);

    return new Response(JSON.stringify({ updated: userId, period }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  }

  if (
    event.type === "customer.subscription.deleted" ||
    event.type === "customer.subscription.updated"
  ) {
    const subscription = event.data.object;

    // Buscar usuario pelo stripe customer id via metadata ou client_reference_id
    const customerId = subscription.customer;
    const { data: profiles } = await supabase
      .from("profiles")
      .select("id")
      .eq("stripe_customer_id", customerId)
      .limit(1);

    if (!profiles || profiles.length === 0) {
      return new Response(JSON.stringify({ skipped: "user not found" }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    const userId = profiles[0].id;

    if (
      event.type === "customer.subscription.deleted" ||
      subscription.status === "canceled" ||
      subscription.status === "unpaid" ||
      subscription.status === "past_due"
    ) {
      await supabase.from("profiles").update({
        subscription_status: "free",
        subscription_period: null,
        subscription_end_date: null,
      }).eq("id", userId);
    } else if (subscription.status === "active") {
      const interval = subscription.items?.data?.[0]?.price?.recurring?.interval;
      await supabase.from("profiles").update({
        subscription_status: "premium",
        subscription_period: interval === "year" ? "annual" : "monthly",
        subscription_end_date: subscription.current_period_end
          ? new Date(subscription.current_period_end * 1000).toISOString()
          : null,
      }).eq("id", userId);
    }

    return new Response(JSON.stringify({ processed: event.type }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  }

  return new Response(JSON.stringify({ received: event.type }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
