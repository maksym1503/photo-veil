# ADR-003: Product quality and failure-safe lifecycle

Status: accepted for reversible local implementation, 2026-10-10. CTO consulted before implementation. ADR-002 commercial and owner gates remain in force.

Keep the existing renderer, UIKit canvas geometry, actors, protected gallery format, authentication providers and test layers. Improve presentation using native SwiftUI, ephemeral guidance and state-driven feedback; do not add persisted onboarding or a service.

Disable runtime cloud synchronization before awaiting a consent write. A failed write suppresses restoration for that user during this process; only successful explicit enable removes suppression. Match consent generations and identity before publishing completion. Dependent cloud/local destructive flows abort if disabling cannot persist. Report failure honestly; a process restart may restore the last successfully saved preference, so the error must explain retrying before closing the app.

Imports use cancellation plus generation guards, because detached decoding need not stop immediately. Exports are single-flight and snapshot the existing composed layers. Check the session before beginning a destination and before publishing completion. An already-started Photos/gallery save may complete after closing the photo; never claim cancellation reverses it. Remove obsolete temporary exports.

Gallery saves await coalesced opening and retry transient opening failure. Opening failure differs from empty history. Reload committed metadata after a deletion failure and keep error recovery visible. Decode failure must terminate loading.

Do nothing leaves privacy/failure bugs; replacing auth/storage or buying a service adds unnecessary complexity and migration risk. No schema/provider/dependency or irreversible change is approved here. Physical device, real provider, StoreKit sandbox, legal/public URLs, pricing/allowance and distribution remain owner gates.

Validation: existing deterministic core and native PR layers, targeted editor/gallery/accessibility integration, independent read-only review and QA. Preserve V4 merge/physical acceptance gate and all existing tests.
