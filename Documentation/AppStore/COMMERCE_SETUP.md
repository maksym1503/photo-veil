> Current catalog reconciliation (2026-10-26): canonical annual identifier is `vail.pro.annual`, verified in Photo Privacy Pro. Previous `vail.pro.yearly` belongs to an obsolete separate group and is not offered/unlocked by the app. [ADR010](../Engineering/Decisions/010-annual-product-identifier.md) supersedes prior identifier instructions. Poland price14.99/month is above target;99.99/year matches. Trials and annual availability remain unconfigured; approval is required for commercial changes. Local `.storekit` target prices/trials are not live Apple settings.

# Native subscriptions and export allowance

Current implementation: [MONETIZATION_IMPLEMENTATION.md](MONETIZATION_IMPLEMENTATION.md). [ADR-007](../Engineering/Decisions/007-freemium-exports.md) supersedes the former inactive, monthly-only, editing-session allowance proposal.

Owner-approved model: **two successful Save/Share operations free**, then unlimited exports with **Veil Pro Monthly** (`vail.pro.monthly`, target 12.99 PLN/month) or **Veil Pro Yearly** (`vail.pro.annual`, target 99.99 PLN/year). Both plans belong to one equal-level subscription group, with a three-day introductory free trial for eligible customers. Apple permits one introductory offer per group. Prices and eligibility shown in the app come from StoreKit.

Local code and Xcode StoreKit configuration are implemented without activating real products or payments. Published Terms/Privacy URLs, Apple enrollment/agreements, App Store Connect configuration and real sandbox/device acceptance remain release blockers. No `VeilCommerce.plist` is required by the new runtime; the legacy parser is retained only for compatibility tests. A legal link alone is not release approval.

See the implementation document for architecture, test commands/results, free-allowance lifecycle limitations, production configuration and the owner release checklist. The existing V4 physical/configured-backend merge gate remains intact.
