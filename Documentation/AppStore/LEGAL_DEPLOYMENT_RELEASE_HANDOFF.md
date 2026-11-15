> Current update, 2026-10-28: the owner deployed the approved package. Public Privacy, Terms and Support at https://veil-legal.pages.dev are verified against the approved files. Live mobile QA passed16/16 states; see `CloudflarePages/2026-10-28-live-qa/QA_REPORT.md` (relative from AppStore). Privacy/Support URLs are saved and read back in App Store Connect and configured for app build1.0(7). The upload blocker and pending-publication statements below are historical. No additional legal-content approval is required. Build/upload results are recorded separately when completed.

# Approved legal deployment and release continuation — 2026-10-28

## Owner authorization

Owner explicitly approved final legal content and Cloudflare publication. Approved public identity: **Maksym Bilyi, Poland**. Approved Support and Privacy email: **veil.app.support@proton.me**. Residential address, phone, personal Gmail and unrelated domains must not appear. Owner reports Paid Applications Agreement accepted, DAC7 completed and DSA Active. These account attestations are owner-confirmed, not independently verified through a web session. No change to EU trader classification is authorized or performed.

## Completed and verified

- Prepared eight-file allowlisted publication folder/ZIP at `CloudflarePages/2026-10-28-approved-publication/cloudflare-pages-public.zip`.
- All legal pages use approved name/country/email and publication date 2026-10-28. No unresolved placeholders/draft banners, residential address or phone. Independent CTO reviewed the actual folder/ZIP/hash manifest and contact scope.
- Corrected publication validation to separate explicitly approved country-only website disclosure from Apple DSA classification. Legacy full-contact validation remains; country-only mode requires explicit approval and rejects populated address/phone/trader-contact fields. This is not a certification of every applicable website-law obligation.
- Packaging regression tests: **11/11 passed**, including explicit disclosure approval, private-contact rejection and actual country-only render. One initial test harness error from macOS temporary-directory symlink ancestry was fixed using the existing tests' resolved-path pattern. No product/privacy guard was weakened.
- Source audit passed. Existing app and monetization logic unchanged; live advertising remains disabled.
- Live Cloudflare project read verified `veil-legal` in separate Veil account `38fb0d48cb0beef413083f534b7cf090`; no pre-existing deployment.
- Live Apple subscription readback: `vail.pro.monthly`, 12.99 PLN/month; `vail.pro.annual`, 99.99 PLN/year; both **READY_TO_SUBMIT** in Photo Privacy Pro. Poland introductory offers: FREE_TRIAL, THREE_DAYS, one period, start 2026-10-26. No commercial settings modified.
- Six draft App Store screenshots read back **COMPLETE**. Subscription readiness validator: zero errors; warnings include pending review and optional promotional images, plus the obsolete unused yearly group. Obsolete resources preserved.
- Updated version 1.0 copyright to `2026 Maksym Bilyi` and release type **MANUAL**. No review submission or public release initiated.

## Actual deployment blocker

`POST /pages/assets/upload` through the official Cloudflare MCP returned HTTP403 / error8000013 (Authorization failed). Getting a project upload JWT succeeds; a subsequent upload using that valid, unexpired, project-specific JWT also returned the same403. No token was printed, saved to the repository or disclosed. No asset upload/deployment succeeded. Do not treat the reserved hostname as published.

The owner has been given the exact dashboard fallback: Veil account → Workers & Pages → veil-legal → Create deployment → Production → upload the approved ZIP → Deploy. The package directory was opened locally. No additional legal approval is needed. This is an account/upload capability step, not a request to approve content again.

## Pending dependent work

After deployment succeeds, verify `https://veil-legal.pages.dev/privacy`, `/terms`, `/support`, HTTPS, redirects, headers, no private-path exposure, mobile layouts, keyboard/accessibility and exact approved content. Fresh live browser checks have **not** run; the browser QA module was unavailable in the default local module path on the earlier check. Do not claim current deployed/mobile verification.

Only after public verification, set ASC Privacy/Support URL fields and `VEIL_PRIVACY_POLICY_URL` / `VEIL_SUPPORT_URL` in app settings. Then increment build6, test the now-open legal purchase gate, archive/sign/Apple-validate/upload to the existing internal group. None of those dependent mutations/builds/uploads has occurred in this continuation. Existing build1.0(6) and previous genuine commerce/export test evidence remain historical, not newly executed checks. Unchanged native suites were deliberately not repeated.

Fresh `asc validate --deep --check-urls` found missing public Support/Privacy URLs, review contact fields (including phone), unattached build, missing copyright (subsequently fixed), and missing content-rights attestation. The cached Apple web session is unavailable, so App Privacy publication, agreements and first-subscription attachment cannot be independently deep-verified. Do not invent reviewer contact or attest content rights on the owner's behalf. Final first-subscription selection and public submission remain separate from internal TestFlight. No app/subscription review submitted.

Private raw read-only CLI evidence remains under `/tmp/veil-legal-release/` (validation, pricing, trial offers and screenshot readbacks), outside public assets. The ignored legal configuration is mode0600; no secrets are present in upload files. No domain or service was purchased or connected.
