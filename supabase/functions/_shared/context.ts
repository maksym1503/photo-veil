import { createClient } from "npm:@supabase/supabase-js@2.57.4";

export function reply(status: number, code: string) {
  return new Response(JSON.stringify({ status: code }), { status, headers: { "Content-Type": "application/json", "Cache-Control": "no-store" } });
}
export async function context(req: Request) {
  if (req.method !== "POST") throw new Error("method");
  const url = Deno.env.get("SUPABASE_URL")!;
  const admin = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, { auth: { persistSession: false, autoRefreshToken: false } });
  const header = req.headers.get("Authorization") ?? "";
  if (!header.startsWith("Bearer ")) throw new Error("auth");
  // Always validate with Auth; do not trust a decoded JWT or a user ID supplied by the client.
  const { data, error } = await admin.auth.getUser(header.slice(7));
  if (error || !data.user) throw new Error("auth");
  return { admin, user: data.user };
}
export function uuid(value: unknown): string {
  if (typeof value !== "string" || !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value)) throw new Error("input");
  return value.toLowerCase();
}
