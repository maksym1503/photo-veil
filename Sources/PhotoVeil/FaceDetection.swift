import CoreGraphics
import Foundation
import Vision

/// Geometry uses original-image top-left normalized coordinates, never viewport coordinates.
enum FaceDetection {
    struct Report {
        let baselineCount: Int
        let rawCount: Int
        let regions: [CGRect]
        let requestCount: Int
        let elapsed: TimeInterval
    }

    static func tiles(for size: CGSize) -> [CGRect] {
        guard max(size.width, size.height) >= 2000 else { return [] }
        let landscape = size.width >= size.height
        // A modern 12 MP image gets ~1000-pixel crops, so distant faces occupy more detector pixels.
        // Explicit work ceiling: 20 serial crops + one whole-image pass, never an unbounded grid.
        let highResolution = max(size.width, size.height) >= 3600
        let longCount = highResolution ? 5 : 2
        let shortCount = highResolution ? 4 : 2
        let longSpan: CGFloat = highResolution ? 0.25 : 0.6
        let shortSpan: CGFloat = highResolution ? 0.34 : 0.6
        var result: [CGRect] = []
        for long in 0..<longCount {
            for short in 0..<shortCount {
                let x = CGFloat(long) * (1 - longSpan) / CGFloat(longCount - 1)
                let y = CGFloat(short) * (1 - shortSpan) / CGFloat(shortCount - 1)
                result.append(landscape ? CGRect(x: x, y: y, width: longSpan, height: shortSpan)
                              : CGRect(x: y, y: x, width: shortSpan, height: longSpan))
            }
        }
        return result
    }

    static func map(_ local: CGRect, through tile: CGRect) -> CGRect {
        CGRect(x: tile.minX + local.minX * tile.width, y: tile.minY + local.minY * tile.height,
               width: local.width * tile.width, height: local.height * tile.height)
    }

    static func merge(_ candidates: [CGRect]) -> [CGRect] {
        var kept: [CGRect] = []
        // Prefer complete boxes over crop-edge partial detections. Merge before privacy expansion.
        for box in candidates.sorted(by: { $0.width * $0.height > $1.width * $1.height }) {
            guard !box.isEmpty, !box.isNull else { continue }
            let duplicate = kept.contains { existing in
                let overlap = existing.intersection(box)
                guard !overlap.isNull else { return false }
                let area = overlap.width * overlap.height
                let smaller = min(existing.width * existing.height, box.width * box.height)
                let union = existing.width * existing.height + box.width * box.height - area
                return area / max(union, 0.000001) > 0.35 || area / max(smaller, 0.000001) > 0.75
            }
            if !duplicate { kept.append(box) }
        }
        return kept.sorted { abs($0.minY - $1.minY) < 0.001 ? $0.minX < $1.minX : $0.minY < $1.minY }
    }

    static func analyze(_ image: CGImage, tiled: Bool = true) throws -> Report {
        let started = Date()
        func detect(_ cg: CGImage) throws -> [CGRect] {
            let request = VNDetectFaceRectanglesRequest()
            #if targetEnvironment(simulator)
            request.usesCPUOnly = true
            #endif
            try VNImageRequestHandler(cgImage: cg, orientation: .up).perform([request])
            return (request.results ?? []).map { ImageGeometryMapper.topLeftRect(fromVision: $0.boundingBox) }
        }
        let baseline = try detect(image)
        var candidates = baseline, count = 1
        let size = CGSize(width: image.width, height: image.height)
        for tile in tiled ? tiles(for: size) : [] {
            try Task.checkCancellation()
            let pixels = CGRect(x: tile.minX * size.width, y: tile.minY * size.height,
                                width: tile.width * size.width, height: tile.height * size.height).integral
                .intersection(CGRect(origin: .zero, size: size))
            guard let crop = image.cropping(to: pixels) else { continue }
            let actualTile = CGRect(x: pixels.minX / size.width, y: pixels.minY / size.height,
                                    width: pixels.width / size.width, height: pixels.height / size.height)
            // Process one crop at a time, at most 21 requests total; release each crop after use.
            candidates += try autoreleasepool { try detect(crop).map { map($0, through: actualTile) } }
            count += 1
        }
        return Report(baselineCount: baseline.count, rawCount: candidates.count, regions: merge(candidates),
                      requestCount: count, elapsed: Date().timeIntervalSince(started))
    }
}
