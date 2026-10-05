import XCTest
import CoreImage
import ImageIO
import AppKit
@testable import ImageGeometry

/// Opt-in real-Vision diagnostic, not a flaky recall assertion in deterministic CI.
final class DetectionBenchmarkTests: XCTestCase {
    func testChallengingFixturesAndPerformance() throws {
        guard ProcessInfo.processInfo.environment["VEIL_RUN_DETECTION_BENCHMARK"] == "1" else {
            throw XCTSkip("Opt-in real Vision/profile run; see Documentation/QA/V4")
        }
        let fixtureRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("PhotoVeilUITests/Fixtures")
        let source = try load(fixtureRoot.appendingPathComponent("two-faces.jpg"))
        let faces = try FaceDetection.analyze(source, tiled: false).regions
        let face = try XCTUnwrap(faces.first)
        let cropBox = face.insetBy(dx: -face.width * 0.65, dy: -face.height * 0.65)
            .intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
        let crop = try XCTUnwrap(source.cropping(to: CGRect(x: cropBox.minX * CGFloat(source.width), y: cropBox.minY * CGFloat(source.height),
                                                          width: cropBox.width * CGFloat(source.width), height: cropBox.height * CGFloat(source.height)).integral))
        let output = URL(fileURLWithPath: "/tmp/veil-v4-diagnostics", isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        var measurements: [[String: Any]] = []
        let fixtures: [(String, Int, Int, [(CGFloat, CGFloat, CGFloat)])] = [
            ("faces-large-medium", 3200, 2400, [(220,300,650),(1200,450,280),(2400,800,250)]),
            ("faces-small-landscape", 4032, 3024, [(250,400,650),(1300,1400,110),(2550,1000,80),(3500,450,60)]),
            ("faces-small-portrait", 3024, 4032, [(350,400,500),(1100,2300,110),(2400,3100,85)]),
            ("faces-edges-partial", 4032, 3024, [(5,50,170),(3770,2200,240),(-70,1300,170),(1700,1000,200)])
        ]
        for (name,width,height,placements) in fixtures {
            try autoreleasepool {
                let image = try composite(crop, width: width, height: height, placements: placements)
                try write(image, to: output.appendingPathComponent(name + ".jpg"))
                let ci = CIImage(cgImage: image), scale = 1800 / CGFloat(max(width,height))
                let preview = try XCTUnwrap(CIContext().createCGImage(ci.applyingFilter("CILanczosScaleTransform", parameters: [kCIInputScaleKey: scale]), from: CGRect(x: 0,y: 0,width: CGFloat(width)*scale,height: CGFloat(height)*scale)))
                let baseline = try FaceDetection.analyze(preview, tiled: false), improved = try FaceDetection.analyze(image)
                measurements.append(["fixture": name, "pixels": "\(width)x\(height)", "placed_faces": placements.count,
                    "v3_preview_faces": baseline.regions.count, "v4_whole_faces": improved.baselineCount,
                    "v4_merged_faces": improved.regions.count, "raw_candidates": improved.rawCount,
                    "suppressed_candidates": improved.rawCount - improved.regions.count,
                    "v3_seconds": baseline.elapsed, "v4_seconds": improved.elapsed, "requests": improved.requestCount,
                    "boxes": improved.regions.map { [$0.minX,$0.minY,$0.width,$0.height] }])
            }
        }
        let card = try syntheticCard()
        try write(card, to: output.appendingPathComponent("sample-card.jpg"))
        let documents = try DocumentDetection.analyze(card)
        measurements.append(["fixture": "sample-card", "document_boundaries": documents.boundaries.count,
                             "detail_regions": documents.details.count, "seconds": documents.elapsed])
        let region = BlurRegion(rect: CGRect(x: 0.2,y: 0.2,width: 0.6,height: 0.6), shape: .oval)
        for (width,height) in [(4032,3024),(8064,6048)] {
            for effect in PrivacyEffect.allCases {
                try autoreleasepool {
                    let image = try composite(crop, width: width, height: height, placements: [(500,500,1000)])
                    let started = Date()
                    let rendered = try XCTUnwrap(PrivacyImageRenderer.render(source: image, regions: [region], strength: .strong, effect: effect))
                    try write(rendered, to: output.appendingPathComponent("profile-\(width)-\(effect.rawValue).jpg"))
                    measurements.append(["operation":"full-resolution export including JPEG encoding", "effect": effect.rawValue, "pixels":"\(width)x\(height)",
                                         "seconds":Date().timeIntervalSince(started), "output_width":rendered.width])
                }
            }
        }
        let data = try JSONSerialization.data(withJSONObject: measurements, options: [.prettyPrinted,.sortedKeys])
        try data.write(to: output.appendingPathComponent("measurements.json"))
        print("Veil diagnostic measurements: /tmp/veil-v4-diagnostics/measurements.json")
    }
    private func load(_ url: URL) throws -> CGImage {
        let source = try XCTUnwrap(CGImageSourceCreateWithURL(url as CFURL,nil)); return try XCTUnwrap(CGImageSourceCreateImageAtIndex(source,0,nil))
    }
    private func composite(_ crop: CGImage, width: Int, height: Int, placements: [(CGFloat,CGFloat,CGFloat)]) throws -> CGImage {
        let context = try XCTUnwrap(CGContext(data:nil,width:width,height:height,bitsPerComponent:8,bytesPerRow:width*4,
            space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue))
        context.setFillColor(CGColor(red:0.45,green:0.56,blue:0.55,alpha:1)); context.fill(CGRect(x:0,y:0,width:width,height:height))
        for (x,y,w) in placements { context.draw(crop,in:CGRect(x:x,y:y,width:w,height:w*CGFloat(crop.height)/CGFloat(crop.width))) }
        return try XCTUnwrap(context.makeImage())
    }
    private func syntheticCard() throws -> CGImage {
        let context = try XCTUnwrap(CGContext(data:nil,width:2400,height:1600,bitsPerComponent:8,bytesPerRow:9600,
            space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue))
        context.setFillColor(CGColor(gray:0.18,alpha:1));context.fill(CGRect(x:0,y:0,width:2400,height:1600))
        context.setFillColor(CGColor(gray:0.94,alpha:1));context.fill(CGRect(x:300,y:300,width:1800,height:1000))
        NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=NSGraphicsContext(cgContext:context,flipped:false)
        for (text,y,size) in [("VEIL SAMPLE CARD",1100,65.0),("4111 1111 1111 1111",800,95.0),("12/28",600,65.0),("SAMPLE HOLDER",420,65.0)] {
            (text as NSString).draw(at:NSPoint(x:430,y:y),withAttributes:[.font:NSFont.monospacedSystemFont(ofSize:size,weight:.medium),.foregroundColor:NSColor.black])
        }
        NSGraphicsContext.restoreGraphicsState();return try XCTUnwrap(context.makeImage())
    }
    private func write(_ image: CGImage, to url: URL) throws {
        let writer = try XCTUnwrap(CGImageDestinationCreateWithURL(url as CFURL,"public.jpeg" as CFString,1,nil))
        CGImageDestinationAddImage(writer,image,[kCGImageDestinationLossyCompressionQuality:0.92] as CFDictionary)
        XCTAssertTrue(CGImageDestinationFinalize(writer))
    }
}
