# V4 backend setup — owner-controlled, not provisioned

The default app compiles with no credentials, no account UI that pretends to sign in, and no Veil network client instantiated. Editor, gallery, Share and Photos saving work offline. Nothing was deployed by Codex. Do not merge or release until device/provider/backend validation is complete.

## Dependency

Official `supabase-swift` **2.55.3**, commit `9c8c9d283b13a369f52cc78d8639648d8a17f5d3`, MIT. Reviewed release source/configuration, Keychain and OAuth implementation, examples and maintenance (release September 29, 2026). Only the **Auth** product is linked, not the all-in-one Supabase/Realtime product. It owns PKCE, refresh and session persistence; a small ephemeral URLSession adapter transports SQL metadata/private Storage bytes. Apple cryptography/HTTP types and Point-Free clocks/concurrency/issue-reporting packages are transitive runtime dependencies; exact versions are in `PhotoVeil.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`. Swift Crypto's manifest is bundled. No analytics or telemetry traits are enabled. Server functions pin `@supabase/supabase-js` 2.117.2. Review licenses/SDK compliance with each update; keep the resolution lockfile.

## 1. Project and storage

1. Create a Supabase project in an owner-chosen region. Confirm pricing, quotas, backup retention, processors/DPA and production legal policy. Do not reuse a project with public photo buckets/policies.
2. Install the official Supabase CLI and Docker for a disposable local stack. From this repository: `supabase start`, `supabase db reset`, then run `psql "$VEIL_LOCAL_DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/ownership.sql` against that **local** stack. Never run test fixtures against production.
3. Inspect/apply both migrations in `supabase/migrations`. Vault must be available. Locally validate Vault privileges, account cleanup trigger and Storage API integration; the repository's PostgreSQL-shim policy runner is an additional deterministic RLS check, not a substitute for Supabase.
4. Link the real project with `supabase link --project-ref YOUR_REAL_PROJECT_REF`, review migration diff, then `supabase db push`. Confirm RLS on profiles/gallery and private `veil-gallery` bucket. No public URLs/signed links are used. JPEG-only bucket, maximum object 50 MiB. Set owner-chosen per-user quotas/rate limits/billing alerts before public launch; publish resulting limits rather than inventing them here.
5. Deploy `apple-credential`, `delete-gallery-item`, `delete-account` using `supabase functions deploy FUNCTION_NAME`. They independently verify bearer tokens with Auth `getUser` even though platform `verify_jwt` is false (supports current keys). Never remove that verification. Service-role key stays in the managed function environment; never in iOS. Functions never accept an account owner ID from the client.

## 2. Apple provider and deletion revocation

1. Enable Sign in with Apple for **com.maksym1503.veil** in your Apple Developer account, and regenerate the matching provisioning profile. Preserve your local DEVELOPMENT_TEAM.
2. Configure Supabase's Apple provider with the real native bundle identifier; follow the [official provider guide](https://supabase.com/docs/guides/auth/social-login/auth-apple). Use the appropriate App ID / Services ID for each client, rather than inventing an identifier or callback domain.
3. Generate an Apple client-secret JWT using your real Team ID, Apple Key ID and `.p8` key through established Apple tooling. Configure **server-only** `APPLE_NATIVE_CLIENT_ID=com.maksym1503.veil` and `APPLE_CLIENT_SECRET`. Do not commit a private key/JWT. Apple client secrets expire: schedule rotation before expiry (at most six months), and verify the token-exchange/revocation endpoints with a real test account.
4. Native Apple authorization exchanges a nonce-bound ID token through Supabase Auth. The short-lived authorization code is separately exchanged **on the server** for a revocation refresh token, bound to the same Apple subject, and stored in Supabase Vault. No OAuth code, OCR text or token is logged.
5. Test first authorization, Hide My Email, returning login without name/email, revocation in Apple settings, restoration and in-app deletion. Account deletion closes upload permissions, revokes Apple via `/auth/revoke`, removes private storage including incomplete uploads, then deletes Auth identity (cascades metadata and transactionally cleans Vault). Network/provider failure leaves a retryable account state; missing Apple revocation credentials require reconnecting Apple and retrying. Never claim deletion success on error.
6. Review [Apple TN3194](https://developer.apple.com/documentation/technotes/tn3194-handling-account-deletions-and-revoking-tokens-for-sign-in-with-apple), configure provider notifications where applicable, and implement operational handling/retention for provider-side revocation or support deletion requests before production.

## 3. Google

1. Create an owner-controlled Google Cloud OAuth consent screen and web OAuth client for Supabase. Choose the appropriate testing/production audience; list authorized test accounts until publishing.
2. Add the **actual** Supabase project Auth callback to Google authorized redirect URIs; get it from the Supabase provider dashboard. Store Google client secret in Supabase Auth configuration, never iOS.
3. Enable Google in Supabase Auth. Allow the exact app redirect **veil://auth/callback** in Supabase's redirect allow list; avoid broad wildcard redirects. Test the supported Google OAuth/PKCE flow through ASWebAuthenticationSession, cancellation, wrong routes and token refresh. The app uses an ephemeral browser session and validates the callback scheme/host/path/code before SDK exchange. Provider OAuth state is managed by Supabase; PKCE is generated/stored by the official SDK.
4. No separate Google SDK, custom password form, mandatory name or duplicated email profile field is added. Google/Supabase can receive account email/name as identity data; disclose this. Revoke unnecessary provider grants via the provider's supported account controls; Veil requests no Photos/Drive scope.

## 4. iOS public configuration

Create the **gitignored** `Configuration/VeilBackend.plist` containing string values:

| Key | Value you must supply |
| --- | --- |
| SupabaseURL | The real HTTPS project root URL, with no path/query/fragment |
| PublishableKey | Real `sb_publishable_…` client key; secret/service keys are rejected |
| RedirectURL | `veil://auth/callback` |
| AppleCapabilityEnabled | `YES` only after Apple capability/profile setup |

The build copies this optional file into the app. It is public configuration; never insert secrets. Set **VEIL_ENTITLEMENTS_FILE = Configuration/Veil.entitlements** in your local build configuration after enabling the real capability. The default empty setting keeps local-only signing usable. Add the real public Privacy/Terms/Support URLs to `VeilPublicLinks`. Do a clean build when changing configuration. `Configuration/*.local.xcconfig`, `.env*`, `.p8` and `.p12` are ignored. Git ignore is not a secret scanner: inspect staged changes.

## Sync semantics and recovery

- Signing in alone does not enable sync. Explicit opt-in is stored per identity; sign-out disables it. Existing unlinked processed gallery outputs are included in the consent dialog. Originals/source asset files and OCR never sync. Outputs can still contain any details the user left visible.
- Stable UUID paths: `userID/editID/processed.jpg` and `thumbnail.jpg`. Files upload before metadata commit. Retrying replaces the same paths/row. One task runs while the app is active, with a 60-second retry and manual Sync now. No background entitlement or distributed queue.
- Local saves succeed first. Deletes persist local owner-scoped tombstones; server deletes create remote tombstones and remove files. Remote deletion wins. Tombstone metadata is retained for cross-device convergence until account deletion; confirm/document any production retention policy before pruning it.
- Interrupted uploads can leave unreferenced private objects; retry or item/account deletion cleans known namespaces. Establish an owner-run orphan cleanup policy for abandoned uploads before public launch. Turning sync off halts future work; an in-flight transfer may already have sent bytes. It does not delete existing cloud copies.
- Signing out/account deletion never deletes local photos. Local files previously tied to another/deleted identity never silently upload to a different account. Delete local history is a separate action; cloud copies may download again if sync is subsequently enabled.
- No end-to-end encryption claim. HTTPS, private buckets, RLS and Vault protect transport/access/secrets; the service operator and backups remain part of the trust/retention model.

## Production acceptance (not yet executed)

Use two real isolated test accounts: A cannot SELECT/INSERT/UPDATE/DELETE B metadata or GET/POST/upsert/delete B Storage paths using authenticated requests; no anon access/public bucket link. Test 200+ items/pagination, offline save, interrupted upload, delete during sync, disable/sign-out during sync, expired session, app kill/relaunch, remote tombstones, cloud-only deletion, Apple account deletion/revocation and retry at each server step. Confirm objects/profile/gallery/Auth/Vault cleanup, billing/rate limits, restore behavior, server logging and backup retention. Run Deno checks and SQL tests before deployment. Do not enable production account/cloud UI until these pass.
