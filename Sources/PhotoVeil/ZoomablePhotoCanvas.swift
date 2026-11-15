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
    let newRegionShape: BlurRegion.Shape
    let drawsRegions: Bool
    let paintsStrokes: Bool
    let strokes: [BlurStroke]
    let onStroke: (BlurStroke?, Bool) -> Void
    let onFaces: (Int) -> Void
    let onPlate: (Int) -> Void
    let onRegions: ([BlurRegion]) -> Void
    let onZoomChanged: (Bool) -> Void
    var watermark: PhotoWatermark? = nil
    var onWatermarkMove: (CGPoint, Bool) -> Void = { _, _ in }
    var onDetectionRect: (Int, CGRect) -> Void = { _, _ in }
    var detectionContext = ""
    var premiumPreview = false
    var protectsPreview = false

    func makeUIView(context: Context) -> ZoomingPhotoView {
        let view = ZoomingPhotoView()
        view.configure(original: original, preview: preview, mode: mode, faces: faces, selectedFaces: selectedFaces,
                       plates: plates, selectedPlates: selectedPlates, regions: regions, newRegionShape: newRegionShape, drawsRegions: drawsRegions, paintsStrokes: paintsStrokes, strokes: strokes, onStroke: onStroke,
                       onFaces: onFaces, onPlate: onPlate, onRegions: onRegions, onZoomChanged: onZoomChanged, watermark: watermark, onWatermarkMove: onWatermarkMove, onDetectionRect: onDetectionRect, detectionContext: detectionContext,
                       premiumPreview: premiumPreview, protectsPreview: protectsPreview)
        return view
    }

    func updateUIView(_ view: ZoomingPhotoView, context: Context) {
        view.configure(original: original, preview: preview, mode: mode, faces: faces, selectedFaces: selectedFaces,
                       plates: plates, selectedPlates: selectedPlates, regions: regions, newRegionShape: newRegionShape, drawsRegions: drawsRegions, paintsStrokes: paintsStrokes, strokes: strokes, onStroke: onStroke,
                       onFaces: onFaces, onPlate: onPlate, onRegions: onRegions, onZoomChanged: onZoomChanged, watermark: watermark, onWatermarkMove: onWatermarkMove, onDetectionRect: onDetectionRect, detectionContext: detectionContext,
                       premiumPreview: premiumPreview, protectsPreview: protectsPreview)
    }
}

/// Reusable, noninteractive presentation mark for processed gallery images.
struct PremiumPreviewLattice: UIViewRepresentable {
    var marked: Bool
    var checking: Bool = false

    func makeUIView(context: Context) -> PremiumPreviewLatticeView {
        PremiumPreviewLatticeView(marked: marked, checking: checking)
    }

    func updateUIView(_ view: PremiumPreviewLatticeView, context: Context) {
        view.setPresentation(marked: marked, checking: checking)
    }
}

private final class DetectionAccessibilityElement: UIAccessibilityElement {
    var activate: (() -> Void)?
    var adjust: ((CGFloat, CGFloat, CGFloat, CGFloat) -> Void)?
    override func accessibilityActivate() -> Bool {
        guard let activate else { return false }
        activate()
        return true
    }
    func actions() -> [UIAccessibilityCustomAction] {
        [UIAccessibilityCustomAction(name: "Move left", actionHandler: { [weak self] _ in self?.adjust?(-0.02, 0, 0, 0); return true }),
         UIAccessibilityCustomAction(name: "Move right", actionHandler: { [weak self] _ in self?.adjust?(0.02, 0, 0, 0); return true }),
         UIAccessibilityCustomAction(name: "Move up", actionHandler: { [weak self] _ in self?.adjust?(0, -0.02, 0, 0); return true }),
         UIAccessibilityCustomAction(name: "Move down", actionHandler: { [weak self] _ in self?.adjust?(0, 0.02, 0, 0); return true }),
         UIAccessibilityCustomAction(name: "Grow", actionHandler: { [weak self] _ in self?.adjust?(0, 0, 0.02, 0.02); return true }),
         UIAccessibilityCustomAction(name: "Shrink", actionHandler: { [weak self] _ in self?.adjust?(0, 0, -0.02, -0.02); return true })]
    }
}

final class ZoomingPhotoView: UIScrollView, UIScrollViewDelegate {
    private let photoContent = UIView()
    private let imageView = UIImageView()
    private let overlay = PhotoRegionOverlay()
    private let watermarkOverlay = WatermarkPositionOverlay()
    private let premiumPreviewLattice = PremiumPreviewLatticeView()
    private var showsPremiumPreview = false
    private var protectsPreview = false
    private var sourceIdentity: ObjectIdentifier?
    private var detectionContext = ""
    private var sourceSize: CGSize = .zero
    private var needsSourceLayout = true
    private var isLayingOutPhoto = false
    private var lastViewportSize: CGSize = .zero
    private var lastZoomState: Bool?
    private var onZoomChanged: ((Bool) -> Void)?
    private var fitObserver: NSObjectProtocol?
    private var previewInvalidationObserver: NSObjectProtocol?

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
        addSubview(premiumPreviewLattice)
        photoContent.addSubview(imageView)
        photoContent.addSubview(overlay)
        photoContent.addSubview(watermarkOverlay)
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
        fitObserver = NotificationCenter.default.addObserver(forName: .photoVeilFitPhoto, object: nil, queue: .main) { [weak self] _ in
            self?.fitToScreen()
        }
        previewInvalidationObserver = NotificationCenter.default.addObserver(forName: .veilPreviewAccessInvalidated, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            self.protectsPreview = true
            self.photoContent.isHidden = true
            self.premiumPreviewLattice.setPresentation(marked: false, checking: true)
            self.updatePreviewLayers()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        if let fitObserver { NotificationCenter.default.removeObserver(fitObserver) }
        if let previewInvalidationObserver { NotificationCenter.default.removeObserver(previewInvalidationObserver) }
    }

    func configure(original: UIImage, preview: UIImage, mode: EditorMode?, faces: [CGRect], selectedFaces: Set<Int>,
                   plates: [CGRect], selectedPlates: Set<Int>, regions: [BlurRegion], newRegionShape: BlurRegion.Shape, drawsRegions: Bool, paintsStrokes: Bool, strokes: [BlurStroke], onStroke: @escaping (BlurStroke?, Bool) -> Void,
                   onFaces: @escaping (Int) -> Void, onPlate: @escaping (Int) -> Void,
                   onRegions: @escaping ([BlurRegion]) -> Void, onZoomChanged: @escaping (Bool) -> Void, watermark: PhotoWatermark? = nil, onWatermarkMove: @escaping (CGPoint, Bool) -> Void = { _, _ in }, onDetectionRect: @escaping (Int, CGRect) -> Void = { _, _ in }, detectionContext: String = "",
                   premiumPreview: Bool = false, protectsPreview: Bool = false) {
        showsPremiumPreview = premiumPreview
        self.protectsPreview = protectsPreview
        // Hiding the source and raising an opaque sibling happen in the same
        // synchronous update, so an unknown entitlement never exposes a clean frame.
        photoContent.isHidden = protectsPreview
        premiumPreviewLattice.setPresentation(marked: premiumPreview, checking: protectsPreview)
        updatePreviewLayers()
        if self.detectionContext != detectionContext { overlay.cancelPendingGesture() }
        self.detectionContext = detectionContext
        let identity = ObjectIdentifier(original)
        let size = original.cgImage.map { CGSize(width: $0.width, height: $0.height) } ?? original.size
        let sourceChanged = identity != sourceIdentity || size != sourceSize
        if sourceChanged { overlay.cancelPendingGesture() }
        sourceIdentity = identity
        sourceSize = size
        imageView.image = preview
        self.onZoomChanged = onZoomChanged
        overlay.configure(imageSize: photoContent.bounds.size, mode: mode, faces: mode == .faces ? faces : [], selectedFaces: selectedFaces,
                          plates: mode == .plate || mode == .documents ? plates : [], selectedPlates: selectedPlates, regions: mode == .manual ? regions : [], newRegionShape: newRegionShape,
                          drawsRegions: drawsRegions, paintsStrokes: paintsStrokes, strokes: mode == .manual ? strokes : [], onStroke: onStroke, onFaces: onFaces, onPlate: onPlate, onRegions: onRegions, onDetectionRect: onDetectionRect)
        watermarkOverlay.configure(watermark, move: onWatermarkMove)
        let canvasInteractive = mode == .manual
        // One finger edits; two fingers can always navigate while drawing.
        panGestureRecognizer.isEnabled = true
        let detectionInteractive = mode == .faces || mode == .plate || mode == .documents
        panGestureRecognizer.minimumNumberOfTouches = (canvasInteractive && drawsRegions) || watermark != nil || detectionInteractive ? 2 : 1
        panGestureRecognizer.maximumNumberOfTouches = 2
        setNeedsLayout()
        if sourceChanged { needsSourceLayout = true }
        updatePreviewLayers()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updatePreviewLayers()
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
            watermarkOverlay.frame = photoContent.bounds
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
        updatePreviewLayers()
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { photoContent }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerContent()
        notifyZoomState()
        updatePreviewLayers()
    }

    private func centerContent() {
        let scaledWidth = photoContent.frame.width
        let scaledHeight = photoContent.frame.height
        let horizontal = max(0, (bounds.width - scaledWidth) / 2)
        let vertical = max(0, (bounds.height - scaledHeight) / 2)
        contentInset = UIEdgeInsets(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
        overlay.zoomScale = zoomScale
        watermarkOverlay.zoomScale = zoomScale
        updateCanvasDiagnostics()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCanvasDiagnostics()
        updatePreviewLayers()
    }

    private func updatePreviewLayers() {
        let photoRect = photoContent.convert(photoContent.bounds, to: self)
        let visiblePhotoRect = photoRect.intersection(bounds)
        let hasVisiblePhoto = !visiblePhotoRect.isNull && !visiblePhotoRect.isEmpty
        premiumPreviewLattice.frame = hasVisiblePhoto ? visiblePhotoRect : .zero
        premiumPreviewLattice.setPresentation(marked: showsPremiumPreview && !protectsPreview, checking: protectsPreview)
        premiumPreviewLattice.isHidden = !hasVisiblePhoto || (!showsPremiumPreview && !protectsPreview)
        bringSubviewToFront(premiumPreviewLattice)
    }

    private func updateCanvasDiagnostics() {
        #if DEBUG
        guard ProcessInfo.processInfo.arguments.contains("-veil-ui-testing") else { return }
        accessibilityValue = String(format: "%.4f,%.2f,%.2f", zoomScale, contentOffset.x + contentInset.left, contentOffset.y + contentInset.top)
        #endif
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

/// Draws a sparse, screen-space lattice over the visible photograph only.
/// It has one accessibility element and never participates in touch handling.
final class PremiumPreviewLatticeView: UIView {
    private var marked = false
    private var checking = false
    private var invalidationObserver: NSObjectProtocol?

    init(marked: Bool = false, checking: Bool = false) {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        clipsToBounds = true
        backgroundColor = .clear
        isOpaque = false
        updateAccessibility()
        setPresentation(marked: marked, checking: checking)
        invalidationObserver = NotificationCenter.default.addObserver(forName: .veilPreviewAccessInvalidated, object: nil, queue: .main) { [weak self] _ in
            self?.setPresentation(marked: false, checking: true)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        if let invalidationObserver { NotificationCenter.default.removeObserver(invalidationObserver) }
    }

    func setPresentation(marked: Bool, checking: Bool) {
        let nextMarked = marked && !checking
        guard self.marked != nextMarked || self.checking != checking else { return }
        self.marked = nextMarked
        self.checking = checking
        backgroundColor = checking ? .secondarySystemBackground : .clear
        isOpaque = checking
        updateAccessibility()
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard marked, !checking, let context = UIGraphicsGetCurrentContext(), bounds.width > 0, bounds.height > 0 else { return }
        context.saveGState()
        context.clip(to: bounds)
        let label = "VAIL · PREVIEW" as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: UIColor.white.withAlphaComponent(0.46),
            .strokeColor: UIColor(white: 0.18, alpha: 0.42),
            .strokeWidth: -0.8
        ]
        let labelSize = label.size(withAttributes: attributes)
        let stepX = max(150, labelSize.width + 42)
        let stepY: CGFloat = 76
        let rowLimit = Int(ceil(bounds.height / stepY)) + 1
        let columnLimit = Int(ceil(bounds.width / stepX)) + 1
        for row in -1...rowLimit {
            let y = CGFloat(row) * stepY
            let stagger: CGFloat = row.isMultiple(of: 2) ? 0 : stepX * 0.5
            for column in -1...columnLimit {
                let center = CGPoint(x: CGFloat(column) * stepX + stagger, y: y)
                context.saveGState()
                context.translateBy(x: center.x, y: center.y)
                context.rotate(by: -.pi / 9)
                label.draw(at: CGPoint(x: -labelSize.width / 2, y: -labelSize.height / 2), withAttributes: attributes)
                context.restoreGState()
            }
        }
        context.restoreGState()
    }

    private func updateAccessibility() {
        isAccessibilityElement = marked || checking
        accessibilityElementsHidden = !isAccessibilityElement
        accessibilityTraits = .staticText
        if checking {
            accessibilityIdentifier = "premiumPreviewChecking"
            accessibilityLabel = "Checking export access"
        } else if marked {
            accessibilityIdentifier = "premiumPreviewWatermark"
            accessibilityLabel = "Preview watermark"
        } else {
            accessibilityIdentifier = nil
            accessibilityLabel = nil
        }
    }
}

/// Preserve the first touch independently of UIKit's pan-recognition threshold.
/// Hit classification must use the handle the user touched, not a later location.
private final class DetectionPanGestureRecognizer: UIPanGestureRecognizer {
    private(set) var touchOrigin: CGPoint?
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if touchOrigin == nil, let view, let touch = touches.first { touchOrigin = touch.location(in: view) }
        super.touchesBegan(touches, with: event)
    }
    override func reset() { touchOrigin = nil; super.reset() }
}

private final class PhotoRegionOverlay: UIView {
    private enum DragKind { case create, move(Int), resize(Int), delete(Int), detection(Int, Bool, Bool) }
    private var imageSize = CGSize.zero
    private var mode: EditorMode?
    private var faces: [CGRect] = []
    private var selectedFaces = Set<Int>()
    private var plates: [CGRect] = []
    private var selectedPlates = Set<Int>()
    private var regions: [BlurRegion] = []
    private var newRegionShape: BlurRegion.Shape = .roundedRectangle
    private var drawsRegions = true
    private var paintsStrokes = false
    private var strokes: [BlurStroke] = []
    private var draftStroke: BlurStroke?
    private var onStroke: ((BlurStroke?, Bool) -> Void)?
    private lazy var plateTap = UITapGestureRecognizer(target: self, action: #selector(selectPlate(_:)))
    private lazy var detectionPan = DetectionPanGestureRecognizer(target: self, action: #selector(dragDetection(_:)))

    override init(frame: CGRect) {
        super.init(frame: frame)
        // A recognized tap survives UIScrollView touch arbitration.
        detectionPan.minimumNumberOfTouches = 1; detectionPan.maximumNumberOfTouches = 1
        addGestureRecognizer(detectionPan)
        addGestureRecognizer(plateTap)
        plateTap.require(toFail: detectionPan)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func selectPlate(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        let point = gesture.location(in: self)
        if mode == .faces {
            if let index = faces.indices.first(where: { pixelRect(faces[$0]).contains(point) }) { onFaces?(index) }
        } else if mode == .plate || mode == .documents {
            if let index = plates.indices.first(where: { pixelRect(plates[$0]).contains(point) }) { onPlate?(index) }
        }
    }

    @objc private func dragDetection(_ gesture: DetectionPanGestureRecognizer) {
        let point = gesture.location(in: self)
        switch gesture.state {
        case .began:
            guard let origin = gesture.touchOrigin else { clearDraft(); return }
            beginDetectionGesture(at: origin, isFaces: mode == .faces)
            updateDetectionDraft(at: point)
        case .changed: updateDetectionDraft(at: point)
        case .ended:
            updateDetectionDraft(at: point)
            if case .detection(let index, let isFaces, _) = activeKind, let draftRect {
                let source = isFaces ? faces : plates
                if source.indices.contains(index), source[index] != draftRect { onDetectionRect?(index, draftRect) }
            }
            clearDraft()
        case .cancelled, .failed: clearDraft()
        default: break
        }
    }

    private func updateDetectionDraft(at point: CGPoint) {
        guard case .detection(let index, let isFaces, let resizing) = activeKind,
              let startPoint, imageSize.width > 0, imageSize.height > 0 else { return }
        let source = isFaces ? faces : plates
        guard source.indices.contains(index) else { clearDraft(); return }
        let dx = (point.x - startPoint.x) / imageSize.width
        let dy = (point.y - startPoint.y) / imageSize.height
        var rect = source[index]
        if resizing {
            rect.size.width = min(max(6 / (zoomScale * imageSize.width), rect.width + dx), 1 - rect.minX)
            rect.size.height = min(max(6 / (zoomScale * imageSize.height), rect.height + dy), 1 - rect.minY)
        } else {
            rect.origin.x = min(max(0, rect.minX + dx), 1 - rect.width)
            rect.origin.y = min(max(0, rect.minY + dy), 1 - rect.height)
        }
        draftRect = rect; setNeedsDisplay()
    }

    private var onFaces: ((Int) -> Void)?
    private var onPlate: ((Int) -> Void)?
    private var onRegions: (([BlurRegion]) -> Void)?
    private var startPoint: CGPoint?
    private var activeKind: DragKind?
    private var draftRect: CGRect?
    private var onDetectionRect: ((Int, CGRect) -> Void)?
    private var configurationRevision = 0
    var zoomScale: CGFloat = 1 { didSet { setNeedsDisplay() } }

    func configure(imageSize: CGSize, mode: EditorMode?, faces: [CGRect], selectedFaces: Set<Int>, plates: [CGRect], selectedPlates: Set<Int>,
                   regions: [BlurRegion], newRegionShape: BlurRegion.Shape, drawsRegions: Bool, paintsStrokes: Bool, strokes: [BlurStroke], onStroke: @escaping (BlurStroke?, Bool) -> Void, onFaces: @escaping (Int) -> Void, onPlate: @escaping (Int) -> Void,
                   onRegions: @escaping ([BlurRegion]) -> Void, onDetectionRect: @escaping (Int, CGRect) -> Void = { _, _ in }) {
        if self.mode != mode || self.faces != faces || self.plates != plates ||
            self.selectedFaces != selectedFaces || self.selectedPlates != selectedPlates ||
            (self.imageSize != .zero && self.imageSize != imageSize) {
            cancelPendingGesture()
        }
        self.imageSize = imageSize; self.mode = mode; self.faces = faces; self.selectedFaces = selectedFaces
        self.plates = plates; self.selectedPlates = selectedPlates; self.regions = regions; self.newRegionShape = newRegionShape; self.drawsRegions = drawsRegions
        self.paintsStrokes = paintsStrokes; self.strokes = strokes; self.onStroke = onStroke
        self.onDetectionRect = onDetectionRect
        let automatic = mode == .faces || mode == .plate || mode == .documents
        plateTap.isEnabled = automatic
        detectionPan.isEnabled = automatic
        self.onFaces = onFaces; self.onPlate = onPlate; self.onRegions = onRegions
        isUserInteractionEnabled = mode != nil
        accessibilityIdentifier = "photoRegions"
        super.accessibilityElements = makeAccessibleRegions()
        setNeedsDisplay()
    }

    func updateCanvasSize(_ size: CGSize) {
        if size != imageSize { cancelPendingGesture() }
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
            let element = DetectionAccessibilityElement(accessibilityContainer: self)
            element.activate = { [weak self] in self?.onFaces?(index) }
            element.accessibilityLabel = selectedFaces.contains(index) ? "Blurred face \(index + 1)" : "Face \(index + 1)"
            element.accessibilityHint = "Double-tap to toggle privacy effect"
            element.accessibilityValue = selectedFaces.contains(index) ? "Blur on" : "Blur off"
            element.accessibilityIdentifier = "face_\(index)"
            element.accessibilityTraits = .button
            element.accessibilityFrameInContainerSpace = pixelRect(rect)
            addDetectionAdjustments(to: element, index: index, rect: rect)
            elements.append(element)
        }
        for (index, rect) in plates.enumerated() {
            let element = DetectionAccessibilityElement(accessibilityContainer: self)
            element.activate = { [weak self] in self?.onPlate?(index) }
            element.accessibilityLabel = mode == .documents
                ? "\(selectedPlates.contains(index) ? "Hidden" : "Visible") document region \(index + 1)"
                : (selectedPlates.contains(index) ? "Blurred plate suggestion" : "Plate suggestion")
            element.accessibilityHint = "Double-tap to toggle privacy effect"
            element.accessibilityValue = selectedPlates.contains(index) ? "Blur on" : "Blur off"
            element.accessibilityIdentifier = "\(mode == .documents ? "document" : "plate")_\(index)"
            element.accessibilityTraits = .button
            element.accessibilityFrameInContainerSpace = pixelRect(rect)
            addDetectionAdjustments(to: element, index: index, rect: rect)
            elements.append(element)
        }
        for (index, region) in regions.enumerated() {
            let element = UIAccessibilityElement(accessibilityContainer: self)
            element.accessibilityLabel = "Blur region \(index + 1)"
            element.accessibilityIdentifier = "blur_region_\(index)"
            if ProcessInfo.processInfo.arguments.contains("-veil-ui-testing") {
                element.accessibilityValue = String(format: "%.6f,%.6f,%.6f,%.6f", region.rect.minX, region.rect.minY, region.rect.width, region.rect.height)
            }
            element.accessibilityTraits = .button
            element.accessibilityFrameInContainerSpace = pixelRect(region.rect)
            elements.append(element)
        }
        for (index, stroke) in strokes.enumerated() {
            let element = UIAccessibilityElement(accessibilityContainer: self)
            element.accessibilityLabel = "Blur stroke \(index + 1)"
            element.accessibilityIdentifier = "blur_stroke_\(index)"
            element.accessibilityValue = stroke.points.map { String(format: "%.6f,%.6f", $0.x, $0.y) }.joined(separator: ";")
            let xs = stroke.points.map(\.x), ys = stroke.points.map(\.y)
            if let x = xs.min(), let y = ys.min(), let maxX = xs.max(), let maxY = ys.max() {
                element.accessibilityFrameInContainerSpace = pixelRect(CGRect(x: x, y: y, width: max(0.01, maxX - x), height: max(0.01, maxY - y)))
            }
            elements.append(element)
        }
        return elements
    }

    private func addDetectionAdjustments(to element: DetectionAccessibilityElement, index: Int, rect: CGRect) {
        let isFaces = mode == .faces
        let selected = isFaces ? selectedFaces : selectedPlates
        guard selected.contains(index) else { return }
        let revision = configurationRevision
        element.accessibilityCustomActions = element.actions()
        element.adjust = { [weak self] dx, dy, dw, dh in
            guard let self, self.configurationRevision == revision else { return }
            let current = isFaces ? self.faces : self.plates
            guard current.indices.contains(index) else { return }
            var updated = current[index]
            updated.size.width = min(1, max(0.01, updated.width + dw))
            updated.size.height = min(1, max(0.01, updated.height + dh))
            updated.origin.x = min(max(0, updated.minX + dx), 1 - updated.width)
            updated.origin.y = min(max(0, updated.minY + dy), 1 - updated.height)
            if isFaces { self.faces[index] = updated } else { self.plates[index] = updated }
            self.onDetectionRect?(index, updated)
            self.setNeedsDisplay()
        }
        if ProcessInfo.processInfo.arguments.contains("-veil-ui-testing") {
            element.accessibilityValue = String(format: "%.6f,%.6f,%.6f,%.6f", rect.minX, rect.minY, rect.width, rect.height)
        }
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        context.setLineWidth(2 / max(zoomScale, 0.01))
        for (index, face) in faces.enumerated() { drawDetection(draftRect.flatMap { isDetection(index, inFaces: true) ? $0 : nil } ?? face, active: selectedFaces.contains(index), context: context) }
        for (index, plate) in plates.enumerated() { drawDetection(draftRect.flatMap { isDetection(index, inFaces: false) ? $0 : nil } ?? plate, active: selectedPlates.contains(index), context: context) }
        for region in regions {
            drawRegion(region.rect, shape: region.shape, context: context, selected: true)
        }
        if let draftRect, mode == .manual {
            let previewRegion = BlurRegion(rect: draftRect, shape: newRegionShape)
            drawRegion(previewRegion.rect, shape: previewRegion.shape, context: context, selected: false)
        }
        context.restoreGState()
    }

    private func isDetection(_ index: Int, inFaces: Bool) -> Bool {
        guard let activeKind, case .detection(let active, let facesMode, _) = activeKind else { return false }
        return active == index && facesMode == inFaces
    }

    private func drawDetection(_ normalized: CGRect, active: Bool, context: CGContext) {
        let box = pixelRect(normalized)
        let length = min(12 / zoomScale, min(box.width, box.height) * 0.2)
        context.setLineDash(phase: 0, lengths: active ? [] : [3 / zoomScale, 3 / zoomScale])
        // Neutral shadow keeps white corners legible over both light and dark photographs.
        context.setShadow(offset: .zero, blur: 2 / zoomScale, color: UIColor.black.withAlphaComponent(0.75).cgColor)
        context.setStrokeColor(UIColor.white.withAlphaComponent(active ? 0.72 : 0.9).cgColor)
        for (x, y, dx, dy) in [(box.minX, box.minY, length, length), (box.maxX, box.minY, -length, length),
                               (box.minX, box.maxY, length, -length), (box.maxX, box.maxY, -length, -length)] {
            context.move(to: CGPoint(x: x, y: y + dy)); context.addLine(to: CGPoint(x: x, y: y)); context.addLine(to: CGPoint(x: x + dx, y: y))
        }
        context.strokePath()
        if active {
            let diameter = 12 / max(zoomScale, 0.01)
            context.setFillColor(UIColor.white.cgColor)
            context.fillEllipse(in: CGRect(x: box.maxX - diameter / 2, y: box.maxY - diameter / 2,
                                          width: diameter, height: diameter))
        }
        context.setShadow(offset: .zero, blur: 0, color: nil)
    }

    private func drawRegion(_ normalized: CGRect, shape: BlurRegion.Shape, context: CGContext, selected: Bool) {
        let box = pixelRect(normalized)
        let path: UIBezierPath = shape == .oval ? UIBezierPath(ovalIn: box) : UIBezierPath(roundedRect: box, cornerRadius: min(22, box.height * 0.18))
        context.setLineDash(phase: 0, lengths: [])
        context.setFillColor(UIColor.white.withAlphaComponent(selected ? 0.04 : 0.12).cgColor)
        context.addPath(path.cgPath); context.fillPath()
        context.setStrokeColor(UIColor.white.cgColor)
        context.addPath(path.cgPath); context.strokePath()
        if selected {
            let handleSize = 44 / max(zoomScale, 0.01)
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
            context.setStrokeColor(UIColor.darkGray.cgColor)
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
        case .faces, .plate, .documents: break // Native recognizers own automatic gestures.
        case .manual:
            guard drawsRegions else { return }
            if paintsStrokes {
                draftStroke = BlurStroke(points: [normalizedPoint(point)])
                onStroke?(draftStroke, false)
            } else {
                beginRegionGesture(at: point)
            }
        default: break
        }
    }

    private func beginDetectionGesture(at point: CGPoint, isFaces: Bool) {
        let detections = isFaces ? faces : plates
        let selected = isFaces ? selectedFaces : selectedPlates
        guard let hit = detections.indices.reversed().first(where: { selected.contains($0) && pixelRect(detections[$0]).insetBy(dx: -28 / zoomScale, dy: -28 / zoomScale).contains(point) }) else { return }
        let box = pixelRect(detections[hit])
        // A small region must retain a draggable body. VoiceOver also offers
        // explicit resize actions, independent of this visual corner target.
        let handle = max(12 / zoomScale, min(22 / zoomScale, min(box.width, box.height) * 0.45))
        let resize = CGRect(x: box.maxX - handle * 0.5, y: box.maxY - handle * 0.5, width: handle, height: handle)
        activeKind = .detection(hit, isFaces, resize.contains(point))
        startPoint = point
        draftRect = detections[hit]
        setNeedsDisplay()
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
            case .detection: return .zero
            }
        }
        setNeedsDisplay()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard event?.allTouches?.count == 1 else { clearDraft(); return }
        if paintsStrokes, var stroke = draftStroke, let point = touches.first?.location(in: self) {
            let normalized = normalizedPoint(point)
            if let last = stroke.points.last,
               hypot((last.x - normalized.x) * imageSize.width, (last.y - normalized.y) * imageSize.height) * zoomScale < 3 { return }
            stroke.points.append(normalized)
            draftStroke = stroke
            onStroke?(stroke, false)
            return
        }
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
        case .detection: break
        }
        setNeedsDisplay()
    }

    private func normalizedPoint(_ point: CGPoint) -> CGPoint {
        CGPoint(x: min(1, max(0, point.x / imageSize.width)), y: min(1, max(0, point.y / imageSize.height)))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard mode == .manual else { return }
        if let stroke = draftStroke {
            draftStroke = nil
            onStroke?(stroke, true)
            return
        }
        guard let activeKind, let draftRect else { clearDraft(); return }
        switch activeKind {
        case .create:
            let minWidth = 6 / max(zoomScale * imageSize.width, 1)
            let minHeight = 6 / max(zoomScale * imageSize.height, 1)
            if draftRect.width >= minWidth && draftRect.height >= minHeight {
                onRegions?(regions + [BlurRegion(rect: draftRect, shape: newRegionShape)])
            }
        case .move(let index), .resize(let index):
            var updated = regions
            updated[index].rect = draftRect
            onRegions?(updated)
        case .delete(let index):
            var updated = regions
            updated.remove(at: index)
            onRegions?(updated)
        case .detection(let index, _, _):
            let source = mode == .faces ? faces : plates
            if source.indices.contains(index), draftRect != source[index] {
                onDetectionRect?(index, draftRect)
            }
        }
        clearDraft()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if mode == .manual { clearDraft() }
    }

    func cancelPendingGesture() {
        configurationRevision += 1
        let enabled = detectionPan.isEnabled
        detectionPan.isEnabled = false // Cancel possible as well as recognized pans.
        detectionPan.isEnabled = enabled
        clearDraft()
    }

    private func clearDraft() {
        if draftStroke != nil { draftStroke = nil; onStroke?(nil, false) }
        activeKind = nil; startPoint = nil; draftRect = nil; setNeedsDisplay()
    }
}

/// Selection only: the visible watermark is always in the shared rendered pixels.
/// This view lives in photoContent, so zoom, pan, rotation and letterboxing use
/// the same image coordinate system as manual privacy regions.
private final class WatermarkPositionOverlay: UIView {
    private var watermark: PhotoWatermark?
    private var move: ((CGPoint, Bool) -> Void)?
    private var initialCenter = CGPoint.zero
    private var currentCenter = CGPoint.zero
    var zoomScale: CGFloat = 1 { didSet { setNeedsDisplay() } }
    private lazy var drag = UIPanGestureRecognizer(target: self, action: #selector(dragged(_:)))

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        drag.minimumNumberOfTouches = 1; drag.maximumNumberOfTouches = 1
        addGestureRecognizer(drag)
        isAccessibilityElement = true
        accessibilityLabel = "Watermark position"
        accessibilityHint = "Use actions to move the watermark, or choose a placement below."
        accessibilityIdentifier = "watermarkPosition"
        accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: "Move left", target: self, selector: #selector(moveLeft)),
            UIAccessibilityCustomAction(name: "Move right", target: self, selector: #selector(moveRight)),
            UIAccessibilityCustomAction(name: "Move up", target: self, selector: #selector(moveUp)),
            UIAccessibilityCustomAction(name: "Move down", target: self, selector: #selector(moveDown))]
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    func configure(_ watermark: PhotoWatermark?, move: @escaping (CGPoint, Bool) -> Void) {
        self.watermark = watermark; self.move = move
        isHidden = watermark == nil; isUserInteractionEnabled = watermark != nil
        if let watermark {
            currentCenter = watermark.center
            accessibilityValue = "Horizontal \(Int(watermark.center.x * 100)) percent, vertical \(Int(watermark.center.y * 100)) percent"
        }
        setNeedsDisplay()
    }
    override func draw(_ rect: CGRect) {
        guard let watermark, let layout = WatermarkRenderer.layout(for: watermark, imageSize: bounds.size),
              let context = UIGraphicsGetCurrentContext() else { return }
        let box = layout.bounds.insetBy(dx: -5 / zoomScale, dy: -5 / zoomScale)
        context.setShadow(offset: .zero, blur: 2 / zoomScale, color: UIColor.black.withAlphaComponent(0.6).cgColor)
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.75).cgColor)
        context.setLineWidth(1 / max(zoomScale, 0.01))
        context.setLineDash(phase: 0, lengths: [4 / zoomScale, 4 / zoomScale])
        context.stroke(box)
    }
    @objc private func dragged(_ gesture: UIPanGestureRecognizer) {
        guard let watermark, bounds.width > 0, bounds.height > 0 else { return }
        if gesture.state == .began { initialCenter = watermark.center }
        let translation = gesture.translation(in: self)
        currentCenter = CGPoint(x: min(0.95, max(0.05, initialCenter.x + translation.x / bounds.width)),
                                y: min(0.95, max(0.05, initialCenter.y + translation.y / bounds.height)))
        move?(currentCenter, gesture.state == .ended || gesture.state == .cancelled || gesture.state == .failed)
    }
    private func nudge(x: CGFloat, y: CGFloat) -> Bool {
        guard let watermark else { return false }
        move?(CGPoint(x: min(0.95, max(0.05, watermark.center.x + x)), y: min(0.95, max(0.05, watermark.center.y + y))), true)
        return true
    }
    @objc private func moveLeft() -> Bool { nudge(x: -0.05, y: 0) }
    @objc private func moveRight() -> Bool { nudge(x: 0.05, y: 0) }
    @objc private func moveUp() -> Bool { nudge(x: 0, y: -0.05) }
    @objc private func moveDown() -> Bool { nudge(x: 0, y: 0.05) }
}
