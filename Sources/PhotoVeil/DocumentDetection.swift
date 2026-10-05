import Foundation
import CoreGraphics
import Vision

/// Only geometry escapes this pipeline. Recognized strings are transient, never persisted or logged.
enum DocumentDetection {
    struct Result {
        let boundaries: [CGRect]
        let details: [CGRect]
        let elapsed: TimeInterval
    }

    static func isCardNumberLike(_ text: String) -> Bool {
        let digits = text.filter(\.isNumber)
        return (13...19).contains(digits.count) && text.allSatisfy { $0.isNumber || $0.isWhitespace || $0 == "-" }
    }

    static func analyze(_ image: CGImage) throws -> Result {
        let start = Date()
        let handler = VNImageRequestHandler(cgImage: image, orientation: .up)
        let rectangles = VNDetectRectanglesRequest()
        rectangles.maximumObservations = 8
        rectangles.minimumConfidence = 0.65
        rectangles.minimumSize = 0.15
        rectangles.minimumAspectRatio = 0.35
        rectangles.maximumAspectRatio = 1
        try handler.perform([rectangles])
        var boxes = (rectangles.results ?? []).map { ImageGeometryMapper.topLeftRect(fromVision: $0.boundingBox) }
        let document = VNDetectDocumentSegmentationRequest()
        if (try? handler.perform([document])) != nil {
            boxes += (document.results ?? []).filter { $0.confidence >= 0.6 }
                .map { ImageGeometryMapper.topLeftRect(fromVision: $0.boundingBox) }
        }
        boxes = FaceDetection.merge(boxes).filter { $0.width * $0.height > 0.04 }
        guard !boxes.isEmpty else { return Result(boundaries: [], details: [], elapsed: Date().timeIntervalSince(start)) }
        try Task.checkCancellation()
        let text = VNRecognizeTextRequest()
        text.recognitionLevel = .accurate
        text.usesLanguageCorrection = false
        try handler.perform([text])
        var details: [CGRect] = []
        for observation in text.results ?? [] {
            let box = ImageGeometryMapper.topLeftRect(fromVision: observation.boundingBox)
            guard boxes.contains(where: { $0.contains(CGPoint(x: box.midX, y: box.midY)) }) else { continue }
            // Broad text coverage avoids country-specific name/ID layouts. Card digits get wider padding.
            let cardLike = observation.topCandidates(1).first.map { isCardNumberLike($0.string) } ?? false
            details.append(box.insetBy(dx: -box.width * (cardLike ? 0.12 : 0.06), dy: -box.height * 0.3)
                .intersection(CGRect(x: 0, y: 0, width: 1, height: 1)))
        }
        let faces = VNDetectFaceRectanglesRequest()
        if (try? handler.perform([faces])) != nil {
            details += (faces.results ?? []).map { ImageGeometryMapper.topLeftRect(fromVision: $0.boundingBox) }
                .filter { box in boxes.contains { $0.contains(CGPoint(x: box.midX, y: box.midY)) } }
                .map { $0.insetBy(dx: -$0.width * 0.23, dy: -$0.height * 0.28).intersection(CGRect(x: 0, y: 0, width: 1, height: 1)) }
        }
        return Result(boundaries: boxes, details: FaceDetection.merge(details), elapsed: Date().timeIntervalSince(start))
    }
}
