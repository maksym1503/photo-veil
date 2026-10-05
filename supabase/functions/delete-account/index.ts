import { context, reply } from "../_shared/context.ts";
Deno.serve(async (req) => {
  try {
    const { admin, user } = await context(req);
    // Close the write gate before deleting anything. Persisted on failure; retry is safe.
    const { error: gate } = await admin.from("profiles").update({ deletion_requested: true }).eq("id", user.id);
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
  } catch { return reply(400, "unavailable"); }
});
