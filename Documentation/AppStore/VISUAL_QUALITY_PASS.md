# Visual quality pass — 2026-10-11

Scope: STANDARD presentation work; no rendering, metadata policy, storage format, account, billing or provider architecture changes. Keep metadata remains the new-session default. Original photos remain unchanged. Existing working-tree/signing edits and the V4 owner acceptance gate were preserved.

## Screenshot audit and design decisions

Actual iPhone 13 mini / iOS 26.5 Simulator screenshots were captured before implementation, using approved synthetic fixtures and code-native artwork. The independent presentation reviewer inspected the affected states and critiqued the composition before root implemented changes.

| State | Observed problem | Composition change |
| --- | --- | --- |
| Home, four hero stages | Floating portrait, purposeless moon and barely visible location glyph; watermark example was obscure. | A photo illustration with layered scenery, a prominent generic map fragment and attached/removed location label, brighter concealment outline and a legible PRIVATE COPY stamp. Tap-controlled stage changes retain native animation, haptics and Reduce Motion behavior. No coordinates or device location are used. |
| Metadata, Keep/Remove | Small choices clustered at the top of a mostly empty panel. | Two generous open rows, short supporting copy, aligned symbols and clear selected checkmarks; centered inside the existing panel. At accessibility text sizes, decorative leading icons and visual captions yield space to full titles and checks; descriptions remain in each native button’s accessibility value. |
| Empty Watermark | Add action sat too high, with an unnecessary AA icon and vague caption. | Centered stamp preview, text-only Add watermark action and one short usage-control caption. Active watermark controls remain intact. |
| Original comparison | Control sat outside the portrait photo’s visual edge. | Inset derives from the aspect-fit photo width and a minimum native chrome margin. Zoom/pan state is preserved. |
| Done | Active tool controls remained visible, repeating an already-made metadata choice. | Distinct Ready to share review, concise policy summary with change action, optional watermark status and prominent Save/Share actions. Edit returns to tools. The photo viewport and panel footprint stay stable. |
| Gallery selection | Sparse count and icon-only destructive action were widely separated. | Centered compact count plus labelled Delete in a native safe-area footer, retaining separate Cancel and disabled empty-selection behavior. Accessibility sizes stack the two elements. |
| Single/multiple deletion | Intrinsic-width destructive button and fixed-height sheet left unused space. | Full-width, centered 44-point actions and content-measured normal-size detent; scrolling and accessibility-size presentation retained. |

## Review and validation

- Native PR: **77/77 passed**, no missing/skipped/expected failures; exact required execution inventory verified. `/tmp/veil-design-pr-final.xcresult` and `.log`.
- Dark compact targeted Integration initially **8/10 passed**; the two gallery failures exposed a native ToolbarItem merging the count and nested Delete into a single accessible button. A view-level safe-area footer corrected the product accessibility issue; both cases then **2/2 passed** in `/tmp/veil-design-gallery-fixed.xcresult`.
- Final compact screenshots/behavior: **4/4 passed** in `/tmp/veil-design-final-captures.xcresult`, covering normal/largest gallery, largest-text review and largest-text home/guide/help. Screenshot critique prompted stable hero labels, a legible preview caption and shorter AX review; Save/Share are asserted hittable without scrolling.
- Final AX Metadata layout: **1/1 passed**, `/tmp/veil-design-metadata-ax-final.xcresult`. Both choices are hittable, non-overlapping and above the pillar bar; Keep/Remove round-trip and final-review action visibility pass. Actual screenshots show full words and both choices in view.
- Light iPhone 17 Pro / iOS 26.5: **2/2 passed**, `/tmp/veil-design-light.xcresult`; hero, metadata, watermark, final review, single/multi-delete and actual Photos/Share workflows. Taken together, all **10 distinct selected Integration cases** have passed; this is not a full 111-case Integration run.
- PR preceded the isolated footer/hero/AX presentation corrections; targeted Integration above validates those deltas. Rendering/export/metadata/persistence contracts did not change.
- Final unsigned Simulator **Release passed**; fixture-exclusion check passed. `/tmp/veil-design-release.log`, `/tmp/veil-design-release-check.log`. This is not a signed device archive.
- Repository validator: **119 Swift methods**, existing layers preserved. Swift parsing and `git diff --check` passed; no new test methods, timeout increases, skips or retry of unchanged failing code.

The separate read-only visual reviewer accepted light/dark, all affected standard states and accessibility-size Metadata/review/gallery after recapture. Minor retained tradeoff: Original overlays the portrait photo when there is no letterbox space; it follows the fitted-photo leading edge without shifting the viewport. At the largest text size, lower-priority review explanatory text may require scrolling; both primary actions fit.

| Comparison | Before | After |
| --- | --- | --- |
| Hero | [Before](Evidence/visual-before-hero.png) | [After](Evidence/visual-after-hero.png) |
| Metadata | [Before](Evidence/visual-before-metadata.png) | [After](Evidence/visual-after-metadata.png) |
| Final review | [Before](Evidence/visual-before-review.png) | [After](Evidence/visual-after-review.png) |
| Gallery selection | [Before](Evidence/visual-before-gallery.png) | [After](Evidence/visual-after-gallery.png) |

[AX Metadata](Evidence/visual-after-metadata-largest.png), [AX review](Evidence/visual-after-review-largest.png), [light hero](Evidence/visual-after-hero-light.png). These are original running-app attachments; hero captures include transition frames, not static marketing artwork. Only approved synthetic fixtures and code-native art are present. [Attachment provenance](Evidence/visual-screenshots.json), [machine-readable results and source fingerprints](Evidence/visual-validation.json).

The initial baseline gallery capture reached all requested states, then exposed an ambiguous Cancel query (gallery toolbar and confirmation). A specific confirmation identifier resolves that test ambiguity. Initial implementation compilation caught an escaping ViewBuilder requirement. PR execution then exposed an accessibility defect: an explicit element-group modifier moved each metadata identifier onto an Other wrapper instead of its native Button. A diagnostic accessibility-tree capture confirmed this; the grouping modifier was removed. Hidden sizing content and visible panels are separated, with overlays retaining the original layout footprint. Screenshot review also caught visual title hyphenation at largest text sizes; reclaiming decorative/caption space fixed it while retaining full accessibility descriptions. Failed/interrupted logs and completed bundles are retained (Xcode could not finalize every interrupted bundle); no timeout increase or unchanged retry was used.

Root acted as Engineering Lead, implementer and test operator. The existing presentation thread acted read-only as independent Product Design / Visual QA for this pass and did not implement these changes. The stronger CTO reviewer was unavailable due to a usage limit; this fallback is disclosed and does not count as a completed CTO review. No new architecture decision or owner approval is required for this reversible UI scope.

## Release boundaries

Simulator appearance is not physical VoiceOver, motion/haptic, color or performance acceptance. Full 111-case Integration, opt-in performance profiles, signed-device archive and the existing physical-device/V4, public legal/support, provider and commerce gates remain release-candidate requirements. No service or distribution was activated.

## Targeted watermark refinements — 2026-10-12

FAST pass, root implementation/visual QA only. The hero’s PRIVATE COPY lettering is now translucent, clipped and transformed with the illustrated photo, without a badge background, border or glow. Its appearance uses the same concealed state as the existing blur, eliminating the separate stage-three delay. Illustration geometry, blur/unblur, location transitions, tap/automatic animation timing and Reduce Motion behavior are unchanged. The Illustrative preview label and empty editor’s PRIVATE COPY decoration were removed. Add watermark still creates the existing PhotoWatermark default, “For verification only”; editing/rendering/privacy behavior is unchanged. No owner input or external action was needed.

Actual compact dark iPhone 13 mini / iOS 26.5 captures reviewed: [home](Evidence/watermark-refinement-home.png), [empty watermark](Evidence/watermark-refinement-empty.png), and the default text visible in `/tmp/veil-watermark-refinement-shots/F6F9E9D7-27D1-4A5A-97D0-2E8E24FAC210.png`. The three existing targeted UI cases passed: landing animation/Reduce Motion, largest-text watermark controls, and custom text/styles/gallery/Photos/Share. Exact executed case results verified in `/tmp/veil-watermark-refinement.xcresult`; logs and attachments use the same prefix. The run contains a long host-clock interruption during AX text-sheet presentation; it is correctness/appearance evidence, not latency or performance evidence. Existing test source is unchanged; temporary additional capture/assertion edits were removed. No full suite or Release build was repeated for these two presentation-only edits. Earlier screenshots/validation above remain historical.
