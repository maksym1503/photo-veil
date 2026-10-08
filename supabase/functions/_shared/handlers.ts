import { context, reply, uuid, RequestFailure } from "./context.ts";

export async function appleCredential(req: Request): Promise<Response> {
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
  } catch (error) { return reply(error instanceof RequestFailure ? error.status : 503, "unavailable"); } // No token/code/payload logging.
}

export async function deleteGalleryItem(req: Request): Promise<Response> {
  try {
    const { admin, user } = await context(req);
    const id = uuid((await req.json()).id);
    const { error } = await admin.from("gallery_items").update({ deleted_at: new Date().toISOString() }).eq("user_id", user.id).eq("id", id);
    if (error) return reply(503, "retry");
    // Also repairs interrupted uploads that never produced a metadata row. Caller can only delete their own namespace.
    const prefix = `${user.id}/${id}`;
    const { error: files } = await admin.storage.from("veil-gallery").remove([`${prefix}/processed.jpg`, `${prefix}/thumbnail.jpg`]);
    return files ? reply(503, "retry") : reply(200, "deleted");
  } catch (error) { return reply(error instanceof RequestFailure ? error.status : 503, "unavailable"); }
}

export async function deleteAccount(req: Request): Promise<Response> {
  try {
    const { admin, user } = await context(req);
    // Close the write gate before deleting anything. Persisted on failure; retry is safe.
    const { error: gate } = await admin.from("profiles").upsert({ id: user.id, deletion_requested: true });
    if (gate) return reply(503, "retry");
    if (user.identities?.some((i) => i.provider === "apple")) {
      const { data: refresh, error } = await admin.rpc("veil_apple_refresh", { owner_id: user.id });
      const clientID = Deno.env.get("APPLE_NATIVE_CLIENT_ID"), secret = Deno.env.get("APPLE_CLIENT_SECRET");
      if (error || !refresh || !clientID || !secret) return reply(409, "reauthorize_apple");
      const result = await fetch("https://appleid.apple.com/auth/revoke", { method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({ client_id: clientID, client_secret: secret, token: refresh, token_type_hint: "refresh_token" }),
      });
      if (!result.ok) return reply(503, "retry");
    }
    const bucket = admin.storage.from("veil-gallery");
    async function clear(prefix: string): Promise<void> {
      // Remove the first page repeatedly, including files from incomplete uploads.
      while (true) {
        const { data, error } = await bucket.list(prefix, { limit: 100, sortBy: { column: "name", order: "asc" } });
        if (error) throw error;
        if (!data?.length) return;
        const files: string[] = [];
        for (const entry of data) {
          if (entry.id) files.push(`${prefix}/${entry.name}`);
          else await clear(`${prefix}/${entry.name}`);
        }
        if (files.length) { const { error } = await bucket.remove(files); if (error) throw error; }
      }
    }
    await clear(user.id);
    // Cascades remove profile, gallery metadata and credential references. Auth revokes refresh sessions.
    const { error: removed } = await admin.auth.admin.deleteUser(user.id);
    return removed ? reply(503, "retry") : reply(200, "deleted");
  } catch (error) { return reply(error instanceof RequestFailure ? error.status : 503, "unavailable"); }
}
