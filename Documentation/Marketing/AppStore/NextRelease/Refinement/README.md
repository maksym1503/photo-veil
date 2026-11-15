# Editorial Calm + Quiet Lattice — refined owner review

Maksym selected both A directions for development. These assets are **new review
candidates**, not approved production assets. No publication, App Store Connect
change, replacement of live screenshots, release or merge is authorized/performed.

- [Five screenshot candidates](editorial-contact-sheet.png)
- [Actual light/dark preview comparison](quiet-lattice-contact-sheet.png)
- Individual opaque RGB JPEGs: `editorial-calm/01-faces.jpg` through `05-share.jpg`.
- Unaltered running-app screenshots: `captures/`.

## Changes from round one

The cream background and concise editorial type remain. A wide, focused crop of
the original photo supplies a clear Before reference, followed by a larger native
app screen showing the implemented result. Device edges and a short displaced
shadow add restrained physical depth. No controls, selection rectangles, processed
pixels or subscription prices are fabricated by the artwork renderer.

| Screenshot | Actual implemented feature | Distinct synthetic photograph |
| --- | --- | --- |
| Blur faces. Instantly. | Real Vision face detection; actual blurred result with editable detection handles. | New cafe portrait of two fictional adults. |
| Hide private details. | Real plate detection and blur. | Existing synthetic street/car scene and fictional TEST482 plate. |
| Leave location behind. | Actual Metadata tool with Remove selected; exports omit supported source metadata. | New coastal travel photograph with fictional GPS0/0 added to the demo fixture. |
| Take full control. | Two manually drawn solid-redaction regions, using real image coordinates and native controls. | New photographed reservation card with ALEX SAMPLE / DEMO482, entirely fictional. |
| Share with confidence. | Actual final-review UI and available Save/Share actions; real blurred faces. | Existing synthetic park portrait. |

Before strips are deliberately cropped feature references, not a claim that the
entire image is the crop. Third-shot location data is not visually embedded in the
photograph; its Before label reflects the source fixture's actual GPS field.
Remove is the chosen export policy; it does not modify the original. Photos or a
receiving app may add their own dates/IDs. Automatic detection remains fallible.

## Quiet Lattice in the application

The lighter lattice is now implemented as native **presentation**, using small
white labels with a subtle gray outline, repeated in screen coordinates over the
visible photograph. It follows zoom, pan and layout, is noninteractive and has
one accessibility label. It does not enter Core Image layers, originals, exported
JPEGs, gallery pixels/thumbnails or cloud files. Valid verified Pro is clean.

Preview Mode explains the exhausted allowance. Unlock Clean Exports uses the
existing native glass/capsule action style and opens the existing StoreKit paywall,
including Restore Purchases and genuine product/offer eligibility. Dismissal leaves
the marked preview available. Unknown verified-access state uses an opaque checking
cover; storage failure is explained without claiming that a free export was used.
Native invalidation covers stale frames before SwiftUI reconciles foreground state.

The light/dark images are **actual app captures after successful exports exhausted
the current two-export allowance**. They show real redacted photos, native pattern,
reason and CTA; no pattern or CTA is added by the artwork renderer. The separate
migration to one export remains awaiting the owner's existing-user decision.
No quota reset or threshold change is included in this refinement. After migration
approval the pattern automatically follows the shared allowance's configured limit.

## Sources and regeneration

Built-in imagegen created the new coast/card/night photos; the previously generated
cafe photo is reused. Prompts and source PNGs are in `source/`. Existing street/park
fixtures retain repository provenance. These are synthetic demonstration images,
not customer photographs, real customer documents or real location history.

`source/prepare_fixtures.swift` encodes the approved source photos as test JPEGs.
Only the coast gets a fictional GPS0/0 placeholder. The four marketing fixtures are
Debug-only resources, explicitly excluded from Release. Captures use the production
Vision analyzer, session, controls, renderer and successful Save-to-Veil accounting;
there is no injected quota/Pro state or substituted detector for these captures.

After capturing `PhotoVeilUITests/testRefinedEditorialAndPreviewJourney`, export the
native attachments into `captures/` and run from repository root:

```sh
swift Documentation/Marketing/AppStore/NextRelease/Refinement/source/render_refinement.swift
```

The renderer retains actual UI pixels and adds only the surrounding marketing
composition. Output candidates are1320 ×2868 JPEGs with no alpha channel. Contact
sheets are review aids. `manifest.json` records sources, capture provenance and
hashes. Test/review evidence is under `Documentation/QA/NextRelease/Refinement/`.

Owner action: review these refined screenshots and the light/dark native lattice.
Approval of directions is recorded; final asset approval is still required.
App publication, live screenshot replacement and release merge require separate
explicit authorization. The one-export migration remains a separate owner decision.
