# Veil: privacy photo editing and watermarks

Veil has three editing areas: **Redact**, **Metadata** and **Watermark**. Redact contains the existing Background, Faces, Plates, Documents and Manual tools, with Blur, Pixelate and solid Redact. Switching areas changes focus, not active effects or metadata intent.

## Watermark workflow

Choose Watermark → Add watermark for a centered, softly diagonal “For verification only” mark. Edit text or use a purpose-based suggestion; the date suggestion uses today's device date only when chosen, never the source capture date. There is no account-name/location autofill, clipboard read or reusable custom-text history. Light, Dark and Stamp styles, top/center/bottom placement presets, repeated pattern and size/opacity/rotation adjustments are available. Drag with one finger on the photo to reposition; two fingers retain photo navigation. VoiceOver position actions and native controls provide alternatives. Undo applies to watermark edits independently of visual redaction; Reset edits and its Undo cover both.

Watermark text is intentionally visible in the processed image. Review it before sharing, and avoid information you do not want recipients to see. A watermark communicates intended use; it cannot prevent cropping, removal, copying or misuse and is not proof of authenticity. Solid Redact remains appropriate for sensitive visible text; a watermark is not a redaction substitute.

## Export and lifetime

The same normalized composition drives preview and full-resolution output. The watermark is composited above every privacy effect before the existing JPEG metadata encoder. Save to Photos, Share and Save to Veil receive that result. Gallery re-export and optional future cloud synchronization carry the finished pixels without applying the mark twice. Source metadata Remove/Keep is independent, with Keep selected for each new session. Removing metadata does not remove a visible watermark. Originals remain unchanged.

Custom text/settings exist in the current editor and its bounded Undo history only. Closing/replacing the photo clears them. There is no custom-text UserDefaults, local index recipe, cloud text field, telemetry or logging. Saving/sharing deliberately retains the text as pixels, including gallery/cloud thumbnails. The existing protected-file, deletion, temporary-share cleanup and opt-in cloud contracts apply. Debug image evidence for watermarked compositions is disabled unless a separate synthetic-watermark test flag is explicitly supplied alongside UI testing; production builds contain no fixture capture path.

Text is limited to 120 characters, additionally bounded by 512 Unicode scalars and 2,048 UTF-8 bytes. Glyph rasters are capped at 4,096 pixels per side and 1.5 million pixels (approximately 6 MB of RGBA storage); image-space geometry remains independent of that raster cap. Repetition uses at most 64 placements. Normalized coordinates, opacity and rotation are bounded. Unsupported/invalid or failed active rendering blocks export rather than silently dropping a mark. Empty text is rejected on UI commit. Exact output remains the existing sRGB JPEG; source-format/HDR/auxiliary-image limitations remain documented in [metadata scope](METADATA_REMOVAL.md). There is no JPEG intermediate between redaction and watermarking. Small native glyph tiles avoid a second full-frame watermark buffer; physical large-image peak memory and color acceptance remain release gates.

## Acceptance

- Watermark-only and mixed redaction output; no restoration of hidden original pixels.
- All three styles, Unicode, text/resource limits, blank/invalid values, rotation, clipping, repeat coverage and image-space scale.
- Serialized/cancelled previews and export parity; completed preview cache includes watermark state.
- Scoped Undo, global Reset/Undo, direct drag, photo navigation, accessibility alternatives and new-session cleanup.
- Both metadata policies, local save/reopen/re-export, thumbnail preservation and all native save/share destinations.
- No custom text in logs, index JSON, metadata additions or reusable preferences; only deliberately flattened output retains it.
- Existing V4 deterministic and integration cases remain in their current layers; configured cloud and physical 12–48 MP checks remain separate gates.

Architecture: [ADR-006](../Engineering/Decisions/006-three-pillar-watermark.md). Research: [Darkroom placement/adjustments](https://darkroom.co/help/export/watermark), [ZLImageEditor native gesture coordination](https://github.com/longitachi/ZLImageEditor/blob/master/Sources/General/ZLStickerGestureCoordinator.swift), [Apple Core Text](https://developer.apple.com/documentation/coretext). Interaction ideas reviewed; no external editor code, SDK or assets were imported.
