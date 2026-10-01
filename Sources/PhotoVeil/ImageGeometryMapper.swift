import CoreGraphics

/// Maps between normalized top-left image coordinates and an aspect-fit view rectangle.
struct ImageGeometryMapper: Equatable {
    let imageSize: CGSize
    let container: CGRect
    var zoomScale: CGFloat = 1
    var panOffset: CGSize = .zero

    var displayedRect: CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return .zero }
        let scale = min(container.width / imageSize.width, container.height / imageSize.height)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        return CGRect(x: container.midX - size.width / 2, y: container.midY - size.height / 2, width: size.width, height: size.height)
    }

    func viewRect(fromNormalized rect: CGRect) -> CGRect {
        let imageRect = displayedRect
        let x = imageRect.minX + rect.minX * imageRect.width
        let y = imageRect.minY + rect.minY * imageRect.height
        return CGRect(x: container.midX + (x - container.midX) * zoomScale + panOffset.width,
                      y: container.midY + (y - container.midY) * zoomScale + panOffset.height,
                      width: rect.width * imageRect.width * zoomScale,
                      height: rect.height * imageRect.height * zoomScale)
    }

    func normalizedPoint(fromView point: CGPoint) -> CGPoint? {
        let rect = displayedRect
        guard zoomScale > 0, rect.width > 0, rect.height > 0 else { return nil }
        let imagePoint = CGPoint(x: container.midX + (point.x - panOffset.width - container.midX) / zoomScale,
                                 y: container.midY + (point.y - panOffset.height - container.midY) / zoomScale)
        guard rect.contains(imagePoint) else { return nil }
        return CGPoint(x: (imagePoint.x - rect.minX) / rect.width, y: (imagePoint.y - rect.minY) / rect.height)
    }

    func normalizedRect(fromView rect: CGRect) -> CGRect {
        let imageRect = displayedRect
        guard zoomScale > 0, imageRect.width > 0, imageRect.height > 0 else { return .zero }
        let unscaled = CGRect(x: container.midX + (rect.minX - panOffset.width - container.midX) / zoomScale,
                              y: container.midY + (rect.minY - panOffset.height - container.midY) / zoomScale,
                              width: rect.width / zoomScale, height: rect.height / zoomScale)
        let clipped = unscaled.intersection(imageRect)
        guard !clipped.isNull else { return .zero }
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
