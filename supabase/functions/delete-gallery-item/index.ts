import { context, reply, uuid } from "../_shared/context.ts";
Deno.serve(async (req) => {
  try {
    const { admin, user } = await context(req);
    const id = uuid((await req.json()).id);
    const { error } = await admin.from("gallery_items").update({ deleted_at: new Date().toISOString() }).eq("user_id", user.id).eq("id", id);
    if (error) return reply(503, "retry");
    // Also repairs interrupted uploads that never produced a metadata row. Caller can only delete their own namespace.
    const prefix = `${user.id}/${id}`;
    const { error: files } = await admin.storage.from("veil-gallery").remove([`${prefix}/processed.jpg`, `${prefix}/thumbnail.jpg`]);
    return files ? reply(503, "retry") : reply(200, "deleted");
  } catch { return reply(400, "unavailable"); }
});
