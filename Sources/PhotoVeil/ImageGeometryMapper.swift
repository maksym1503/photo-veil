import CoreGraphics

/// Maps between normalized top-left image coordinates and an aspect-fit view rectangle.
struct ImageGeometryMapper: Equatable {
    let imageSize: CGSize
    let container: CGRect

    var displayedRect: CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return .zero }
        let scale = min(container.width / imageSize.width, container.height / imageSize.height)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        return CGRect(x: container.midX - size.width / 2, y: container.midY - size.height / 2, width: size.width, height: size.height)
    }

    func viewRect(fromNormalized rect: CGRect) -> CGRect {
        let imageRect = displayedRect
        return CGRect(x: imageRect.minX + rect.minX * imageRect.width,
                      y: imageRect.minY + rect.minY * imageRect.height,
                      width: rect.width * imageRect.width,
                      height: rect.height * imageRect.height)
    }

    func normalizedPoint(fromView point: CGPoint) -> CGPoint? {
        let rect = displayedRect
        guard rect.contains(point), rect.width > 0, rect.height > 0 else { return nil }
        return CGPoint(x: (point.x - rect.minX) / rect.width, y: (point.y - rect.minY) / rect.height)
    }

    func normalizedRect(fromView rect: CGRect) -> CGRect {
        let imageRect = displayedRect
        let clipped = rect.intersection(imageRect)
        guard !clipped.isNull, imageRect.width > 0, imageRect.height > 0 else { return .zero }
        return CGRect(x: (clipped.minX - imageRect.minX) / imageRect.width,
                      y: (clipped.minY - imageRect.minY) / imageRect.height,
                      width: clipped.width / imageRect.width,
                      height: clipped.height / imageRect.height)
    }

    /// Vision uses a bottom-left origin; editor and renderer use a top-left origin.
    static func topLeftRect(fromVision rect: CGRect) -> CGRect {
        CGRect(x: rect.minX, y: 1 - rect.maxY, width: rect.width, height: rect.height)
    }
}
