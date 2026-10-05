# V4 security and data-flow review

Scope: app code, linked Auth product, SQL ownership rules and server deletion handlers. This is a focused implementation review, not a penetration-test certification. Real provider/Storage/Vault acceptance remains owner-controlled; see [backend setup](../Backend/BACKEND_SETUP.md).

## Boundaries

| Flow | Data / destination | Consent and protection |
| --- | --- | --- |
| Local editor | Picker-selected pixels and transient Vision/OCR results in memory | No account, network or broad Photos read permission. Analysis does not log recognized strings. |
| Save to Veil | Processed JPEG, 384-pixel thumbnail and versioned metadata | Explicit save; Application Support, complete file protection, backup exclusion. No source-photo cache. |
| Share | Processed JPEG in a unique temporary export folder | Complete file protection; cleaned after dismissal and on next launch, including obsolete V3 export files. Recipient apps are outside Veil's control. |
| Save to Photos | Processed JPEG to the system library | Add-only authorization requested on the action. Photos/iCloud retention belongs to system settings. |
| Optional account | Provider identity and optional display name | Native Apple nonce, official Auth PKCE/refresh, Keychain when-unlocked/device-only session storage. No mandatory profile form. |
| Optional sync | Processed JPEG/thumbnail, dimensions, effect, timestamps and UUID ownership | Separate explicit opt-in per identity, private authenticated Storage, HTTPS and Postgres RLS. No original or OCR upload. |
| Apple deletion credential | Provider refresh token on server | Server-only exchange and Supabase Vault. Private schema/service-only functions; never a client secret. |

Processed photos may still contain information the user did not conceal. Managed storage is **not end-to-end encrypted**. Provider/operator access, server request logs, backup retention, region and legal processor terms need owner review before production. No analytics/tracking SDK or app payload logging was introduced. Default unconfigured builds instantiate no network/auth client.

## Checks and fixes

- Metadata and Storage SELECT/INSERT/UPDATE/DELETE policies use authenticated owner checks and exact user/item paths. Ownership is immutable. Private bucket limits JPEG objects to 50 MiB.
- Deletion closes cloud write permissions before deleting objects/identity. Clients cannot reopen or delete/recreate a closed profile to bypass that gate. Remote tombstones prevent a stale device from resurrecting a deleted item.
- Server functions authenticate bearer tokens themselves, derive ownership from the verified identity and reject unauthenticated calls. They do not trust a submitted user ID. Partial failure returns an error and is retryable; it never reports deletion success prematurely.
- Apple revocation occurs before Auth deletion. Vault cleanup is transactionally tied to Auth deletion; a failed Auth deletion preserves the revocation credential for retry. SQL tests check the service-only boundary using a clearly isolated test double, not production Vault encryption.
- Explicit cloud-only deletion persists keep-local intent before contacting the server. A subsequent remote tombstone neither deletes those retained local files nor silently uploads them again; ordinary gallery deletion still propagates.
- Signing out stops sync and retains local history. Local items tied to one account never silently upload under another. Persisted consent is per account; signing in alone does not upload.
- SDK PKCE and nonce handling replace custom authentication. Browser callbacks must match the exact route and contain one authorization code; token fragments are rejected. Tokens/OAuth payloads/private URLs are not logged. Ephemeral URLSession disables disk cache/cookies.
- App-switcher covering applies to the window, including sheets. Real-device snapshot timing must still be checked.
- Gallery deletion removes metadata and files; valid-index orphan cleanup handles interrupted local saves. Corrupt/unknown metadata is preserved and reported rather than erased. Schema version 1 rejects unsupported versions pending explicit future migration.
- All eight UI-test JPEG resources are excluded from Release. An unused legacy QAStreet asset was removed from the production asset catalog. Test fixtures and screenshots live in Tests/Documentation; UI injection flags are DEBUG-only.
- Public config is optional and ignored by Git; only `sb_publishable_` keys are accepted. Entitlement configuration is opt-in. Owner's local DEVELOPMENT_TEAM changes were preserved and excluded from commits. No project was provisioned and no secret was fabricated.

## Acceptance limits

Deterministic mocks cover offline/editor independence, auth lifecycle and sync retries/deletes. SQL role tests exercise actual migrations on an isolated PostgreSQL database. HTTP-mocked server tests cover identity spoofing, unauthorized access, deletion order and failures. These do not replace real two-user Supabase Storage API tests, real Vault, Apple/Google UI, expired credentials, provider revocation, multi-device sync or device file-protection tests.

Before public launch, choose quotas/rate limits, abandoned-upload cleanup, provider notification handling, server logging policy and backup/tombstone retention. This release is a draft pending those owner decisions and physical validation.
