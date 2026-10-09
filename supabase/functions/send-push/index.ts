import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

interface ServiceAccount {
  project_id: string;
  private_key: string;
  client_email: string;
}

async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = btoa(JSON.stringify({ alg: "RS256", typ: "JWT" }))
    .replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  const payload = btoa(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  })).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");

  const pemContent = sa.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\n/g, "");
  const binaryKey = Uint8Array.from(atob(pemContent), (c) => c.charCodeAt(0));

  const key = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const data = new TextEncoder().encode(`${header}.${payload}`);
  const signature = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, data);
  const sig = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");

  const jwt = `${header}.${payload}.${sig}`;

  const resp = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const tokenData = await resp.json();
  return tokenData.access_token;
}

serve(async (req) => {
  try {
    const body = await req.json();
    const record = body.record;

    if (!record) {
      return new Response(JSON.stringify({ error: "No record" }), {
        status: 400,
      });
    }

    const { title, body: notifBody, target_user_id } = record;

    const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    if (!serviceAccountJson) {
      return new Response(
        JSON.stringify({ error: "FIREBASE_SERVICE_ACCOUNT not set" }),
        { status: 500 },
      );
    }

    const serviceAccount: ServiceAccount = JSON.parse(serviceAccountJson);
    const accessToken = await getAccessToken(serviceAccount);
    const projectId = serviceAccount.project_id;

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    let query = supabase.from("push_tokens").select("token, user_id");
    if (target_user_id) {
      query = query.eq("user_id", target_user_id);
    }

    const { data: tokens, error: tokensError } = await query;

    if (tokensError || !tokens || tokens.length === 0) {
      return new Response(
        JSON.stringify({ message: "No tokens found", error: tokensError }),
        { status: 200 },
      );
    }

    const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
    const invalidTokens: string[] = [];
    let sent = 0;

    for (const { token } of tokens) {
      try {
        const resp = await fetch(fcmUrl, {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token,
              notification: {
                title: title ?? "Eleva",
                body: notifBody ?? "",
              },
              android: {
                priority: "high",
                notification: {
                  channel_id: "eleva_notifications",
                  sound: "default",
                },
              },
            },
          }),
        });

        if (resp.ok) {
          sent++;
        } else {
          const errData = await resp.json();
          const errCode = errData?.error?.details?.[0]?.errorCode ??
            errData?.error?.status;
          if (
            errCode === "UNREGISTERED" || errCode === "INVALID_ARGUMENT" ||
            resp.status === 404
          ) {
            invalidTokens.push(token);
          }
        }
      } catch (e) {
        console.error(`Erro ao enviar push para token ${token}:`, e);
      }
    }

    if (invalidTokens.length > 0) {
      for (const token of invalidTokens) {
        await supabase.from("push_tokens").delete().eq("token", token);
      }
    }

    return new Response(
      JSON.stringify({
        sent,
        total: tokens.length,
        invalidRemoved: invalidTokens.length,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.error("send-push error:", e);
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});
