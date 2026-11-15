import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let base = root.appendingPathComponent("Documentation/Marketing/AppStore/NextRelease/FinalReview")
let captures = base.appendingPathComponent("captures/light")
let out = base.appendingPathComponent("editorial-calm")
try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
let ink = NSColor(calibratedRed: 0.055, green: 0.10, blue: 0.13, alpha: 1)
let blue = NSColor(calibratedRed: 0.03, green: 0.39, blue: 0.93, alpha: 1)
let paper = NSColor(calibratedRed: 0.966, green: 0.965, blue: 0.949, alpha: 1)
func text(_ value: String, in r: NSRect, size: CGFloat, color: NSColor = ink, weight: NSFont.Weight = .semibold) {
    let p = NSMutableParagraphStyle(); p.lineSpacing = -1
    (value as NSString).draw(in: r, withAttributes: [.font: NSFont.systemFont(ofSize: size, weight: weight), .foregroundColor: color, .paragraphStyle: p])
}
func render(_ url: URL, w: Int = 1320, h: Int = 2868, jpeg: Bool = false, draw: () -> Void) throws {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)!
    paper.setFill(); NSRect(x: 0, y: 0, width: w, height: h).fill()
    draw(); NSGraphicsContext.restoreGraphicsState()
    try bitmap.representation(using: jpeg ? .jpeg : .png, properties: [.compressionFactor: 0.97])!.write(to: url)
}
func round(_ r: NSRect, _ radius: CGFloat, _ color: NSColor) {
    color.setFill(); NSBezierPath(roundedRect: r, xRadius: radius, yRadius: radius).fill()
}
func pill(_ value: String, x: CGFloat, y: CGFloat, width: CGFloat) {
    let r = NSRect(x: x, y: y, width: width, height: 42)
    let shadow = NSShadow(); shadow.shadowColor = .black.withAlphaComponent(0.12); shadow.shadowBlurRadius = 6; shadow.shadowOffset = NSSize(width: 0, height: -3)
    NSGraphicsContext.saveGraphicsState(); shadow.set(); round(r, 21, .white.withAlphaComponent(0.94)); NSGraphicsContext.restoreGraphicsState()
    text(value, in: r.insetBy(dx: 17, dy: 7), size: 22, weight: .bold)
}
func featureCrop(_ image: NSImage, focus: CGRect, into rect: NSRect) {
    // Crop only the original photo. Never reconstruct or retouch app controls/results.
    var source = NSRect(x: focus.minX * image.size.width, y: (1 - focus.maxY) * image.size.height, width: focus.width * image.size.width, height: focus.height * image.size.height)
    let targetAspect = rect.width / rect.height
    if source.width / source.height > targetAspect {
        let width = source.height * targetAspect; source.origin.x += (source.width - width) / 2; source.size.width = width
    } else {
        let height = source.width / targetAspect; source.origin.y += (source.height - height) / 2; source.size.height = height
    }
    NSGraphicsContext.saveGraphicsState(); NSBezierPath(roundedRect: rect, xRadius: 26, yRadius: 26).addClip()
    image.draw(in: rect, from: source, operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
}
func device(_ image: NSImage, rect r: NSRect) {
    let shadow = NSShadow(); shadow.shadowBlurRadius = 28; shadow.shadowOffset = NSSize(width: 0, height: -17); shadow.shadowColor = .black.withAlphaComponent(0.19)
    // A quiet physical edge and displaced shadow provide depth without decorative objects.
    NSGraphicsContext.saveGraphicsState(); shadow.set(); round(r.insetBy(dx: -8, dy: -8).offsetBy(dx: 0, dy: -4), 62, NSColor(white: 0.36, alpha: 1)); NSGraphicsContext.restoreGraphicsState()
    round(r.insetBy(dx: -5, dy: -5), 60, NSColor(white: 0.12, alpha: 1))
    NSColor.white.withAlphaComponent(0.3).setStroke()
    let edge = NSBezierPath(roundedRect: r.insetBy(dx: -6, dy: -6), xRadius: 61, yRadius: 61)
    edge.lineWidth = 1.5; edge.stroke()
    NSGraphicsContext.saveGraphicsState(); NSBezierPath(roundedRect: r, xRadius: 55, yRadius: 55).addClip(); image.draw(in: r); NSGraphicsContext.restoreGraphicsState()
}
struct Shot {
    let file: String, headline: String, subtitle: String, fixture: String
    let focus: CGRect
}
let shots = [
    Shot(file: "01-faces", headline: "Blur faces.\nInstantly.", subtitle: "Automatic detection. Your final say.", fixture: "marketing-cafe", focus: CGRect(x: 0, y: 0.10, width: 1, height: 0.18)),
    Shot(file: "02-plates", headline: "Hide private\ndetails.", subtitle: "Cover number plates before you share.", fixture: "two-people-car", focus: CGRect(x: 0.35, y: 0.67, width: 0.30, height: 0.08)),
    Shot(file: "03-location", headline: "Leave location\nbehind.", subtitle: "Remove source metadata from your copy.", fixture: "marketing-coast", focus: CGRect(x: 0, y: 0.20, width: 1, height: 0.50)),
    Shot(file: "04-documents", headline: "Take full\ncontrol.", subtitle: "Adjust detected regions. Make it precise.", fixture: "marketing-card", focus: CGRect(x: 0.17, y: 0.425, width: 0.66, height: 0.12)),
    Shot(file: "05-share", headline: "Share with\nconfidence.", subtitle: "Review your edited copy before sharing.", fixture: "two-faces", focus: CGRect(x: 0, y: 0.23, width: 1, height: 0.55))
]
for shot in shots {
    let photo = NSImage(contentsOf: root.appendingPathComponent("Tests/PhotoVeilUITests/Fixtures/\(shot.fixture).jpg"))!
    guard let ui = NSImage(contentsOf: captures.appendingPathComponent(shot.file + "-after.png")) else { fatalError("Missing actual app capture: \(shot.file)") }
    let r = NSRect(x: 160, y: 24, width: 1000, height: 1000 * ui.size.height / ui.size.width)
    try render(out.appendingPathComponent(shot.file + ".jpg"), jpeg: true) {
        text("VAIL", in: NSRect(x: 82, y: 2780, width: 1156, height: 50), size: 37, weight: .bold)
        text(shot.headline, in: NSRect(x: 80, y: 2490, width: 1160, height: 270), size: 126, weight: .bold)
        text(shot.subtitle, in: NSRect(x: 83, y: 2440, width: 1155, height: 46), size: 33, color: ink.withAlphaComponent(0.70), weight: .regular)
        let strip = NSRect(x: 80, y: 2228, width: 1160, height: 190)
        let shadow = NSShadow(); shadow.shadowColor = .black.withAlphaComponent(0.12); shadow.shadowBlurRadius = 12; shadow.shadowOffset = NSSize(width: 0, height: -5)
        NSGraphicsContext.saveGraphicsState(); shadow.set(); round(strip, 26, .white); NSGraphicsContext.restoreGraphicsState()
        featureCrop(photo, focus: shot.focus, into: strip)
        pill(shot.file == "03-location" ? "LOCATION ATTACHED" : "BEFORE", x: 98, y: 2245, width: shot.file == "03-location" ? 286 : 128)
        device(ui, rect: r)
        // Label stays outside genuine UI, so no app control is altered or hidden.
        text("AFTER", in: NSRect(x: 31, y: 2120, width: 118, height: 37), size: 22, color: ink.withAlphaComponent(0.65), weight: .bold)
    }
}
try render(base.appendingPathComponent("editorial-contact-sheet.png"), w: 2400, h: 1240) {
    text("VAIL / EDITORIAL CALM", in: NSRect(x: 35, y: 1130, width: 2300, height: 75), size: 52, weight: .bold)
    text("Five final-review candidates · real app UI · synthetic demonstration photography", in: NSRect(x: 37, y: 1075, width: 2300, height: 50), size: 29, color: ink.withAlphaComponent(0.7), weight: .regular)
    for (index, shot) in shots.enumerated() {
        let x = 36 + index * 468
        NSImage(contentsOf: out.appendingPathComponent(shot.file + ".jpg"))!.draw(in: NSRect(x: x, y: 70, width: 440, height: 956))
        text("0\(index + 1)", in: NSRect(x: x, y: 25, width: 440, height: 34), size: 25)
    }
}
let previewShots = ["preview-light", "preview-dark"]
try render(base.appendingPathComponent("quiet-lattice-contact-sheet.png"), w: 1400, h: 1690) {
    text("QUIET LATTICE / REFINED", in: NSRect(x: 40, y: 1588, width: 1320, height: 65), size: 43, weight: .bold)
    text("Actual redacted previews · lighter repeated marks · native upgrade controls", in: NSRect(x: 40, y: 1535, width: 1320, height: 45), size: 25, color: ink.withAlphaComponent(0.7), weight: .regular)
    for (index, name) in previewShots.enumerated() {
        let previewPath = index == 0 ? captures.appendingPathComponent(name + ".png") : base.appendingPathComponent("captures/dark/" + name + ".png")
        guard let ui = NSImage(contentsOf: previewPath) else { fatalError("Missing actual preview capture") }
        device(ui, rect: NSRect(x: CGFloat(70 + index * 680), y: 130, width: 580, height: 580 * ui.size.height / ui.size.width))
        text(index == 0 ? "LIGHT UI · LIGHT PHOTOGRAPH" : "DARK UI · DARK PHOTOGRAPH", in: NSRect(x: 70 + index * 680, y: 65, width: 580, height: 40), size: 26)
    }
    text("Review only · captured after the current allowance is exhausted; migration to one export remains pending.", in: NSRect(x: 40, y: 10, width: 1320, height: 36), size: 20, color: ink.withAlphaComponent(0.6), weight: .regular)
}
print("Rendered five opaque1320×2868 JPEG candidates and two final-review contact sheets.")

try render(base.appendingPathComponent("documents-adjustment-evidence.png"), w: 1600, h: 1320) {
    text("AUTOMATIC DOCUMENTS / ACTUAL APP", in: NSRect(x: 45, y: 1220, width: 1510, height: 65), size: 42, weight: .bold)
    text("Detected region → native move → native resize · Undo and cached analysis asserted", in: NSRect(x: 45, y: 1170, width: 1510, height: 45), size: 26, color: ink.withAlphaComponent(0.7), weight: .regular)
    for (index, name) in ["04-documents-detected", "04-documents-moved", "04-documents-after"].enumerated() {
        let ui = NSImage(contentsOf: captures.appendingPathComponent(name + ".png"))!
        device(ui, rect: NSRect(x: CGFloat(50 + index * 520), y: 110, width: 460, height: 460 * ui.size.height / ui.size.width))
        text(["DETECTED", "MOVED", "RESIZED"][index], in: NSRect(x: 50 + index * 520, y: 45, width: 460, height: 45), size: 27)
    }
}
try render(base.appendingPathComponent("dark-appearance-evidence.png"), w: 1600, h: 1320) {
    text("DARK APPEARANCE / ACTUAL APP", in: NSRect(x: 45, y: 1220, width: 1510, height: 65), size: 42, weight: .bold)
    text("Plate redaction · adjusted Documents · Quiet Lattice and native upgrade CTA", in: NSRect(x: 45, y: 1170, width: 1510, height: 45), size: 26, color: ink.withAlphaComponent(0.7), weight: .regular)
    for (index, name) in ["02-plates-after", "04-documents-after", "preview-dark"].enumerated() {
        let ui = NSImage(contentsOf: base.appendingPathComponent("captures/dark/" + name + ".png"))!
        device(ui, rect: NSRect(x: CGFloat(50 + index * 520), y: 110, width: 460, height: 460 * ui.size.height / ui.size.width))
        text(["PLATES", "DOCUMENTS", "PREVIEW MODE"][index], in: NSRect(x: 50 + index * 520, y: 45, width: 460, height: 45), size: 27)
    }
}
