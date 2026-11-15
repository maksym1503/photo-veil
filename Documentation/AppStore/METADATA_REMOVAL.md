# Photo metadata choice

Choose **Remove metadata** or **Keep metadata** in the Metadata tool. After Done, review the choice and save or share; tap the summary to change it. Remove omits source location, capture date/time, camera/device details, descriptive metadata, comments and embedded previews. Keep preserves supported source details, including location when available. JPEG re-encoding cannot retain every tag: original previews, auxiliary images, opaque application data and unsupported comments are excluded; orientation, dimensions and color information are rebuilt. The choice follows Save to Photos, Share, the saved gallery copy and future cloud sync, including thumbnails. Originals stay unchanged. Basic image-format information remains, and Photos or receiving apps may add dates or identifiers.

Keep is visibly selected for each new photo (owner-requested polish, 2026-10-11). Returning to editing retains the current session choice. The final review describes the selected mode, including when no supported metadata is available. Gallery detail shows the choice saved with that copy. There is no new settings screen or permission.

## Preservation limitations

Keep preserves supported source details, including location when available. JPEG re-encoding cannot retain every tag: original previews, auxiliary images, opaque application data and unsupported comments are excluded; orientation, dimensions and color information are rebuilt. Metadata means fields available in the system picker representation, which may differ from the original Photos asset. Exact byte-for-byte EXIF/IPTC/XMP/comment preservation is not promised. A source ICC profile, HDR/depth/Live Photo components, original embedded preview or proprietary MakerNote may be unsupported by a rendered JPEG. The supported native fields are explicitly allowlisted in `SourcePhotoMetadata`; unrecognized opaque payloads are not copied. Normalized pixels require orientation 1 and new dimensions. The output remains standard sRGB JPEG.

Existing files and previously uploaded/shared copies are not rewritten. Older gallery entries without a saved choice use Remove. Metadata already removed from an older copy cannot be recovered. Gallery/cloud operational dates and identifiers remain separate from embedded photo metadata.

## Architecture and failures

[ADR-005](../Engineering/Decisions/005-optional-photo-metadata.md) supersedes mandatory removal. A privately constructed `PhotoExport` contains bytes, actual dimensions and chosen policy. Import captures only a supported metadata snapshot alongside pixels in memory. Encoding runs off-main; no original-file cache is added. Destinations accept the same policy-bearing output. Remove failures never export unsanitized bytes; Keep failures never silently fall back to Remove. Empty available metadata is explained rather than invented.

Local indexes add an optional policy without rewriting existing files. Cloud records need the additive `202610100001_metadata_policy.sql` migration before optional configured sync uses this client; no migration is deployed by this task. Missing legacy policies mean Remove; unknown values fail decoding. Consent/cancellation is rechecked immediately before upload.

## Verification

Synthetic fixtures exercise both branches, supported metadata, normalized orientations/dimensions, absent original previews, gallery persistence/re-export, cloud round-trip and failure handling. Current results belong in [release readiness](RELEASE_READINESS.md); prior always-on evidence is historical. Physical Photos Info, large-photo/color/memory, configured two-device sync and archive checks remain release gates.

Native references: [ImageIO destinations](https://developer.apple.com/documentation/imageio/cgimagedestination), [image properties](https://developer.apple.com/documentation/imageio/cgimagesourcecopypropertiesatindex(_:_:_:)).
