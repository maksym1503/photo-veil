# ADR-004: Source metadata removal on every exported copy

Status: superseded by [ADR-005](005-optional-photo-metadata.md), 2026-10-10. Historical mandatory-removal decision. CTO consulted before implementation; the owner explicitly requested the feature. Reversible local implementation, no provider or release activation.

Metadata removal is always on. Use a native ImageIO pixel-only JPEG encoder with an opaque standard sRGB raster; never copy source properties, metadata, ICC descriptions, embedded previews or auxiliary images. A privately constructed typed result travels to Share, Photos and local gallery, avoiding repeated compression within a new editor export. Existing/downloaded gallery bytes are normalized for all eight EXIF orientations and reconstructed before new storage or outbound copies, including future cloud uploads. Fail closed; no original-byte fallback.

Keep originals and existing files intact. No gallery schema or destructive migration. Existing cloud/Photos/shared copies are not retroactively cleaned. Gallery/cloud operational dates, dimensions, ownership and IDs remain separate from embedded photo metadata. Previously saved JPEGs may be recompressed for a new export. Run decoding/encoding on existing detached tasks or the gallery actor, never the main actor.

Product claim: “Source metadata removed.” Explain removal of embedded location, capture-date, camera/device and descriptive metadata, including EXIF/IPTC/XMP/comments and previews. Dimensions, standard encoding/color information remain; Photos/recipients may add dates/identifiers. Visible image content still needs review. No optional switch, permission, analytics, dependency or network requirement.

Doing nothing cannot support a verified privacy promise; deleting selected tags may miss unfamiliar metadata; a third-party library is unnecessary. Native pixel reconstruction is the smallest robust boundary. Validate tagged synthetic fixtures, metadata/marker absence, orientations and appearance, gallery/legacy/cloud boundaries, failures, native save/reopen and UI guidance. Physical Photos inspection/performance and existing V4 release gates remain required.
