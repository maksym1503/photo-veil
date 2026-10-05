import { deleteAccount, deleteGalleryItem } from "../_shared/handlers.ts";
const owner = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa";
const edit = "11111111-1111-1111-1111-111111111111";
function assert(value: boolean) { if (!value) throw new Error("Deletion assertion failed"); }
function request(body: unknown = {}) { return new Request("https://example.invalid/function", { method: "POST", headers: { Authorization: "Bearer TEST-ONLY", "Content-Type": "application/json" }, body: JSON.stringify(body) }); }

// All HTTP is mocked. No real endpoint/key/provider identity is configured or contacted.
async function mocked(run: (calls: string[]) => Promise<void>, apple = false, failStorage = false, failRevoke = false) {
  Deno.env.set("SUPABASE_URL", "https://example.invalid"); Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "TEST-ONLY");
  Deno.env.set("APPLE_NATIVE_CLIENT_ID", "TEST-ONLY"); Deno.env.set("APPLE_CLIENT_SECRET", "TEST-ONLY");
  const real = globalThis.fetch, calls: string[] = [];
  let listed = false;
  globalThis.fetch = ((input: RequestInfo | URL, init?: RequestInit) => {
    const url = new URL(input instanceof Request ? input.url : String(input)), method = init?.method ?? (input instanceof Request ? input.method : "GET");
    calls.push(`${method} ${url.pathname}${url.search}`);
    let data: unknown = {};
    if (url.pathname === "/auth/v1/user") data = { id: owner, app_metadata: { provider: apple ? "apple" : "google" }, identities: apple ? [{ provider: "apple" }] : [] };
    if (url.pathname.includes("veil_apple_refresh")) data = "TEST-ONLY";
    if (url.pathname.includes("/object/list/")) { data = listed ? [] : [{ name: "processed.jpg", id: edit }]; listed = true; }
    const fails = (failStorage && method === "DELETE" && url.pathname.includes("/object/")) || (failRevoke && url.pathname === "/auth/revoke");
    return Promise.resolve(new Response(JSON.stringify(data), { status: fails ? 500 : 200, headers: { "Content-Type": "application/json" } }));
  }) as typeof fetch;
  try { await run(calls); } finally { globalThis.fetch = real; }
}
Deno.test("unauthenticated deletion never reaches admin APIs", async () => {
  await mocked(async (calls) => {
    const response = await deleteAccount(new Request("https://example.invalid/function", { method: "POST" }));
    assert(response.status === 401); assert(calls.length === 0);
  });
});
Deno.test("item deletion binds namespace to verified owner, not body user ID", async () => {
  await mocked(async (calls) => {
    const response = await deleteGalleryItem(request({ id: edit, user_id: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb" }));
    assert(response.status === 200); assert(calls.some((c) => c.includes(`user_id=eq.${owner}`)));
    assert(!calls.some((c) => c.includes("bbbbbbbb")));
  });
});
Deno.test("storage failure does not claim deletion success", async () => {
  await mocked(async () => { assert((await deleteGalleryItem(request({ id: edit }))).status === 503); }, false, true);
});
Deno.test("account closes writes and removes storage before Auth identity", async () => {
  await mocked(async (calls) => {
    assert((await deleteAccount(request())).status === 200);
    const gate = calls.findIndex((c) => c.includes("/profiles")), storage = calls.findIndex((c) => c.startsWith("DELETE") && c.includes("/storage/"));
    const auth = calls.findIndex((c) => c.startsWith("DELETE") && c.includes("/auth/v1/admin/users/"));
    assert(gate >= 0 && storage > gate && auth > storage);
  });
});
Deno.test("Apple revocation failure leaves Auth identity for retry", async () => {
  await mocked(async (calls) => {
    assert((await deleteAccount(request())).status === 503);
    assert(calls.some((c) => c.includes("/auth/revoke")));
    assert(!calls.some((c) => c.startsWith("DELETE") && c.includes("/auth/v1/admin/users/")));
  }, true, false, true);
});
