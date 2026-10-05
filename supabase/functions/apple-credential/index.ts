import { context, reply } from "../_shared/context.ts";
Deno.serve(async (req) => {
  try {
    const { admin, user } = await context(req);
    const identity = user.identities?.find((i) => i.provider === "apple");
    if (!identity) return reply(403, "provider");
    const { code } = await req.json();
    if (typeof code !== "string" || code.length > 4096) return reply(400, "input");
    const clientID = Deno.env.get("APPLE_NATIVE_CLIENT_ID"), secret = Deno.env.get("APPLE_CLIENT_SECRET");
    if (!clientID || !secret) return reply(503, "configuration");
    const response = await fetch("https://appleid.apple.com/auth/token", {
      method: "POST", headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({ grant_type: "authorization_code", code, client_id: clientID, client_secret: secret }),
    });
    if (!response.ok) return reply(409, "reauthorize");
    const token = await response.json();
    if (!token.refresh_token || !token.id_token) return reply(409, "reauthorize");
    // This token came directly from Apple's authenticated HTTPS token endpoint. Bind code to the same Apple subject.
    const payload = JSON.parse(atob(token.id_token.split(".")[1].replace(/-/g, "+").replace(/_/g, "/")));
    if (payload.sub !== identity.identity_data?.sub || payload.aud !== clientID || payload.iss !== "https://appleid.apple.com") return reply(403, "identity");
    const { error } = await admin.rpc("veil_store_apple_refresh", { owner_id: user.id, refresh_token: token.refresh_token });
    if (error) return reply(503, "retry");
    return reply(200, "saved");
  } catch { return reply(400, "unavailable"); } // No token/code/payload logging.
});
