# Vail next-release visual review — round-one archive

Status: historical round-one concepts. Maksym selected **A — Editorial Calm** and
**A — Quiet Lattice** for refinement. See the [latest final-review set](FinalReview/README.md) and [prior refinement archive](Refinement/README.md).
The following selection-stage notes describe round one only. No final set, upload, App Store Connect
change or replacement of live screenshots is authorized or performed.

Open [all three directions](all-directions.png) and [preview watermark concepts](preview-concepts.png).
Each direction has two actual 1320 × 2868 PNG mockups and a smaller contact sheet.

| Direction | Visual idea | Tradeoff |
| --- | --- | --- |
| [A — Editorial calm](a-editorial/contact-sheet.png) | Warm ivory, strong black system typography, generous space, large genuine app UI. Recommended for a clear premium product page. | Less dramatic than a full-photo campaign. |
| [B — Midnight studio](b-studio/contact-sheet.png) | Charcoal/navy with restrained cyan glow, dimensional tilted devices and soft shadows, matching the existing cyan/blue identity. | Dark framing reduces the apparent UI size slightly. |
| [C — Photo story](c-photo-story/contact-sheet.png) | Large original synthetic image with the edited running-app result in front, explicit Before/After labels. | Photography dominates; UI is smaller. |

The first two themes are Faces and private details. After selection, the proposed
sequence is: Blur Faces Instantly → Hide Private Details → Remove Location Data →
Take Full Control → Share With Confidence. The remaining three images are deliberately
not produced before approval. Metadata copy must describe the actual Remove choice,
not claim that Keep removes location. Automatic detection remains fallible.

## Premium preview proposals

[A — Quiet lattice](preview-concept-a-lattice.png), recommended: repeated diagonal
`VAIL · PREVIEW` text with a neutral shadow, no broad bands. It leaves the photograph
inspectable while marking multiple areas. [B — Frosted ribbons](preview-concept-b-ribbon.png)
adds translucent backing for steadier contrast over busy images, with more visual weight.
Both include Preview Mode, the reason, and Unlock Clean Exports. These are **presentation
mockups**, not evidence of an implemented commerce watermark. The production implementation
is pending the existing-user quota decision in ADR-013. No screenshots are blocked and
neither pattern promises complete resistance to cropping or other circumvention.

## Provenance and regeneration

`source/render_concepts.swift` composes real native captures into the layouts; app
controls are never reconstructed. The face-capture PNG is 1206 × 2622 and is
proportionally scaled inside the 1320 × 2868 layouts. First screenshots use the new native
Faces capture with **real Vision analysis** in `captures/vail11-faces.png`, captured
by the passing `testNextReleaseFaceMarketingCapture` Integration case. Second screenshots retain
the genuine 1.0 release manual-redaction capture (`captures/details-reference.png`) with a fictional document. That capture
is historical UI evidence, not 1.1 release validation. Contact sheets are comparisons,
not store upload files. No trial/price offer is represented by marketing artwork.

C's background source is the same existing synthetic fixture/document shown in its app
capture. Existing fixture rights/provenance remain in the release evidence. The new
`source/synthetic-cafe.png` was generated with the built-in imagegen tool solely for
preview concept photography: two fictional adult cafe friends and a fictional DEMO /
ALEX SAMPLE card; no customer photos or personal identifiers. The original generation
prompt is retained in `source/image-prompt.txt`. Preview-pattern typography and mockup
layout are reproducible AppKit drawings; they are not app screenshots.

Run from repository root:

```sh
swift Documentation/Marketing/AppStore/NextRelease/source/render_concepts.swift
```

Before final production, recapture the selected direction's whole sequence against
accepted 1.1 UI, verify photo provenance, export opaque RGB assets, and review each
native device/localization size. Apple guidance checked 2026-11-14:
[screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/),
[show your app in use](https://developer.apple.com/help/app-review/guideline-reference/2-3-3-screenshots/),
[accurate metadata](https://developer.apple.com/app-store/review/guidelines/).

Owner action: select A, B or C (or give concrete revision feedback). Stop final-set
production until Maksym explicitly approves a direction.
