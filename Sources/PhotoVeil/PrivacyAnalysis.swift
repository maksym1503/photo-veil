import UIKit
import CoreImage

/// Only expensive external analysis is substitutable. State, masks and rendering
/// always follow the same editor path, regardless of the analyzer.
protocol PrivacyAnalyzing {
    func background(_ image: UIImage, strength: BlurStrength) async throws -> (image: UIImage, mask: CIImage)
    func faces(_ image: UIImage) async throws -> [CGRect]
    func plates(_ image: UIImage) async throws -> [CGRect]
    func documents(_ image: UIImage) async throws -> DocumentDetection.Result
}

struct VisionPrivacyAnalyzer: PrivacyAnalyzing {
    func background(_ image: UIImage, strength: BlurStrength) async throws -> (image: UIImage, mask: CIImage) {
        try await BlurRenderer.renderBackground(image, strength: strength)
    }
    func faces(_ image: UIImage) async throws -> [CGRect] { try await BlurRenderer.detectFaces(in: image) }
    func plates(_ image: UIImage) async throws -> [CGRect] { try await BlurRenderer.detectPlateSuggestions(in: image) }
    func documents(_ image: UIImage) async throws -> DocumentDetection.Result {
        guard let cg = (BlurRenderer.previewImage(image, maxDimension: 3200) ?? image).cgImage else { throw BlurError.unavailable }
        return try DocumentDetection.analyze(cg)
    }
}

enum PrivacyAnalyzerFactory {
    static func make() -> any PrivacyAnalyzing {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-veil-ui-testing"), args.contains("-veil-analysis-fixture") {
            return FixturePrivacyAnalyzer(empty: args.contains("-veil-empty-analysis"))
        }
        #endif
        return VisionPrivacyAnalyzer()
    }
}

#if DEBUG
/// Explicit opt-in test double; never compiled into Release and never selected by
/// ordinary Debug launches. No alternative selection/Undo/render implementation.
private struct FixturePrivacyAnalyzer: PrivacyAnalyzing {
    let empty: Bool
    func faces(_ image: UIImage) async throws -> [CGRect] {
        empty ? [] : [CGRect(x: 0.16, y: 0.12, width: 0.18, height: 0.2), CGRect(x: 0.48, y: 0.16, width: 0.16, height: 0.18)]
    }
    func plates(_ image: UIImage) async throws -> [CGRect] {
        empty ? [] : [CGRect(x: 0.6, y: 0.66, width: 0.24, height: 0.09)]
    }
    func documents(_ image: UIImage) async throws -> DocumentDetection.Result {
        .init(boundaries: empty ? [] : [CGRect(x: 0.12, y: 0.45, width: 0.4, height: 0.35)],
              details: empty ? [] : [CGRect(x: 0.18, y: 0.5, width: 0.25, height: 0.04), CGRect(x: 0.18, y: 0.62, width: 0.2, height: 0.04)], elapsed: 0)
    }
    func background(_ image: UIImage, strength: BlurStrength) async throws -> (image: UIImage, mask: CIImage) {
        guard !empty, let cg = image.cgImage else { throw BlurError.noSubject }
        let extent = CGRect(x: 0, y: 0, width: cg.width, height: cg.height)
        let mask = CIImage(color: .white).cropped(to: extent.insetBy(dx: extent.width * 0.2, dy: extent.height * 0.2))
            .composited(over: CIImage(color: .black).cropped(to: extent))
        guard let rendered = BlurRenderer.render(image, regions: [], strength: strength, foregroundMask: mask) else { throw BlurError.unavailable }
        return (rendered, mask)
    }
}
#endif
