// Reproducible code-native Veil artwork. Run: swift Design/render_icon.swift
import AppKit
import CoreGraphics

let space = CGColorSpaceCreateDeviceRGB()
func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(colorSpace: space, components: [r, g, b, a])!
}
func render(size: Int, opaque: Bool, output: String, draw: (CGContext) -> Void) {
    let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size * 4,
                            space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.scaleBy(x: CGFloat(size) / 1024, y: CGFloat(size) / 1024)
    draw(context)
    let image = context.makeImage()!
    let bitmap: NSBitmapImageRep
    if opaque {
        // App Store icons must have no alpha channel, including fully opaque alpha.
        bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
                                  samplesPerPixel: 3, hasAlpha: false, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        let source = context.data!.assumingMemoryBound(to: UInt8.self)
        let target = bitmap.bitmapData!
        for y in 0..<size {
            for x in 0..<size {
                let sourceOffset = (y * size + x) * 4
                let targetOffset = y * bitmap.bytesPerRow + x * 3
                for channel in 0..<3 { target[targetOffset + channel] = source[sourceOffset + channel] }
            }
        }
    } else { bitmap = NSBitmapImageRep(cgImage: image) }
    try! bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
}
func mark(_ c: CGContext, launch: Bool = false) {
    c.saveGState()
    let frame = CGPath(roundedRect: CGRect(x: 160, y: 204, width: 704, height: 616), cornerWidth: 126, cornerHeight: 126, transform: nil)
    c.addPath(frame)
    c.setStrokeColor(launch ? color(0.18, 0.48, 0.82) : color(0.90, 0.96, 1))
    c.setLineWidth(34); c.strokePath()
    c.setFillColor(launch ? color(0.27, 0.66, 0.93) : color(0.90, 0.97, 1))
    c.fillEllipse(in: CGRect(x: 672, y: 602, width: 98, height: 98))
    // A flowing veil crosses a photographic frame; a folded edge gives the mark depth.
    let veil = CGMutablePath()
    veil.move(to: CGPoint(x: 238, y: 688))
    veil.addCurve(to: CGPoint(x: 790, y: 352), control1: CGPoint(x: 389, y: 866), control2: CGPoint(x: 733, y: 589))
    veil.addCurve(to: CGPoint(x: 240, y: 518), control1: CGPoint(x: 875, y: 82), control2: CGPoint(x: 322, y: 275))
    veil.addCurve(to: CGPoint(x: 238, y: 688), control1: CGPoint(x: 197, y: 607), control2: CGPoint(x: 195, y: 644))
    veil.closeSubpath()
    c.saveGState()
    if !launch { c.setShadow(offset: .zero, blur: 42, color: color(0.03, 0.55, 1, 0.65)) }
    c.addPath(veil); c.setFillColor(color(0.12, 0.52, 0.93)); c.fillPath()
    c.restoreGState()
    c.saveGState(); c.addPath(veil); c.clip()
    let gradient = CGGradient(colorsSpace: space, colors: [color(0.33, 1, 0.96), color(0.05, 0.57, 0.94), color(0.28, 0.12, 0.89)] as CFArray, locations: [0, 0.46, 1])!
    c.drawLinearGradient(gradient, start: CGPoint(x: 275, y: 730), end: CGPoint(x: 730, y: 290), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    let fold = CGMutablePath(); fold.move(to: CGPoint(x: 238, y: 688))
    fold.addCurve(to: CGPoint(x: 790, y: 352), control1: CGPoint(x: 432, y: 590), control2: CGPoint(x: 594, y: 335))
    c.addPath(fold); c.setStrokeColor(color(0.72, 0.98, 1, 0.6)); c.setLineWidth(8); c.strokePath()
    c.restoreGState(); c.restoreGState()
}
render(size: 1024, opaque: true, output: "Design/Assets.xcassets/PhotoVeilIcon.appiconset/PhotoVeilIcon.png") { c in
    let background = CGGradient(colorsSpace: space, colors: [color(0.055, 0.105, 0.18), color(0.025, 0.035, 0.075)] as CFArray, locations: [0, 1])!
    c.drawLinearGradient(background, start: CGPoint(x: 0, y: 1024), end: CGPoint(x: 900, y: 0), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    mark(c)
}
let folder = "Design/Assets.xcassets/LaunchMark.imageset"
try! FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
for scale in 1...3 {
    render(size: 104 * scale, opaque: false, output: "\(folder)/mark@\(scale)x.png") { mark($0, launch: true) }
}
