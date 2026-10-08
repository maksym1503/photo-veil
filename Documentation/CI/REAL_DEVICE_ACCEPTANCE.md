# Physical iPhone acceptance — bounded pilot

Decision reviewed 2026-10-08: **prepare BrowserStack App Automate XCUITest as an opt-in pilot**, retain the owner's iPhone as authoritative system-UI acceptance until the pilot proves those capabilities. Do not purchase a plan or upload a build automatically. Sauce Labs is a credible alternative; Veil does not need two paid device clouds or an Appium migration.

| Concern | BrowserStack App Automate XCUITest | Sauce Labs XCUITest |
|---|---|---|
| Native / hardware | Native XCUITest on physical iPhones; REST upload/build API | Native XCUITest via saucectl; physical iPhones and simulators |
| iOS versions | Select exact device–OS pair from current catalog; do not assume latest availability | Device name/platform-version matching; consult current real-device catalog |
| Parallelism | Test filtering and sharding; concurrency depends on purchased plan | Suites/shards and parallel devices; plan concurrency applies |
| Evidence | Video, device/test logs, screenshots; optional native xcresult | Video, screenshots, device/framework logs and job results |
| Signing | Upload app IPA + zipped runner app; provider normally re-signs. Test entitlement-dependent features separately | Upload app/runner artifacts; provider re-signing or correctly provisioned private-device setup |
| Photos / system UI | Must pilot add-only permission/save and Share; reset state/provider restrictions can affect OS dialogs/extensions | Same need for capability pilot; public device account/system restrictions vary |
| GitHub / Xcode | REST adapter needs no new app dependency; native Xcode build-for-testing output | saucectl + YAML integrates in CI; extra CLI/config lifecycle |
| Privacy | Test builds, fixtures and recordings leave owner infrastructure; retention/access review required | Same disclosure/review; account region/private-device options require quote |
| Small-project overhead | Small REST adapter, single manual job, one accepted flow | Good if already using Sauce; no existing investment here |
| Published cost snapshot | App Automate headline starts at $199/month; exact concurrency, billing term and real-device entitlement must be confirmed | Real Device Cloud advertises $199/month annual billing or $249 monthly for one parallel device; verify current checkout/contract |

These are published starting prices, not estimates of Veil's bill. Catalog, pricing and terms change. Review the actual quote, region, retention and subprocessor/DPA terms before enabling. BrowserStack wins this pilot narrowly because native results and REST filtering fit the repository without a new runner dependency; no claim is made that its physical devices are inherently more accurate than Sauce's.

## Implemented acceptance

`VeilDevice.xctestplan` selects exactly `VeilDeviceAcceptanceTests/testRealVisionComposedPrivacySaveAndReopen`. It uses **real Vision**, explicit approved bundled fixture import (not the deterministic analyzer), Faces → Plates while Faces persist → Manual while both persist → Done → pixel fingerprint parity → Save to Veil → relaunch → reopen output with screenshots. Local history is UUID-isolated. Native renderer tests protect decoded-pixel semantics; the physical screenshot/reopen checks supplement those assertions. The bundled fixture is deliberate: provider PhotosPicker seeding is a separate capability to establish, not faked as a system import.

The full 35-test UI suite is not uploaded/run for every commit. Physical PhotosPicker import, Save to Photos permission/save, Share extensions, Reduce Motion and actual privacy output inspection remain on the owner's acceptance checklist until the provider pilot verifies them. Existing Integration tests retain Photos/Share coverage. Do not silently mark unsupported provider flows green.

## One-time pilot setup

1. Owner chooses provider plan/region and approves processing **only repository-approved redistributable/synthetic fixtures**. Verify retention: BrowserStack currently documents video 30 days and other logs 60 days. Set shorter retention/delete artifacts where supported; never upload real user photos, OCR documents, backend credentials or production sessions.
2. In GitHub create protected environment **real-device-acceptance** with owner approval and secrets `BROWSERSTACK_USERNAME`, `BROWSERSTACK_ACCESS_KEY`. Restrict it to trusted branches. Provider secrets are never passed to fork PRs. The Actions workflow is manual only; uploading the app is a separate explicit owner action.
3. In Xcode choose Debug (fixture hooks are intentionally absent from Release), PhotoVeil scheme, VeilDevice plan. Build for testing on `generic/platform=iOS` with your actual development team/provisioning. Do not use `CODE_SIGNING_ALLOWED=NO` for physical artifacts. Ensure both app and PR test runner are signed. No signing identity/UDID is invented here.
4. Package the built app as **app.ipa** (`Payload/PhotoVeil.app`), and zip the built **PhotoVeilPRUITests-Runner.app** at zip root as **tests.zip**, following the provider's current upload instructions. Use only the current checkout's products; never rename simulator products as device IPAs. The test runner contains the selected device acceptance class; `only-testing` explicitly filters out other classes.
5. Upload the signed app and runner **directly to the provider from the trusted signing machine**, using its app/test-suite upload APIs with credentials in a private local environment. Do not place signed IPAs/provisioning profiles in this public GitHub repository's Actions artifacts: development profiles can expose device identifiers. Record the built full SHA, archive checksums and returned provider app/test-suite references in your private acceptance record. This is an owner-approved provenance statement, not binary attestation fabricated by CI.
6. In protected environment secrets set `BROWSERSTACK_APP_URL`, `BROWSERSTACK_TEST_SUITE_URL` to those returned `bs://` references and `BROWSERSTACK_BUILD_SHA` to the exact built SHA. Choose an available physical iPhone/OS pair from the live catalog. Dispatch **Veil Real Device Acceptance** on that same commit, passing only the device string. The adapter refuses a mismatch between the owner-approved build SHA and GitHub candidate SHA. Update these three secrets together for each candidate. Never reuse an old binary under a new SHA.
7. Adapter selects only the acceptance class, requests native result bundle, disables network logging, polls with a 30-minute bound and fails honestly on failed/timed-out/zero-test/unknown terminal results. GitHub retains only a **sanitized** seven-day status/count summary, with no provider artifact/video/access URLs. Native xcresult/video/logs remain in the provider account; download them to private candidate evidence. On timeout, cancel the provider job in its dashboard using the reported build ID. The optional local CLI path `python3 scripts/ci/browserstack.py app.ipa tests.zip` supports direct streaming upload and execution from a trusted owner machine; it must use products from that machine's recorded candidate SHA.
8. Pilot system flows on a disposable device: first-use Photos add-only permission, saving and reopening output in Photos, Share Sheet availability, PhotosPicker seeded approved image, session/device reset between runs. Check what re-signing strips (especially Apple auth/app-group/keychain entitlements); this local editor acceptance does **not** validate real Apple/Google login.
9. Record physical device model/iOS, SHA, native result, screenshot review and unsupported OS flows in release evidence. If the pilot adds little value, keep owner-iPhone acceptance and remove only the unused adapter in a reviewed future change; do not silently drop its guarantees.

## Owner iPhone acceptance per candidate

- Import approved fixture through real PhotosPicker without broad read permission.
- Faces auto-private; Plates auto-private while Faces remain; Manual while both remain.
- Clear one layer preserves others; re-entry restores cached detections; Undo isolates Manual.
- Done matches editor; Save to Veil/relaunch/reopen matches; inspect sensitive regions.
- Save to Photos: first-use add-only permission, allow, deny/restricted handling; Share remains usable.
- Share to an actual destination; reopen the file and inspect all privacy layers.
- Large image, small faces, Documents, background fallback, offline/local-only, accessibility.

Sources: [BrowserStack upload APIs](https://www.browserstack.com/docs/app-automate/api-reference/xcuitest/apps), [test suite format](https://www.browserstack.com/docs/app-automate/xcuitest/set-up-test-env/upload-test-suites), [filtering](https://www.browserstack.com/docs/app-automate/xcuitest/select-test-cases), [native results/build API](https://www.browserstack.com/docs/app-automate/api-reference/xcuitest/builds), [debug evidence/retention](https://www.browserstack.com/docs/app-automate/xcuitest/set-debugging-options), [BrowserStack pricing](https://www.browserstack.com/pricing), [Sauce native XCUITest](https://docs.saucelabs.com/mobile-apps/automated-testing/espresso-xcuitest/xcuitest/), [Sauce mobile limitations](https://docs.saucelabs.com/mobile-apps/mobile-faq/), [Sauce pricing](https://saucelabs.com/pricing).
