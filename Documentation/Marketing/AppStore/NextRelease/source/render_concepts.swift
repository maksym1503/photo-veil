import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let base = root.appendingPathComponent("Documentation/Marketing/AppStore/NextRelease")
let originalFaces = NSImage(contentsOf: base.appendingPathComponent("source/synthetic-street.jpg"))!
let originalDocument = NSImage(contentsOf: base.appendingPathComponent("source/synthetic-document.jpg"))!
let cafe = NSImage(contentsOf: base.appendingPathComponent("source/synthetic-cafe.png"))!
let ink = NSColor(calibratedRed: 0.06, green: 0.10, blue: 0.14, alpha: 1)
let blue = NSColor(calibratedRed: 0.05, green: 0.40, blue: 0.94, alpha: 1)
let cyan = NSColor(calibratedRed: 0.24, green: 0.88, blue: 0.93, alpha: 1)
func text(_ value: String, _ rect: NSRect, _ size: CGFloat, _ color: NSColor, weight: NSFont.Weight = .semibold) {
    let style = NSMutableParagraphStyle(); style.lineSpacing = -1
    (value as NSString).draw(in: rect, withAttributes: [.font: NSFont.systemFont(ofSize: size, weight: weight), .foregroundColor: color, .paragraphStyle: style])
}
func rounded(_ rect: NSRect, radius: CGFloat, fill: NSColor) {
    fill.setFill(); NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}
func photo(_ image: NSImage, _ rect: NSRect, radius: CGFloat = 36) {
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).addClip()
    let scale = max(rect.width / image.size.width, rect.height / image.size.height)
    let target = NSRect(x: rect.midX - image.size.width * scale / 2, y: rect.midY - image.size.height * scale / 2, width: image.size.width * scale, height: image.size.height * scale)
    image.draw(in: target); NSGraphicsContext.restoreGraphicsState()
}
func phone(_ image: NSImage, x: CGFloat, y: CGFloat, width: CGFloat, angle: CGFloat = 0) {
    let h = width * image.size.height / image.size.width
    NSGraphicsContext.saveGraphicsState()
    let t = NSAffineTransform(); t.translateX(by: x + width / 2, yBy: y + h / 2); t.concat()
    let rot = NSAffineTransform(); rot.rotate(byDegrees: angle); rot.concat()
    let r = NSRect(x: -width / 2, y: -h / 2, width: width, height: h)
    let shadow = NSShadow(); shadow.shadowBlurRadius = 60; shadow.shadowOffset = NSSize(width: 0, height: -30); shadow.shadowColor = .black.withAlphaComponent(0.22)
    NSGraphicsContext.saveGraphicsState(); shadow.set(); rounded(r.insetBy(dx: -10, dy: -10), radius: 65, fill: NSColor(white: 0.12, alpha: 1)); NSGraphicsContext.restoreGraphicsState()
    NSGraphicsContext.saveGraphicsState(); NSBezierPath(roundedRect: r, xRadius: 55, yRadius: 55).addClip(); image.draw(in: r); NSGraphicsContext.restoreGraphicsState()
    NSGraphicsContext.restoreGraphicsState()
}
func render(_ name: String, width: Int = 1320, height: Int = 2868, draw: () -> Void) throws {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)!
    draw(); NSGraphicsContext.restoreGraphicsState()
    try bitmap.representation(using: .png, properties: [:])!.write(to: base.appendingPathComponent(name + ".png"))
}
let facePath = base.appendingPathComponent("captures/vail11-faces.png")
guard let face = NSImage(contentsOf: facePath) else { fatalError("Capture actual Vision Faces UI before rendering concepts") }
let document = NSImage(contentsOf: base.appendingPathComponent("captures/details-reference.png"))!
for direction in 0..<3 {
    let names = ["a-editorial", "b-studio", "c-photo-story"]
    let dir = names[direction]
    try FileManager.default.createDirectory(at: base.appendingPathComponent(dir), withIntermediateDirectories: true)
    for shot in 0..<2 {
        let ui = shot == 0 ? face : document
        let title = shot == 0 ? "Blur faces.\nKeep the moment." : "Private details.\nOut of the picture."
        try render("\(dir)/0\(shot + 1)") {
            if direction == 0 {
                NSColor(calibratedRed: 0.96, green: 0.96, blue: 0.94, alpha: 1).setFill(); NSRect(x: 0, y: 0, width: 1320, height: 2868).fill()
                text("VAIL", NSRect(x: 108, y: 2710, width: 1000, height: 65), 48, ink, weight: .bold)
                text(title, NSRect(x: 104, y: 2370, width: 1150, height: 280), 126, ink, weight: .bold)
                phone(ui, x: 165, y: 100, width: 990)
            } else if direction == 1 {
                NSGradient(colors: [NSColor(calibratedRed: 0.015, green: 0.02, blue: 0.06, alpha: 1), NSColor(calibratedRed: 0.06, green: 0.13, blue: 0.21, alpha: 1)])!.draw(in: NSRect(x: 0, y: 0, width: 1320, height: 2868), angle: 35)
                let orb = NSRect(x: 650, y: 1550, width: 1050, height: 1050)
                NSGradient(colors: [cyan.withAlphaComponent(0.3), NSColor.clear])!.draw(in: NSBezierPath(ovalIn: orb), relativeCenterPosition: NSPoint(x: -0.4, y: 0.3))
                text("VAIL  /  YOUR PRIVACY STUDIO", NSRect(x: 104, y: 2720, width: 1150, height: 60), 33, cyan)
                text(shot == 0 ? "Faces hidden.\nLife in focus." : "Share the story.\nKeep the details.", NSRect(x: 104, y: 2370, width: 1150, height: 280), 126, .white, weight: .bold)
                phone(ui, x: 183, y: 95, width: 965, angle: shot == 0 ? -3 : 3)
            } else {
                NSColor(calibratedRed: 0.90, green: 0.94, blue: 0.97, alpha: 1).setFill(); NSRect(x: 0, y: 0, width: 1320, height: 2868).fill()
                photo(shot == 0 ? originalFaces : originalDocument, NSRect(x: 0, y: 850, width: 1320, height: 1600), radius: 0)
                text("VAIL", NSRect(x: 104, y: 2710, width: 1100, height: 65), 48, ink, weight: .bold)
                text(shot == 0 ? "Good moments.\nFewer identifiers." : "Your photo.\nYour boundaries.", NSRect(x: 104, y: 2460, width: 1150, height: 240), 110, ink, weight: .bold)
                text("BEFORE", NSRect(x: 104, y: 2240, width: 400, height: 50), 30, .white)
                phone(ui, x: 280, y: 110, width: 760)
                text("AFTER", NSRect(x: 1040, y: 1690, width: 240, height: 50), 30, ink)
                text("\(shot + 1) / 5", NSRect(x: 90, y: 100, width: 180, height: 50), 29, ink)
            }
        }
    }
    try render("\(dir)/contact-sheet", width: 880, height: 1040) {
        NSColor(white: 0.91, alpha: 1).setFill(); NSRect(x: 0, y: 0, width: 880, height: 1040).fill()
        text(["A — Editorial calm", "B — Midnight studio", "C — Photo story"][direction], NSRect(x: 30, y: 970, width: 830, height: 50), 30, ink)
        for i in 0..<2 { NSImage(contentsOf: base.appendingPathComponent("\(dir)/0\(i + 1).png"))!.draw(in: NSRect(x: 30 + i * 425, y: 30, width: 395, height: 858)) }
    }
}
try render("all-directions", width: 1800, height: 1180) {
    NSColor(white: 0.91, alpha: 1).setFill(); NSRect(x: 0, y: 0, width: 1800, height: 1180).fill()
    for (index, dir) in ["a-editorial", "b-studio", "c-photo-story"].enumerated() {
        NSImage(contentsOf: base.appendingPathComponent("\(dir)/contact-sheet.png"))!.draw(in: NSRect(x: 20 + index * 595, y: 160, width: 570, height: 674))
    }
    text("VAIL / NEXT RELEASE", NSRect(x: 30, y: 1040, width: 1740, height: 70), 50, ink, weight: .bold)
    text("Three directions. Two representative screenshots each.", NSRect(x: 30, y: 960, width: 1740, height: 60), 35, ink)
    text("DESIGN REVIEW ONLY · FINAL SET WAITS FOR MAKSYM'S SELECTION", NSRect(x: 30, y: 60, width: 1740, height: 50), 27, ink)
}
// Explicit presentation proposals, not captures of already-shipped behavior.
for concept in 0..<2 {
    try render("preview-concept-\(concept == 0 ? "a-lattice" : "b-ribbon")", width: 900, height: 1300) {
        NSColor(white: 0.96, alpha: 1).setFill(); NSRect(x: 0, y: 0, width: 900, height: 1300).fill()
        text(concept == 0 ? "A / Quiet lattice — recommended" : "B / Frosted ribbons", NSRect(x: 50, y: 1190, width: 800, height: 60), 35, ink)
        let area = NSRect(x: 50, y: 370, width: 800, height: 780)
        photo(cafe, area)
        NSGraphicsContext.saveGraphicsState(); NSBezierPath(roundedRect: area, xRadius: 36, yRadius: 36).addClip()
        for row in 0..<8 {
            for column in 0..<4 {
                NSGraphicsContext.saveGraphicsState()
                let t = NSAffineTransform(); t.translateX(by: CGFloat(column) * 245 + (row % 2 == 0 ? 0 : 100), yBy: 400 + CGFloat(row) * 115); t.concat()
                let rot = NSAffineTransform(); rot.rotate(byDegrees: -22); rot.concat()
                if concept == 1 { rounded(NSRect(x: -10, y: -5, width: 230, height: 42), radius: 6, fill: .white.withAlphaComponent(0.32)) }
                let shadow = NSShadow(); shadow.shadowColor = .black.withAlphaComponent(0.5); shadow.shadowBlurRadius = 2; shadow.set()
                text("VAIL · PREVIEW", NSRect(x: 0, y: 0, width: 240, height: 40), 24, .white.withAlphaComponent(concept == 0 ? 0.60 : 0.75))
                NSGraphicsContext.restoreGraphicsState()
            }
        }
        NSGraphicsContext.restoreGraphicsState()
        text("Preview Mode", NSRect(x: 55, y: 275, width: 790, height: 60), 38, ink, weight: .bold)
        text("Your free export has been used. Upgrade to Pro\nto save or share clean photos.", NSRect(x: 55, y: 178, width: 790, height: 90), 27, ink, weight: .regular)
        rounded(NSRect(x: 50, y: 65, width: 800, height: 85), radius: 24, fill: blue)
        text("Unlock Clean Exports", NSRect(x: 260, y: 87, width: 590, height: 45), 30, .white)
    }
}
try render("preview-concepts", width: 1200, height: 960) {
    NSColor(white: 0.91, alpha: 1).setFill(); NSRect(x: 0, y: 0, width: 1200, height: 960).fill()
    for (index, name) in ["a-lattice", "b-ribbon"].enumerated() {
        NSImage(contentsOf: base.appendingPathComponent("preview-concept-\(name).png"))!.draw(in: NSRect(x: 20 + index * 595, y: 40, width: 565, height: 816))
    }
    text("Premium preview / presentation concepts", NSRect(x: 30, y: 885, width: 1140, height: 50), 32, ink)
}
print("Rendered six 1320×2868 design candidates, direction contact sheets and two preview concepts.")
