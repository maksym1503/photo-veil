import SwiftUI
import UIKit

extension Notification.Name {
    static let photoVeilFitPhoto = Notification.Name("PhotoVeilFitPhoto")
}

struct ZoomablePhotoCanvas: UIViewRepresentable {
    let original: UIImage
    let preview: UIImage
    let mode: EditorMode?
    let faces: [CGRect]
    let selectedFaces: Set<Int>
    let plates: [CGRect]
    let selectedPlates: Set<Int>
    let regions: [BlurRegion]
    let drawsRegions: Bool
    let onFaces: (Int) -> Void
    let onPlate: (Int) -> Void
    let onRegions: ([BlurRegion]) -> Void
    let onZoomChanged: (Bool) -> Void

    func makeUIView(context: Context) -> ZoomingPhotoView {
        let view = ZoomingPhotoView()
        view.configure(original: original, preview: preview, mode: mode, faces: faces, selectedFaces: selectedFaces,
                       plates: plates, selectedPlates: selectedPlates, regions: regions, drawsRegions: drawsRegions,
                       onFaces: onFaces, onPlate: onPlate, onRegions: onRegions, onZoomChanged: onZoomChanged)
        return view
    }

    func updateUIView(_ view: ZoomingPhotoView, context: Context) {
        view.configure(original: original, preview: preview, mode: mode, faces: faces, selectedFaces: selectedFaces,
                       plates: plates, selectedPlates: selectedPlates, regions: regions, drawsRegions: drawsRegions,
                       onFaces: onFaces, onPlate: onPlate, onRegions: onRegions, onZoomChanged: onZoomChanged)
    }
}

final class ZoomingPhotoView: UIScrollView, UIScrollViewDelegate {
    private let photoContent = UIView()
    private let imageView = UIImageView()
    private let overlay = PhotoRegionOverlay()
    private var sourceIdentity: ObjectIdentifier?
    private var sourceSize: CGSize = .zero
    private var needsSourceLayout = true
    private var isLayingOutPhoto = false
    private var lastViewportSize: CGSize = .zero
    private var lastZoomState: Bool?
    private var onZoomChanged: ((Bool) -> Void)?
    private var fitObserver: NSObjectProtocol?

    override init(frame: CGRect) {
        super.init(frame: frame)
        delegate = self
        backgroundColor = .clear
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        contentInsetAdjustmentBehavior = .never
        delaysContentTouches = false
        bouncesZoom = true
        photoContent.clipsToBounds = true
        imageView.contentMode = .scaleToFill
        imageView.isAccessibilityElement = false
        overlay.backgroundColor = .clear
        overlay.isMultipleTouchEnabled = true
        addSubview(photoContent)
        photoContent.addSubview(imageView)
        photoContent.addSubview(overlay)
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
        fitObserver = NotificationCenter.default.addObserver(forName: .photoVeilFitPhoto, object: nil, queue: .main) { [weak self] _ in
            self?.fitToScreen()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit { if let fitObserver { NotificationCenter.default.removeObserver(fitObserver) } }

    func configure(original: UIImage, preview: UIImage, mode: EditorMode?, faces: [CGRect], selectedFaces: Set<Int>,
                   plates: [CGRect], selectedPlates: Set<Int>, regions: [BlurRegion], drawsRegions: Bool,
                   onFaces: @escaping (Int) -> Void, onPlate: @escaping (Int) -> Void,
                   onRegions: @escaping ([BlurRegion]) -> Void, onZoomChanged: @escaping (Bool) -> Void) {
        let identity = ObjectIdentifier(original)
        let size = original.cgImage.map { CGSize(width: $0.width, height: $0.height) } ?? original.size
        let sourceChanged = identity != sourceIdentity || size != sourceSize
        sourceIdentity = identity
        sourceSize = size
        imageView.image = preview
        self.onZoomChanged = onZoomChanged
        overlay.configure(imageSize: photoContent.bounds.size, mode: mode, faces: mode == .faces ? faces : [], selectedFaces: selectedFaces,
                          plates: mode == .plate ? plates : [], selectedPlates: selectedPlates, regions: mode == .manual ? regions : [],
                          drawsRegions: drawsRegions, onFaces: onFaces, onPlate: onPlate, onRegions: onRegions)
        let canvasInteractive = mode == .manual
        // One finger edits; two fingers can always navigate while drawing.
        panGestureRecognizer.isEnabled = true
        panGestureRecognizer.minimumNumberOfTouches = canvasInteractive && drawsRegions ? 2 : 1
        panGestureRecognizer.maximumNumberOfTouches = 2
        setNeedsLayout()
        if sourceChanged { needsSourceLayout = true }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard sourceSize.width > 0, sourceSize.height > 0, bounds.width > 0, bounds.height > 0 else { return }
        guard !isLayingOutPhoto else { return }
        isLayingOutPhoto = true
        defer { isLayingOutPhoto = false }
        if needsSourceLayout || bounds.size != lastViewportSize {
            let userZoom = needsSourceLayout ? 1 : zoomScale
            // Preserve the image point under the viewport center during rotation/layout.
            let center = convert(CGPoint(x: bounds.midX, y: bounds.midY), to: photoContent)
            let oldSize = photoContent.bounds.size
            let normalizedCenter = oldSize.width > 0 && oldSize.height > 0
                ? CGPoint(x: center.x / oldSize.width, y: center.y / oldSize.height) : CGPoint(x: 0.5, y: 0.5)
            let fit = min(bounds.width / sourceSize.width, bounds.height / sourceSize.height)
            let fittedSize = CGSize(width: sourceSize.width * fit, height: sourceSize.height * fit)
            // UIScrollView owns the transform. Never set frame while it is transformed.
            setZoomScale(1, animated: false)
            photoContent.bounds = CGRect(origin: .zero, size: fittedSize)
            photoContent.center = CGPoint(x: fittedSize.width / 2, y: fittedSize.height / 2)
            imageView.frame = photoContent.bounds
            overlay.frame = photoContent.bounds
            overlay.updateCanvasSize(fittedSize)
            contentSize = fittedSize
            minimumZoomScale = 1
            maximumZoomScale = 8
            setZoomScale(userZoom, animated: false)
            centerContent()
            if needsSourceLayout || userZoom == 1 {
                contentOffset = CGPoint(x: -contentInset.left, y: -contentInset.top)
            } else {
                contentOffset = CGPoint(x: normalizedCenter.x * fittedSize.width * userZoom - bounds.width / 2,
                                        y: normalizedCenter.y * fittedSize.height * userZoom - bounds.height / 2)
            }
            needsSourceLayout = false
            lastViewportSize = bounds.size
        }
        centerContent()
        updateCanvasDiagnostics()
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { photoContent }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerContent()
        notifyZoomState()
    }

    private func centerContent() {
        let scaledWidth = photoContent.frame.width
        let scaledHeight = photoContent.frame.height
        let horizontal = max(0, (bounds.width - scaledWidth) / 2)
        let vertical = max(0, (bounds.height - scaledHeight) / 2)
        contentInset = UIEdgeInsets(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
        overlay.zoomScale = zoomScale
        updateCanvasDiagnostics()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) { updateCanvasDiagnostics() }

    private func updateCanvasDiagnostics() {
        guard ProcessInfo.processInfo.arguments.contains("-veil-ui-testing") else { return }
        accessibilityValue = String(format: "%.4f,%.2f,%.2f", zoomScale, contentOffset.x + contentInset.left, contentOffset.y + contentInset.top)
    }

    private func notifyZoomState() {
        let zoomed = zoomScale > minimumZoomScale * 1.04
        guard zoomed != lastZoomState else { return }
        lastZoomState = zoomed
        onZoomChanged?(zoomed)
    }

    func fitToScreen() {
        setZoomScale(1, animated: false)
        centerContent()
        setContentOffset(CGPoint(x: -contentInset.left, y: -contentInset.top), animated: false)
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        fitToScreen()
    }

}

private final class PhotoRegionOverlay: UIView {
    private enum DragKind { case create, move(Int), resize(Int), delete(Int) }
    private var imageSize = CGSize.zero
    private var mode: EditorMode?
    private var faces: [CGRect] = []
    private var selectedFaces = Set<Int>()
    private var plates: [CGRect] = []
    private var selectedPlates = Set<Int>()
    private var regions: [BlurRegion] = []
    private var drawsRegions = true
    private var onFaces: ((Int) -> Void)?
    private var onPlate: ((Int) -> Void)?
    private var onRegions: (([BlurRegion]) -> Void)?
    private var startPoint: CGPoint?
    private var activeKind: DragKind?
    private var draftRect: CGRect?
    var zoomScale: CGFloat = 1 { didSet { setNeedsDisplay() } }

    func configure(imageSize: CGSize, mode: EditorMode?, faces: [CGRect], selectedFaces: Set<Int>, plates: [CGRect], selectedPlates: Set<Int>,
                   regions: [BlurRegion], drawsRegions: Bool, onFaces: @escaping (Int) -> Void, onPlate: @escaping (Int) -> Void,
                   onRegions: @escaping ([BlurRegion]) -> Void) {
        self.imageSize = imageSize; self.mode = mode; self.faces = faces; self.selectedFaces = selectedFaces
        self.plates = plates; self.selectedPlates = selectedPlates; self.regions = regions; self.drawsRegions = drawsRegions
        self.onFaces = onFaces; self.onPlate = onPlate; self.onRegions = onRegions
        isUserInteractionEnabled = mode != nil
        accessibilityIdentifier = "photoRegions"
        super.accessibilityElements = makeAccessibleRegions()
        setNeedsDisplay()
    }

    func updateCanvasSize(_ size: CGSize) {
        imageSize = size
        super.accessibilityElements = makeAccessibleRegions()
        setNeedsDisplay()
    }

    override var accessibilityElements: [Any]? {
        get { super.accessibilityElements }
        set { super.accessibilityElements = newValue }
    }

    private func makeAccessibleRegions() -> [Any] {
        var elements: [Any] = []
        for (index, rect) in faces.enumerated() {
            let element = UIAccessibilityElement(accessibilityContainer: self)
            element.accessibilityLabel = selectedFaces.contains(index) ? "Blurred face \(index + 1)" : "Face \(index + 1)"
            element.accessibilityIdentifier = "face_\(index)"
            element.accessibilityTraits = .button
            element.accessibilityFrameInContainerSpace = pixelRect(rect)
            elements.append(element)
        }
        for (index, rect) in plates.enumerated() {
            let element = UIAccessibilityElement(accessibilityContainer: self)
            element.accessibilityLabel = selectedPlates.contains(index) ? "Blurred plate suggestion" : "Plate suggestion"
            element.accessibilityIdentifier = "plate_\(index)"
            element.accessibilityTraits = .button
            element.accessibilityFrameInContainerSpace = pixelRect(rect)
            elements.append(element)
        }
        for (index, region) in regions.enumerated() {
            let element = UIAccessibilityElement(accessibilityContainer: self)
            element.accessibilityLabel = "Blur region \(index + 1)"
            element.accessibilityIdentifier = "blur_region_\(index)"
            element.accessibilityValue = String(format: "%.6f,%.6f,%.6f,%.6f", region.rect.minX, region.rect.minY, region.rect.width, region.rect.height)
            element.accessibilityTraits = .button
            element.accessibilityFrameInContainerSpace = pixelRect(region.rect)
            elements.append(element)
        }
        return elements
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        context.setLineWidth(2 / max(zoomScale, 0.01))
        for (index, face) in faces.enumerated() {
            let box = pixelRect(face)
            // Corner marks indicate a tappable face without circular controls or handles.
            let length = min(12 / zoomScale, min(box.width, box.height) * 0.18)
            context.setStrokeColor(UIColor.white.withAlphaComponent(selectedFaces.contains(index) ? 0.8 : 0.5).cgColor)
            context.setLineDash(phase: 0, lengths: [])
            for (x, y, dx, dy) in [(box.minX, box.minY, length, length), (box.maxX, box.minY, -length, length),
                                   (box.minX, box.maxY, length, -length), (box.maxX, box.maxY, -length, -length)] {
                context.move(to: CGPoint(x: x, y: y + dy))
                context.addLine(to: CGPoint(x: x, y: y))
                context.addLine(to: CGPoint(x: x + dx, y: y))
            }
            context.strokePath()
        }

        for (index, plate) in plates.enumerated() {
            let box = pixelRect(plate)
            let path = UIBezierPath(roundedRect: box, cornerRadius: min(box.height * 0.15, 28))
            context.setStrokeColor(UIColor.systemOrange.cgColor)
            context.setLineDash(phase: 0, lengths: selectedPlates.contains(index) ? [] : [9 / zoomScale, 5 / zoomScale])
            context.addPath(path.cgPath); context.strokePath()
            if selectedPlates.contains(index) {
                context.setFillColor(UIColor.systemOrange.withAlphaComponent(0.16).cgColor)
                context.addPath(path.cgPath); context.fillPath()
                context.setStrokeColor(UIColor.systemOrange.cgColor); context.addPath(path.cgPath); context.strokePath()
            }
        }
        for region in regions {
            drawRegion(region.rect, shape: region.shape, context: context, selected: true)
        }
        if let draftRect {
            let previewRegion = BlurRegion(rect: draftRect, shape: .roundedRectangle)
            drawRegion(previewRegion.rect, shape: previewRegion.shape, context: context, selected: false)
        }
        context.restoreGState()
    }

    private func drawRegion(_ normalized: CGRect, shape: BlurRegion.Shape, context: CGContext, selected: Bool) {
        let box = pixelRect(normalized)
        let path: UIBezierPath = shape == .oval ? UIBezierPath(ovalIn: box) : UIBezierPath(roundedRect: box, cornerRadius: min(22, box.height * 0.18))
        context.setLineDash(phase: 0, lengths: [])
        context.setFillColor(UIColor.systemOrange.withAlphaComponent(selected ? 0.20 : 0.32).cgColor)
        context.addPath(path.cgPath); context.fillPath()
        context.setStrokeColor(UIColor.white.cgColor)
        context.addPath(path.cgPath); context.strokePath()
        if selected {
            let handleSize = 42 / max(zoomScale, 0.01)
            let closeRect = CGRect(x: box.maxX - handleSize * 0.5, y: box.minY - handleSize * 0.5, width: handleSize, height: handleSize)
            context.setFillColor(UIColor.black.withAlphaComponent(0.78).cgColor)
            context.fillEllipse(in: closeRect)
            context.setStrokeColor(UIColor.white.cgColor); context.setLineWidth(2 / max(zoomScale, 0.01))
            context.move(to: CGPoint(x: closeRect.midX - 5 / zoomScale, y: closeRect.midY - 5 / zoomScale))
            context.addLine(to: CGPoint(x: closeRect.midX + 5 / zoomScale, y: closeRect.midY + 5 / zoomScale))
            context.move(to: CGPoint(x: closeRect.midX + 5 / zoomScale, y: closeRect.midY - 5 / zoomScale))
            context.addLine(to: CGPoint(x: closeRect.midX - 5 / zoomScale, y: closeRect.midY + 5 / zoomScale)); context.strokePath()
            let resize = CGRect(x: box.maxX - handleSize * 0.5, y: box.maxY - handleSize * 0.5, width: handleSize, height: handleSize)
            context.setFillColor(UIColor.white.cgColor); context.fillEllipse(in: resize)
            context.setStrokeColor(UIColor.systemOrange.cgColor)
            context.move(to: CGPoint(x: resize.minX + 13 / zoomScale, y: resize.maxY - 13 / zoomScale))
            context.addLine(to: CGPoint(x: resize.maxX - 13 / zoomScale, y: resize.minY + 13 / zoomScale)); context.strokePath()
        }
    }

    private func pixelRect(_ rect: CGRect) -> CGRect {
        CGRect(x: rect.minX * imageSize.width, y: rect.minY * imageSize.height,
               width: rect.width * imageSize.width, height: rect.height * imageSize.height)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard event?.allTouches?.count == 1, let point = touches.first?.location(in: self) else { clearDraft(); return }
        switch mode {
        case .faces, .plate:
            startPoint = point
        case .manual:
            guard drawsRegions else { return }
            beginRegionGesture(at: point)
        default: break
        }
    }

    private func beginRegionGesture(at point: CGPoint) {
        let hit = regions.indices.reversed().first { pixelRect(regions[$0].rect).insetBy(dx: -28 / zoomScale, dy: -28 / zoomScale).contains(point) }
        if let hit {
            let box = pixelRect(regions[hit].rect)
            let handle = 44 / max(zoomScale, 0.01)
            let deleteHit = CGRect(x: box.maxX - handle * 0.5, y: box.minY - handle * 0.5, width: handle, height: handle)
            let resizeHit = CGRect(x: box.maxX - handle * 0.5, y: box.maxY - handle * 0.5, width: handle, height: handle)
            if resizeHit.contains(point) {
                activeKind = .resize(hit)
            } else if deleteHit.contains(point) {
                activeKind = .delete(hit)
            } else {
                activeKind = .move(hit)
            }
        } else {
            activeKind = .create
        }
        startPoint = point
        draftRect = activeKind.map { kind in
            switch kind {
            case .create: return CGRect(x: point.x / imageSize.width, y: point.y / imageSize.height, width: 0.001, height: 0.001)
            case .move(let index), .resize(let index), .delete(let index): return regions[index].rect
            }
        }
        setNeedsDisplay()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard event?.allTouches?.count == 1 else { clearDraft(); return }
        guard let point = touches.first?.location(in: self), let startPoint, let activeKind else { return }
        let dx = (point.x - startPoint.x) / imageSize.width
        let dy = (point.y - startPoint.y) / imageSize.height
        switch activeKind {
        case .create:
            let start = CGPoint(x: startPoint.x / imageSize.width, y: startPoint.y / imageSize.height)
            let end = CGPoint(x: point.x / imageSize.width, y: point.y / imageSize.height)
            draftRect = CGRect(x: min(start.x, end.x), y: min(start.y, end.y), width: abs(dx), height: abs(dy))
        case .move(let index):
            var rect = regions[index].rect
            rect.origin.x = min(max(0, rect.minX + dx), 1 - rect.width)
            rect.origin.y = min(max(0, rect.minY + dy), 1 - rect.height)
            draftRect = rect
        case .resize(let index):
            var rect = regions[index].rect
            rect.size.width = min(max(6 / (zoomScale * imageSize.width), rect.width + dx), 1 - rect.minX)
            rect.size.height = min(max(6 / (zoomScale * imageSize.height), rect.height + dy), 1 - rect.minY)
            draftRect = rect
        case .delete: break
        }
        setNeedsDisplay()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let point = touches.first?.location(in: self), let startPoint,
           hypot(point.x - startPoint.x, point.y - startPoint.y) * zoomScale < 12 {
            if mode == .faces, let index = faces.indices.first(where: { pixelRect(faces[$0]).contains(point) }) { onFaces?(index) }
            if mode == .plate, let index = plates.indices.first(where: { pixelRect(plates[$0]).contains(point) }) { onPlate?(index) }
        }
        guard let activeKind, let draftRect else { clearDraft(); return }
        switch activeKind {
        case .create:
            let minWidth = 6 / max(zoomScale * imageSize.width, 1)
            let minHeight = 6 / max(zoomScale * imageSize.height, 1)
            if draftRect.width >= minWidth && draftRect.height >= minHeight {
                onRegions?(regions + [BlurRegion(rect: draftRect, shape: .roundedRectangle)])
            }
        case .move(let index), .resize(let index):
            var updated = regions
            updated[index].rect = draftRect
            onRegions?(updated)
        case .delete(let index):
            var updated = regions
            updated.remove(at: index)
            onRegions?(updated)
        }
        clearDraft()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { clearDraft() }

    private func clearDraft() {
        activeKind = nil; startPoint = nil; draftRect = nil; setNeedsDisplay()
    }
}
