import CryptoKit
import PhotosUI
import SwiftUI
import Vision

private enum PrivacyPillar: String, CaseIterable, Identifiable {
    case redact = "Redact", metadata = "Metadata", watermark = "Watermark"
    var id: String { rawValue }
    var symbol: String { switch self { case .redact: "viewfinder"; case .metadata: "info.circle"; case .watermark: "textformat" } }
}
private enum EditScope: Hashable { case privacy(EditorMode), watermark }

private struct EditSnapshot {
    let watermark: PhotoWatermark?
    let watermarkScope: Bool
    let pillar: PrivacyPillar
    let mode: EditorMode?
    let focus: EditorMode?
    let backgroundActive: Bool
    let regions: [BlurRegion]
    let strokes: [BlurStroke]
    let detectionAdjustments: [EditorMode: [Int: CGRect]]
    let wholeDocumentAdjustments: [Int: CGRect]
    let selectedFaces: Set<Int>
    let selectedPlates: Set<Int>
    let selectedDocuments: Set<Int>
    let hidesEntireDocument: Bool
    let settings: [EditorMode: PrivacyEffectSettings]
}

enum EditorMode: String, CaseIterable, Identifiable {
    case background = "Background", faces = "Faces", plate = "Plate", documents = "Documents", manual = "Manual"
    var id: String { rawValue }
    var label: String { self == .plate ? "Plates" : rawValue }
    var symbol: String {
        switch self {
        case .background: "person.crop.rectangle"
        case .faces: "face.smiling"
        case .plate: "rectangle.on.rectangle"
        case .documents: "doc.text.viewfinder"
        case .manual: "scribble.variable"
        }
    }
}

/// Equal tool columns with optically balanced outer label edges. The extra leading
/// inset is measured from native intrinsic content, not a device-specific pixel offset.
private struct PrivacyToolRowLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        CGSize(width: proposal.width ?? subviews.reduce(0) { $0 + $1.sizeThatFits(.unspecified).width }, height: 56)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let first = subviews.first, let last = subviews.last else { return }
        let inset = max(0, (first.sizeThatFits(.unspecified).width - last.sizeThatFits(.unspecified).width) / 2)
        let column = (bounds.width - inset) / CGFloat(subviews.count)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + inset + column * (CGFloat(index) + 0.5), y: bounds.midY),
                anchor: .center, proposal: ProposedViewSize(width: column, height: bounds.height))
        }
    }
}

struct PhotoVeilHome: View {
    @EnvironmentObject private var library: VeilLibrary
    @EnvironmentObject private var exportAccess: VeilExportAccess
    @EnvironmentObject private var subscriptions: VeilSubscriptionStore
    private var premiumState: PremiumPreviewState {
        .resolve(completed: exportAccess.usage, limit: exportAccess.freeLimit, entitlement: subscriptions.previewEntitlement)
    }
    @State private var showingPaywall = false
    @State private var shareLease: UUID?
    @State private var showingGallery = false
    @State private var successMessage: String?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var showingSettings = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var showingPhotoPicker = false
    @State private var importingPhoto = false
    @State private var importTask: Task<Void, Never>?
    @State private var importID = UUID()
    @State private var exportingPhoto = false
    @State private var showingGuide = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sourceMetadata: SourcePhotoMetadata?
    @State private var pillar: PrivacyPillar = .redact
    @State private var watermark: PhotoWatermark?
    @State private var completedWatermark: PhotoWatermark?
    @State private var watermarkGestureEditing = false
    @State private var metadataPolicy: PhotoMetadataPolicy = .keep
    @State private var original: UIImage?
    @State private var previewSource: UIImage?
    @State private var completedRenderLayers: [PrivacyRenderLayer]?
    @State private var previewRenderer = PrivacyPreviewRenderer()
    @State private var preview: UIImage?
    @State private var backgroundMask: CIImage?
    @State private var backgroundSelection = DetectedPrivacySelection()
    @State private var detectionMessage: String?
    @State private var feedbackDismissal: Task<Void, Never>?
    @State private var mode: EditorMode?
    @State private var layerSettings: [EditorMode: PrivacyEffectSettings] = [:]
    private var currentSettings: PrivacyEffectSettings {
        get { layerSettings[mode ?? .manual] ?? PrivacyEffectSettings() }
        nonmutating set { layerSettings[mode ?? .manual] = newValue }
    }
    private var strength: BlurStrength {
        get { currentSettings.strength }
        nonmutating set { currentSettings.strength = newValue }
    }
    private var effect: PrivacyEffect {
        get { currentSettings.effect }
        nonmutating set { currentSettings.effect = newValue }
    }
    private var redactionColor: RedactionColor {
        get { currentSettings.redactionColor }
        nonmutating set { currentSettings.redactionColor = newValue }
    }
    @State private var manualShape: BlurRegion.Shape = .roundedRectangle
    @State private var detectionAdjustments: [EditorMode: [Int: CGRect]] = [:]
    @State private var wholeDocumentAdjustments: [Int: CGRect] = [:]
    @State private var faceRegions: [CGRect] = []
    @State private var faceSelection = DetectedPrivacySelection()
    private var selectedFaces: Set<Int> { get { faceSelection.selected } nonmutating set { faceSelection.selected = newValue } }
    @State private var plateSuggestions: [CGRect] = []
    @State private var plateSelection = DetectedPrivacySelection()
    private var selectedPlates: Set<Int> { get { plateSelection.selected } nonmutating set { plateSelection.selected = newValue } }
    @State private var documentBoundaries: [CGRect] = []
    @State private var documentDetails: [CGRect] = []
    @State private var documentSelection = DetectedPrivacySelection()
    private var selectedDocuments: Set<Int> { get { documentSelection.selected } nonmutating set { documentSelection.selected = newValue } }
    @State private var hidesEntireDocument = false
    private var didAnalyzeDocuments: Bool { documentSelection.hasAnalyzed }
    @State private var manualRegions: [BlurRegion] = []
    @State private var strokes: [BlurStroke] = []
    @State private var brushRenderInFlight = false
    @State private var brushRenderPending = false
    @State private var draftStroke: BlurStroke?
    @State private var paintsStrokes = false
    @State private var showingFinalPreview = false
    @State private var undoStack = ScopedUndoHistory<EditScope, EditSnapshot>()
    @State private var working = false
    @State private var showingOriginal = false
    @State private var manualDraws = true
    @State private var zoomed = false
    @State private var errorMessage: String?
    @State private var shareItem: PhotoShareItem?
    @State private var renderRevision = 0
    private var didAnalyzePlates: Bool { plateSelection.hasAnalyzed }
    private var didAnalyzeFaces: Bool { faceSelection.hasAnalyzed }
    private var didAnalyzeBackground: Bool { backgroundSelection.hasAnalyzed }
    @State private var backgroundAnalysis: Task<Void, Never>?
    @State private var plateAnalysis: Task<Void, Never>?
    @State private var previewRender: Task<Void, Never>?
    @State private var faceAnalysis: Task<Void, Never>?
    @State private var documentAnalysis: Task<Void, Never>?
    @State private var sessionID = UUID()
    @State private var backgroundUnavailable = false
    @State private var testRenderFingerprint = ""
    #if DEBUG
    @State private var analysisCounts: [String: Int] = [:]
    @State private var rapidStressState = "Waiting"
    @State private var testExportFingerprint = ""
    #endif

    #if DEBUG
    private static var allowsSyntheticWatermarkEvidence: Bool {
        ProcessInfo.processInfo.arguments.contains("-veil-synthetic-watermark-evidence")
    }
    #endif

    private var detectingRequestedLayers: Bool {
        // Final output must wait for every requested analysis, even after switching tools.
        backgroundAnalysis != nil || faceAnalysis != nil || plateAnalysis != nil || documentAnalysis != nil
    }

    var body: some View {
        NavigationStack {
            Group {
                if original == nil { importView } else { editorView }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { navigationControls }
        }
        .background(Color(uiColor: .systemBackground))
        .onChange(of: pickerItem) { _, item in
            importTask?.cancel()
            let generation = UUID(); importID = generation
            importTask = Task { await load(item, generation: generation) }
        }
        .sensoryFeedback(.selection, trigger: mode)
        .sensoryFeedback(.selection, trigger: currentSettings)
        .sensoryFeedback(.success, trigger: successMessage)
        .sensoryFeedback(.error, trigger: errorMessage)
        .onAppear(perform: loadFixtureIfRequested)
        .alert("Couldn’t finish that action", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: { Text(errorMessage ?? "Please choose another image.") }
        .sheet(isPresented: $showingPaywall) { NavigationStack { VeilSubscriptionView() } }
        .sheet(isPresented: $showingSettings) { VeilSettings() }
        .sheet(isPresented: $showingGallery) { VeilGallery() }
        .overlay(alignment: .bottom) {
            if let successMessage {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Saved").font(.headline)
                        Text(successMessage).font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    Button("Dismiss", systemImage: "xmark") { self.successMessage = nil }
                        .labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44)
                        .accessibilityIdentifier("dismissSaveNotice")
                }
                .padding(16).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
                .overlay { RoundedRectangle(cornerRadius: 24).strokeBorder(.primary.opacity(0.08)) }
                .padding(16).accessibilityElement(children: .contain)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.36, dampingFraction: 0.88), value: successMessage)
        .sheet(isPresented: $showingGuide) { quickGuide }
        .sheet(item: $shareItem) { item in
            ShareSheet(items: [item.url]) { completed in
                if let lease = shareLease {
                    if let warning = exportAccess.finish(lease, succeeded: completed) { errorMessage = warning }
                    shareLease = nil
                }
            }.onDisappear {
                try? FileManager.default.removeItem(at: item.url)
            }
        }
    }

    private var importView: some View {
        ScrollView {
            VStack(spacing: 20) {
                VeilDemonstration().frame(maxWidth: .infinity)
                VStack(spacing: 10) {
                    VStack(spacing: 2) {
                        Text("Your photo.").foregroundStyle(.primary)
                        Text("Your boundaries.").foregroundStyle(Color(uiColor: .systemBlue))
                    }
                    .font(.largeTitle.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .fixedSize(horizontal: false, vertical: true)
                    Capsule()
                        .fill(LinearGradient(colors: [.cyan, .blue, .indigo], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 64, height: 3)
                        .opacity(0.7)
                        .accessibilityHidden(true)
                    Text("Redact. Control metadata. Add your watermark.")
                        .font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }
                Button { showingPhotoPicker = true } label: {
                    Group {
                        if importingPhoto {
                            HStack(spacing: 10) {
                                ProgressView().tint(.white)
                                Text("Preparing photo…")
                            }
                        } else {
                            Label("Choose a photo", systemImage: "photo")
                        }
                    }
                    .font(.headline).padding(.horizontal, 32).frame(minHeight: 52)
                }
                .modifier(VeilActionStyle(prominent: true))
                .disabled(importingPhoto)
                .accessibilityIdentifier("choosePhoto")
                .photosPicker(isPresented: $showingPhotoPicker, selection: $pickerItem, matching: .images)
                if subscriptions.previewEntitlement != .pro, let used = exportAccess.usage {
                    Text(used >= exportAccess.freeLimit ? "Free export used" :
                         exportAccess.freeLimit == 1 && used == 0 ? "Your first export is free" :
                         "\(exportAccess.freeLimit - used) free export\(exportAccess.freeLimit - used == 1 ? "" : "s") remaining")
                        .font(.caption).foregroundStyle(.secondary)
                        .accessibilityIdentifier("freeExportAllowance")
                }
                Button("See how Veil works", systemImage: "sparkles") { showingGuide = true }
                    .font(.subheadline.weight(.medium)).frame(minHeight: 44)
                    .accessibilityIdentifier("quickGuide")
                HomeSponsorshipBanner(homeVisible: !showingPhotoPicker && !showingGallery && !showingSettings &&
                    !showingGuide && !showingPaywall && !importingPhoto && !exportingPhoto && original == nil)
            }
            .frame(maxWidth: .infinity).padding(.bottom, 32)
            .padding(.top, 4)
        }
    }

    private var quickGuide: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Text("Three tools.\nYour boundaries.")
                        .font(.largeTitle.weight(.semibold)).fixedSize(horizontal: false, vertical: true)
                    Text("Prepare a copy you feel ready to share.")
                        .font(.title3).foregroundStyle(.secondary)
                    ForEach(Array([
                        ("viewfinder", "Cover the details", "Blur, pixelate or redact faces, plates, documents and any area you draw. Use solid Redact for sensitive text."),
                        ("info.circle", "Choose what travels", "Keep supported photo details or leave out source metadata, including location. The original stays unchanged."),
                        ("textformat", "Give it a purpose", "Add a custom watermark or a suggestion. Drag it into place, choose a style, or repeat it across your photo."),
                        ("square.and.arrow.up", "Review, then share", "Check visible details, watermark and metadata choice. Save or share a finished copy. Detection and watermarks cannot guarantee privacy or prevent misuse.")
                    ].enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 18) {
                            Image(systemName: step.0).font(.title2).foregroundStyle(.blue)
                                .frame(width: 36, height: 36).accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 8) {
                                Text(step.1).font(.headline)
                                Text(step.2).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    Label("Editing happens on your iPhone. No account needed.", systemImage: "lock.shield")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Button("Start with a photo") { showingGuide = false }
                        .frame(maxWidth: .infinity, minHeight: 50).modifier(VeilActionStyle(prominent: true))
                }.padding(28)
            }
            .navigationTitle("Welcome to Veil").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showingGuide = false } } }
        }
    }

    @ToolbarContentBuilder private var navigationControls: some ToolbarContent {
        if original == nil {
            ToolbarItem(placement: .topBarLeading) {
                Button("Private Gallery", systemImage: "photo.stack") { showingGallery = true }
                    .labelStyle(.iconOnly).accessibilityIdentifier("gallery")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Settings", systemImage: "gearshape") { showingSettings = true }
                    .labelStyle(.iconOnly).accessibilityIdentifier("settings")
            }
        } else {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close photo", systemImage: "xmark") { clearSession() }.labelStyle(.iconOnly)
            }
            if !showingFinalPreview {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Undo", systemImage: "arrow.uturn.backward") { undo() }
                        .labelStyle(.iconOnly).disabled(!canUndo)
                    Menu("More editing actions", systemImage: "ellipsis") {
                        Button("Reset edits", systemImage: "arrow.counterclockwise", role: .destructive) { resetEdits() }
                    }.labelStyle(.iconOnly)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(showingFinalPreview ? "Edit" : "Done") {
                    showingOriginal = false
                    successMessage = nil
                    dismissDetectionFeedback()
                    showingFinalPreview.toggle()
                }.id(showingFinalPreview).disabled(working || detectingRequestedLayers).accessibilityIdentifier("finalPreview")
            }

        }
    }

    private var editorView: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                if let original, let previewSource, let preview {
                    ZoomablePhotoCanvas(
                        original: original,
                        preview: showingOriginal ? previewSource : preview,
                        mode: showingOriginal || showingFinalPreview || pillar != .redact ? nil : mode,
                        faces: adjustedFaceRegions,
                        selectedFaces: selectedFaces,
                        plates: mode == .documents ? currentDocumentRegions : adjustedPlateRegions,
                        selectedPlates: mode == .documents ? selectedDocuments : selectedPlates,
                        regions: manualRegions,
                        newRegionShape: manualShape,
                        drawsRegions: manualDraws,
                        paintsStrokes: paintsStrokes,
                        strokes: strokes,
                        onStroke: updateStroke,
                        onFaces: toggleFace,
                        onPlate: { mode == .documents ? toggleDocument($0) : togglePlate($0) },
                        onRegions: replaceManualRegions,
                        onZoomChanged: { zoomed = $0 },
                        watermark: !showingOriginal && !showingFinalPreview && pillar == .watermark ? watermark : nil,
                        onWatermarkMove: moveWatermark,
                        onDetectionRect: adjustDetection,
                        detectionContext: "\(sessionID)-\(hidesEntireDocument)",
                        premiumPreview: !showingOriginal && premiumState.marked,
                        protectsPreview: !showingOriginal && premiumState.protectsPhoto
                    )
                    .accessibilityIdentifier("photoCanvas")
                }

                if !showingFinalPreview {
                    GeometryReader { geometry in
                    HStack(spacing: 8) {
                        Button { showingOriginal.toggle() } label: {
                            if usesExpandedControls {
                                Image(systemName: showingOriginal ? "slider.horizontal.3" : "eye")
                                    .font(.system(size: 17, weight: .semibold)).frame(width: 44, height: 44)
                                    .modifier(VeilGlassSurface())
                            } else {
                                Label(showingOriginal ? "Edited" : "Original", systemImage: showingOriginal ? "slider.horizontal.3" : "eye")
                                    .font(.caption.weight(.semibold)).padding(.horizontal, 12).frame(minHeight: 44)
                                    .modifier(VeilGlassSurface())
                            }
                        }
                        .accessibilityLabel(showingOriginal ? "Show edited photo" : "Show original photo")
                        .accessibilityIdentifier("originalToggle")
                        if zoomed {
                            Button { NotificationCenter.default.post(name: .photoVeilFitPhoto, object: nil) } label: {
                                Image(systemName: "arrow.up.left.and.arrow.down.right").font(.caption.weight(.semibold))
                                    .frame(width: 44, height: 44).modifier(VeilGlassSurface())
                            }
                            .accessibilityLabel("Fit photo")
                            .accessibilityIdentifier("fitPhoto")
                        }
                }
                    .padding(.top, 16)
                    .padding(.leading, comparisonInset(in: geometry.size))
                    }
                }
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("-veil-ui-testing") {
                    Color.clear.frame(width: 1, height: 1).accessibilityElement()
                        .accessibilityIdentifier("analysisCounts")
                        .accessibilityValue(["background", "faces", "plates", "documents"].map { "\($0)=\(analysisCounts[$0, default: 0])" }.joined(separator: ","))
                    Color.clear.frame(width: 1, height: 1).accessibilityElement()
                        .accessibilityIdentifier("privacySelectionCounts")
                        .accessibilityValue("background=\(backgroundSelection.selected.count),faces=\(selectedFaces.count),plates=\(selectedPlates.count),documents=\(selectedDocuments.count),rectangles=\(manualRegions.count),strokes=\(strokes.count)")
                    Color.clear.frame(width: 1, height: 1).accessibilityElement()
                        .accessibilityIdentifier("exportFingerprint").accessibilityValue(testExportFingerprint)
                    Color.clear.frame(width: 1, height: 1).accessibilityElement()
                        .accessibilityIdentifier("rapidSelectionStress").accessibilityValue(rapidStressState)
                }
                #endif
                if (working || detectingRequestedLayers) && draftStroke == nil {
                    VStack(spacing: 10) {
                        ProgressView().controlSize(.regular)
                        Text(exportingPhoto ? "Preparing full-quality photo…" : detectingRequestedLayers ? "Finding details…" : "Updating preview…")
                            .font(.caption.weight(.medium)).multilineTextAlignment(.center)
                    }.padding(16).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                        .frame(maxWidth: .infinity, maxHeight: .infinity).accessibilityLabel(detectingRequestedLayers ? "Detecting" : "Processing")
                        .accessibilityIdentifier(detectingRequestedLayers ? "detectionInProgress" : "renderInProgress").allowsHitTesting(false)
                } else {
                    Color.clear.frame(width: 1, height: 1)
                        .accessibilityElement()
                        .accessibilityLabel(backgroundUnavailable ? "Manual fallback" : mode == .background ? "Background ready" : "Processing complete")
                        .accessibilityIdentifier("processingComplete")
                        .accessibilityValue(testRenderFingerprint)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .secondarySystemBackground))
            .overlay(alignment: .bottom) {
                if let detectionMessage, !showingFinalPreview {
                    Text(detectionMessage).font(.callout).multilineTextAlignment(.center)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(.regularMaterial, in: Capsule()).padding(12)
                        .accessibilityIdentifier("detectionFeedback")
                        .allowsHitTesting(false)
                } else if showingOriginal {
                    Label("Original · not shared", systemImage: "eye")
                        .font(.caption.weight(.semibold)).padding(12)
                        .background(.regularMaterial, in: Capsule()).padding(12).allowsHitTesting(false)
                }
            }
            PremiumPreviewNotice(state: premiumState) { showingPaywall = true }
            // Retain the control surface's size so Done never changes the photo transform.
            if showingFinalPreview {
                ZStack {
                    editorControls.hidden().accessibilityHidden(true)
                }.overlay { panelContent { finalReview } }
            }
            else { editorControls }
        }
    }

    // Use the retained panel footprint, centering short states while allowing larger text to scroll.
    private func panelContent<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        GeometryReader { geometry in
            ScrollView {
                content().frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }.accessibilityElement(children: .contain)
        }
    }

    private func comparisonInset(in size: CGSize) -> CGFloat {
        guard let image = previewSource, image.size.height > 0 else { return 20 }
        let fittedWidth = min(size.width, size.height * image.size.width / image.size.height)
        return max(20, (size.width - fittedWidth) / 2)
    }

    private var metadataControl: some View {
        VStack(spacing: 6) {
            metadataOption(.keep, title: "Keep metadata", detail: "Includes location, when available.", symbol: "location")
            metadataOption(.remove, title: "Remove metadata", detail: "Omit location and source details.", symbol: "location.slash")
        }.padding(.horizontal, 24).padding(.vertical, 12)
    }

    private func metadataOption(_ policy: PhotoMetadataPolicy, title: String, detail: String, symbol: String) -> some View {
        Button {
            metadataPolicy = policy
            UISelectionFeedbackGenerator().selectionChanged()
        } label: {
            HStack(spacing: dynamicTypeSize.isAccessibilitySize ? 12 : 16) {
                if !dynamicTypeSize.isAccessibilitySize {
                    Image(systemName: symbol).font(.system(size: 26, weight: .medium))
                        .foregroundStyle(metadataPolicy == policy ? Color.blue : Color.secondary)
                        .frame(width: 36)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.body.weight(.semibold)).foregroundStyle(.primary)
                    if !dynamicTypeSize.isAccessibilitySize {
                        Text(detail).font(.caption).foregroundStyle(.secondary)
                    }
                }.fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                Image(systemName: metadataPolicy == policy ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(metadataPolicy == policy ? Color.blue : Color.secondary.opacity(0.5))
            }.frame(maxWidth: .infinity, minHeight: 64, alignment: .leading).contentShape(Rectangle())
        }.buttonStyle(.plain)
            .accessibilityLabel(title).accessibilityValue(detail)
            .accessibilityAddTraits(metadataPolicy == policy ? .isSelected : [])
            .accessibilityIdentifier(policy == .keep ? "metadataKeep" : "metadataRemove")
    }

    private var metadataSummary: String {
        if metadataPolicy == .remove { return "Source metadata removed" }
        return sourceMetadata?.hasSupportedFields == true ? "Supported metadata kept" : "No source metadata available"
    }

    private var finalReview: some View {
        VStack(spacing: 14) {
            if !dynamicTypeSize.isAccessibilitySize {
                Text("Ready to share").font(.title2.weight(.semibold))
            }
            Button {
                pillar = .metadata; showingFinalPreview = false
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: metadataPolicy == .remove ? "location.slash" : "info.circle")
                    Text(dynamicTypeSize.isAccessibilitySize
                         ? (metadataPolicy == .remove ? "Remove metadata" : "Keep metadata") : metadataSummary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("metadataChoiceExplanation")
                    Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                }.font(.subheadline).frame(minHeight: 44)
            }.buttonStyle(.plain).foregroundStyle(.secondary)
                .accessibilityLabel("\(metadataSummary). Change metadata choice")
                .accessibilityValue(metadataPolicy == .remove ? "Remove metadata" : "Keep metadata")
                .accessibilityIdentifier("metadataReviewChange").disabled(exportingPhoto)
            if watermark != nil {
                Label("Watermark added", systemImage: "checkmark")
                    .font(.caption).foregroundStyle(.secondary)
            }
            let actionLayout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(spacing: 12)) : AnyLayout(HStackLayout(spacing: 12))
            actionLayout {
                Menu {
                    Button("Save to Veil", systemImage: "photo.stack") { prepareExport(destination: .gallery) }
                        .accessibilityIdentifier("saveToVeil")
                    Button("Save to Photos", systemImage: "photo") { prepareExport(destination: .photos) }
                        .accessibilityIdentifier("saveToPhotos")
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down").frame(maxWidth: .infinity, minHeight: 44)
                }.modifier(VeilActionStyle()).accessibilityIdentifier("saveMenu")
                Button { prepareExport() } label: {
                    Label("Share", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity, minHeight: 44)
                }.modifier(VeilActionStyle(prominent: true)).accessibilityIdentifier("export")
            }.font(.body.weight(.semibold)).disabled(working || detectingRequestedLayers || exportingPhoto)
            Text("Originals stay unchanged.").font(.caption2).foregroundStyle(.secondary)
        }.padding(.horizontal, 28).padding(.vertical, 16)
    }

    private var usesExpandedControls: Bool { dynamicTypeSize > .large }

    // Keep the same three layout slots for every tool/effect. Only their contents change.
    private var redactionControls: some View {
        VStack(spacing: 8) {
            VStack(spacing: 4) {
                if usesExpandedControls {
                    VStack(alignment: .leading, spacing: 4) { effectControl; effectParameterMenu }
                } else {
                    HStack(spacing: 8) {
                        effectControl.frame(width: 116)
                        Divider().frame(height: 22)
                        effectParameterControl.frame(maxWidth: .infinity)
                    }.frame(height: 44)
                }
                contextualControls.frame(height: 44)
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .modifier(VeilGlassSurface(panel: true))
            .opacity(mode == nil ? 0 : 1).disabled(mode == nil).accessibilityHidden(mode == nil)

            if usesExpandedControls {
                Menu {
                    ForEach(EditorMode.allCases) { item in
                        Button { select(item) } label: {
                            Label(item.label, systemImage: mode == item ? "checkmark" : item.symbol)
                        }.accessibilityIdentifier("mode_\(item.rawValue.lowercased())")
                    }
                } label: {
                    Text(mode?.label ?? "Choose tool").font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .modifier(VeilActionStyle())
                .accessibilityLabel("Editing tool").accessibilityValue(mode?.label ?? "None selected")
                .accessibilityIdentifier("toolMenu")
            } else {
                PrivacyToolRowLayout {
                    ForEach(EditorMode.allCases) { item in
                        Button { select(item) } label: {
                            VStack(spacing: 3) {
                                Image(systemName: item.symbol)
                                    .symbolEffect(.bounce, options: .nonRepeating, value: !reduceMotion && mode == item)
                                    .font(.system(size: 19, weight: .medium)).frame(width: 26, height: 24)
                                Text(item.label).font(.caption2.weight(.medium)).lineLimit(1)
                                    .frame(maxWidth: .infinity).frame(height: 16)
                            }
                            .foregroundStyle(mode == item ? Color.primary : Color.secondary)
                            .frame(maxWidth: .infinity).frame(height: 56)
                            .background {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(mode == item ? Color.blue.opacity(0.14) : .clear)
                                    .overlay { RoundedRectangle(cornerRadius: 20).strokeBorder(mode == item ? Color.blue.opacity(0.2) : .clear) }
                                    .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: mode)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(VeilModePressStyle())
                        .accessibilityAddTraits(mode == item ? .isSelected : [])
                        .accessibilityIdentifier("mode_\(item.rawValue.lowercased())")
                    }
                }
                .padding(4).modifier(VeilGlassSurface())
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
    }

    private var editorControls: some View {
        VStack(spacing: 0) {
            ZStack {
                redactionControls
                    .opacity(pillar == .redact ? 1 : 0)
                    .disabled(pillar != .redact).accessibilityHidden(pillar != .redact)
            }.overlay {
                    if pillar == .watermark {
                        panelContent { WatermarkControls(watermark: watermark, change: changeWatermark) }
                    } else if pillar == .metadata {
                        panelContent { metadataControl }
                    }
            }
            HStack(spacing: 0) {
                ForEach(PrivacyPillar.allCases) { item in
                    Button {
                        watermarkGestureEditing = false
                        showingOriginal = false; dismissDetectionFeedback()
                        pillar = item
                        UISelectionFeedbackGenerator().selectionChanged()
                    } label: {
                        VStack(spacing: 4) {
                            if usesExpandedControls {
                                Image(systemName: item.symbol).font(.system(size: 20, weight: .medium))
                            } else {
                                Label(item.rawValue, systemImage: item.symbol)
                                    .font(.caption.weight(.semibold)).lineLimit(1)
                            }
                            Capsule().fill(pillar == item ? Color.blue : .clear).frame(width: 24, height: 2)
                                .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: pillar)
                        }.frame(maxWidth: .infinity, minHeight: 44).contentShape(Rectangle())
                    }.buttonStyle(.plain).foregroundStyle(pillar == item ? Color.blue : Color.secondary)
                        .accessibilityAddTraits(pillar == item ? .isSelected : [])
                        .accessibilityLabel(item == .redact ? "Redaction tools" : item.rawValue)
                        .accessibilityIdentifier("pillar_\(item.rawValue.lowercased())")
                }
            }.padding(.horizontal, 12).padding(.bottom, 4)
        }
    }

    private var undoScope: EditScope? { pillar == .watermark ? .watermark : mode.map(EditScope.privacy) }

    private func changeWatermark(_ next: PhotoWatermark?, _ finished: Bool) {
        guard watermark != next else { if finished { watermarkGestureEditing = false }; return }
        if !watermarkGestureEditing { pushUndo(watermarkEdit: true) }
        watermarkGestureEditing = !finished
        watermark = next; showingOriginal = false
        if finished { UISelectionFeedbackGenerator().selectionChanged() }
        rerender()
    }

    private func moveWatermark(_ center: CGPoint, _ finished: Bool) {
        guard var next = watermark else { return }
        next.center = CGPoint(x: min(0.95, max(0.05, center.x)), y: min(0.95, max(0.05, center.y)))
        changeWatermark(next, finished)
    }

    private var effectControl: some View {
        Menu {
            ForEach(PrivacyEffect.allCases) { option in
                Button { setEffect(option) } label: {
                    if effect == option { Label(option.rawValue, systemImage: "checkmark") }
                    else { Text(option.rawValue) }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(effect.rawValue).font(.subheadline.weight(.semibold)).lineLimit(1)
                Image(systemName: "chevron.down").font(.system(size: 10, weight: .semibold))
            }.frame(maxWidth: .infinity, minHeight: 44)
        }.buttonStyle(.plain).accessibilityIdentifier("effectMenu")
    }

    @ViewBuilder private var effectParameterControl: some View {
        if effect == .redact { effectParameterMenu }
        else {
            HStack(spacing: 0) {
                ForEach(BlurStrength.allCases) { option in
                    Button { setStrength(option) } label: {
                        Text(option.rawValue).font(.caption.weight(strength == option ? .semibold : .regular))
                            .lineLimit(1).frame(maxWidth: .infinity, minHeight: 44)
                            .background(strength == option ? Color(uiColor: .tertiarySystemFill) : .clear, in: Capsule())
                    }.buttonStyle(.plain).foregroundStyle(strength == option ? Color.primary : Color.secondary)
                        .accessibilityAddTraits(strength == option ? .isSelected : [])
                        .accessibilityIdentifier("strength_\(option.rawValue.lowercased())")
                }
            }
        }
    }

    private var effectParameterMenu: some View {
        Menu {
            if effect == .redact {
                ForEach(RedactionColor.allCases) { color in
                    Button { setRedactionColor(color) } label: {
                        if redactionColor == color { Label(color.rawValue, systemImage: "checkmark") }
                        else { Text(color.rawValue) }
                    }
                }
            } else {
                ForEach(BlurStrength.allCases) { option in
                    Button { setStrength(option) } label: {
                        if strength == option { Label(option.rawValue, systemImage: "checkmark") }
                        else { Text(option.rawValue) }
                    }.accessibilityIdentifier("strength_\(option.rawValue.lowercased())")
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: effect == .redact ? "circle.lefthalf.filled" : "slider.horizontal.3")
                    .font(.system(size: 17))
                Text(effect == .redact ? redactionColor.rawValue : strength.rawValue).font(.subheadline).lineLimit(1)
                Image(systemName: "chevron.down").font(.system(size: 10, weight: .semibold))
            }.frame(maxWidth: .infinity, minHeight: 44)
        }.buttonStyle(.plain)
        .accessibilityLabel(effect == .redact ? "Redaction color" : effect == .pixelate ? "Pixel size" : "Blur strength")
        .accessibilityValue(effect == .redact ? redactionColor.rawValue : strength.rawValue)
        .accessibilityIdentifier("effectParameterMenu")
    }

    private var contextualControls: some View {
        HStack(spacing: 8) {
            Spacer(minLength: 0)
            if mode == .faces || mode == .plate {
                if (mode == .faces && !faceRegions.isEmpty) || (mode == .plate && !plateSuggestions.isEmpty) {
                    Button { toggleAllDetections() } label: {
                        Label(hasSelectedDetections ? "Clear All" : "Hide all", systemImage: "checkmark.rectangle.stack")
                            .font(.subheadline).lineLimit(1).frame(minHeight: 44)
                    }.buttonStyle(.plain)
                    .accessibilityIdentifier(mode == .faces ? "blurAllFaces" : "blurAllPlates")
                    .accessibilityLabel("\(hasSelectedDetections ? "Clear All" : "Hide all") \(mode == .faces ? "faces" : "plates")")
                } else {
                    Button { select(.manual) } label: { Label("Manual", systemImage: "scribble.variable").font(.subheadline).frame(minHeight: 44) }
                        .buttonStyle(.plain).accessibilityLabel("Select manually")
                }
            } else if mode == .documents {
                Menu {
                    Button("Hide all details") { setDocumentCoverage(entire: false) }
                    Button("Hide entire document") { setDocumentCoverage(entire: true) }
                    Button("Clear All") { clearAll() }.accessibilityIdentifier("clearAll")
                } label: {
                    Label("Coverage", systemImage: "doc.text").font(.subheadline).frame(minHeight: 44)
                }.buttonStyle(.plain).accessibilityIdentifier("documentCoverage")
                .accessibilityValue(didAnalyzeDocuments && documentBoundaries.isEmpty ? "No document found" : hidesEntireDocument ? "Entire document" : "Details")
            } else if mode == .background {
                Button("Clear All", systemImage: "checkmark.rectangle.stack") { clearAll() }
                    .font(.subheadline).frame(minHeight: 44).buttonStyle(.plain).accessibilityIdentifier("clearAll")
            } else if mode == .manual {
                Menu {
                    Button("Rectangle") { paintsStrokes = false; manualShape = .roundedRectangle }
                    Button("Ellipse") { paintsStrokes = false; manualShape = .oval }
                    Button("Brush") { paintsStrokes = true }
                    Divider()
                    Button("Clear All") { clearAll() }.accessibilityIdentifier("clearAll")
                } label: {
                    Image(systemName: paintsStrokes ? "paintbrush.pointed" : manualShape == .oval ? "oval" : "rectangle.dashed")
                        .font(.system(size: 18)).frame(width: 44, height: 44)
                }.buttonStyle(.plain).accessibilityLabel("Selection shape")
                .accessibilityValue(paintsStrokes ? "Brush" : manualShape == .oval ? "Ellipse" : "Rectangle")
                .accessibilityIdentifier("shapeMenu")
                Button { paintsStrokes.toggle(); manualDraws = true } label: {
                    Image(systemName: paintsStrokes ? (manualShape == .oval ? "oval" : "rectangle.dashed") : "paintbrush.pointed")
                        .font(.system(size: 18)).frame(width: 44, height: 44)
                }.buttonStyle(.plain)
                .accessibilityLabel(paintsStrokes ? (manualShape == .oval ? "Ellipse selection" : "Rectangle selection") : "Paint blur")
                .accessibilityIdentifier("manualBrush")
                Button { manualDraws.toggle() } label: {
                    Image(systemName: manualDraws ? "hand.raised" : "pencil.tip.crop.circle")
                        .font(.system(size: 18)).frame(width: 44, height: 44)
                }.buttonStyle(.plain).accessibilityLabel(manualDraws ? "Move photo" : "Draw blur region")
                .accessibilityIdentifier("canvasGestureMode")
            }
            Spacer(minLength: 0)
        }
    }

    private func setEffect(_ option: PrivacyEffect) {
        guard effect != option else { return }
        pushUndo(); effect = option; rerender()
    }
    private func setRedactionColor(_ option: RedactionColor) {
        guard redactionColor != option else { return }
        pushUndo(); redactionColor = option; rerender()
    }
    private func setStrength(_ option: BlurStrength) {
        guard strength != option else { return }
        pushUndo(); strength = option; rerender()
    }

    @MainActor private func load(_ item: PhotosPickerItem?, generation: UUID) async {
        guard let item else { importingPhoto = false; return }
        importingPhoto = true
        working = true
        defer { if importID == generation { working = false; importingPhoto = false } }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let pair = try await Task.detached(priority: .userInitiated, operation: { () throws -> (UIImage, UIImage, SourcePhotoMetadata)? in
                      guard let image = UIImage(data: data), let normalized = BlurRenderer.normalizedImage(image),
                            let downsampled = BlurRenderer.previewImage(normalized) else { return nil }
                      return (normalized, downsampled, try SourcePhotoMetadata.capture(data))
                  }).value else { throw BlurError.unavailable }
            guard !Task.isCancelled, importID == generation else { return }
            beginSession(original: pair.0, preview: pair.1, metadata: pair.2)
        } catch {
            guard !Task.isCancelled, importID == generation else { return }
            errorMessage = "The photo couldn’t be loaded. Please try another one."
        }
    }

    @MainActor private func beginSession(original: UIImage, preview: UIImage, metadata: SourcePhotoMetadata) {
        faceAnalysis?.cancel(); faceAnalysis = nil; documentAnalysis?.cancel(); documentAnalysis = nil
        backgroundAnalysis?.cancel(); backgroundAnalysis = nil; plateAnalysis?.cancel(); plateAnalysis = nil
        previewRender?.cancel(); previewRender = nil; brushRenderInFlight = false; brushRenderPending = false
        sessionID = UUID(); renderRevision += 1; backgroundUnavailable = false
        self.original = original
        self.sourceMetadata = metadata
        self.metadataPolicy = .keep
        self.previewSource = preview
        self.preview = preview
        self.mode = nil
        self.pillar = .redact; self.watermark = nil; self.completedWatermark = nil; self.watermarkGestureEditing = false
        self.backgroundMask = nil
        self.faceRegions = []; detectionAdjustments = [:]; wholeDocumentAdjustments = [:]
        self.selectedFaces = []
        self.plateSuggestions = []
        self.selectedPlates = []
        self.manualRegions = []
        self.strokes = []; self.draftStroke = nil; self.paintsStrokes = false; self.showingFinalPreview = false
        self.undoStack = .init()

        #if DEBUG
        analysisCounts = [:]
        #endif
        backgroundSelection = .init(); faceSelection = .init(); plateSelection = .init(); documentSelection = .init()
        dismissDetectionFeedback()
        self.documentBoundaries = []; self.documentDetails = []; self.selectedDocuments = []; self.hidesEntireDocument = false
        self.completedRenderLayers = nil; self.layerSettings = [:]; self.manualShape = .roundedRectangle
        self.showingOriginal = false
        self.manualDraws = true
    }

    @MainActor private func loadFixtureIfRequested() {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        guard !arguments.contains("-veil-empty") else { return }
        func argument(_ key: String) -> String? {
            guard let index = arguments.firstIndex(of: key), arguments.indices.contains(index + 1) else { return nil }
            return arguments[index + 1]
        }
        let requestedMode = argument("-veil-mode")
        let fixtureName = argument("-veil-fixture") ?? (requestedMode == "background" ? "background-person" : requestedMode == "faces" ? "two-faces" : "two-people-car")
        func fixtureData(_ name: String) -> Data? {
            func image(_ resource: String) -> UIImage? {
                Bundle.main.url(forResource: resource, withExtension: "jpg").flatMap { UIImage(contentsOfFile: $0.path) }
            }
            guard name == "combined-privacy" else {
                return Bundle.main.url(forResource: name, withExtension: "jpg").flatMap { try? Data(contentsOf: $0) }
            }
            guard let photo = image("two-people-car"), let card = image("sample-card") else { return nil }
            let format = UIGraphicsImageRendererFormat(); format.scale = 1
            return UIGraphicsImageRenderer(size: CGSize(width: 1800, height: 2250), format: format).image { _ in
                photo.draw(in: CGRect(x: 0, y: 0, width: 1800, height: 2250))
                card.draw(in: CGRect(x: 900, y: 1650, width: 900, height: 600))
            }.jpegData(compressionQuality: 0.98)
        }
        guard arguments.contains("-veil-ui-testing"), original == nil,
              let fixtureData = fixtureName == "empty-scene"
                ? UIGraphicsImageRenderer(size: CGSize(width: 1000, height: 1200)).image { context in
                    UIColor.gray.setFill(); context.fill(CGRect(x: 0, y: 0, width: 1000, height: 1200))
                  }.jpegData(compressionQuality: 1)
                : fixtureData(fixtureName),
              let fixture = UIImage(data: fixtureData),
              let normalizedFull = BlurRenderer.normalizedImage(fixture),
              let normalized = arguments.contains("-veil-analysis-fixture") ? BlurRenderer.previewImage(normalizedFull, maxDimension: 600) : normalizedFull,
              let downsampled = BlurRenderer.previewImage(normalized),
              let metadata = try? SourcePhotoMetadata.capture(fixtureData) else { return }
        beginSession(original: normalized, preview: downsampled, metadata: metadata)
        if arguments.contains("-veil-cached-mask-fixture") {
            // Controlled cached mask tests activation/clear/export, not Vision segmentation.
            let extent = CGRect(origin: .zero, size: downsampled.size)
            let foreground = CIImage(color: CIColor.white).cropped(to: CGRect(x: 0, y: 0, width: extent.width / 2, height: extent.height))
            backgroundMask = foreground.composited(over: CIImage(color: CIColor.black).cropped(to: extent))
            backgroundSelection.complete(count: 1)
        }
        if let index = arguments.firstIndex(of: "-veil-mode"), arguments.indices.contains(index + 1),
           let requested = EditorMode.allCases.first(where: { $0.rawValue.lowercased() == arguments[index + 1] }) {
            select(requested)
        }
        if arguments.contains("-veil-rapid-selection-stress") {
            // Exercise effect changes on an actual Manual layer, not an empty tool.
            manualRegions = [BlurRegion(rect: CGRect(x: 0.3, y: 0.3, width: 0.2, height: 0.15), shape: .roundedRectangle)]
            let stressSession = sessionID
            Task { await runRapidSelectionStress(session: stressSession) }
        }
        #endif
    }

    #if DEBUG
    /// Rendered UI state stress complements native menu/press tests, whose taps wait for idle.
    /// Uses the same actions at 40 ms intervals; no fake detection or account state.
    @MainActor private func runRapidSelectionStress(session: UUID) async {
        try? await Task.sleep(for: .seconds(5))
        // High-volume cancellation/history invariants are covered by core tests.
        // Two rendered cycles retain rapid asynchronous detection/tool/effect overlap.
        for _ in 0..<2 {
            guard !Task.isCancelled, sessionID == session else { return }
            for tool in EditorMode.allCases {
                select(tool); try? await Task.sleep(for: .milliseconds(40))
            }
            for style in PrivacyEffect.allCases {
                setEffect(style); try? await Task.sleep(for: .milliseconds(40))
                if style == .redact {
                    for color in RedactionColor.allCases { setRedactionColor(color); try? await Task.sleep(for: .milliseconds(40)) }
                } else {
                    for intensity in [BlurStrength.low, .strong] { setStrength(intensity); try? await Task.sleep(for: .milliseconds(40)) }
                }
            }
        }
        guard sessionID == session else { return }
        select(.manual); setEffect(.blur); setStrength(.medium)
        rapidStressState = "Complete"
    }
    #endif

    private func select(_ newMode: EditorMode) {
        guard mode != newMode else {
            if newMode == .manual || newMode == .plate { manualDraws = true }
            return
        }
        UISelectionFeedbackGenerator().selectionChanged()
        let activationChanges: Bool
        switch newMode {
        case .background: activationChanges = backgroundSelection.needsActivationUndo
        case .faces: activationChanges = faceSelection.needsActivationUndo
        case .plate: activationChanges = plateSelection.needsActivationUndo
        case .documents: activationChanges = documentSelection.needsActivationUndo
        case .manual: activationChanges = false
        }
        if activationChanges { pushUndo(for: newMode) }
        renderRevision += 1
        mode = newMode
        backgroundUnavailable = false
        dismissDetectionFeedback()
        showingOriginal = false
        if newMode == .manual || newMode == .plate { manualDraws = true }
        switch newMode {
        case .background:
            backgroundSelection.activate()
            if backgroundMask != nil { rerender() }
            else if didAnalyzeBackground { backgroundUnavailable = true; mode = .manual; manualDraws = true; rerender(); showDetectionFeedback("Background unavailable. Try Manual.") }
            else { runBackground() }
        case .faces:
            faceSelection.activate()
            if !didAnalyzeFaces { runFaces() } else { rerender(); showDetectionFeedback(faceSelection.feedback(for: "faces")) }
        case .plate:
            plateSelection.activate()
            if !didAnalyzePlates { runPlate() } else { rerender(); showDetectionFeedback(plateSelection.feedback(for: "plates")) }
        case .documents:
            documentSelection.activate()
            if !didAnalyzeDocuments { runDocuments() } else { rerender(); showDetectionFeedback(documentSelection.feedback(for: "documents")) }
        case .manual: rerender()
        }
    }

    private let analyzer = PrivacyAnalyzerFactory.make()

    private func runBackground() {
        guard backgroundAnalysis == nil else { return }
        guard let previewSource else { return }
        backgroundSelection.begin()
        working = true
        #if DEBUG
        analysisCounts["background", default: 0] += 1
        #endif
        let currentStrength = strength, session = sessionID
        backgroundAnalysis = Task.detached(priority: .userInitiated) {
            let result: Result<(image: UIImage, mask: CIImage), Error>
            do { result = .success(try await analyzer.background(previewSource, strength: currentStrength)) }
            catch { result = .failure(error) }
            await MainActor.run {
                guard sessionID == session else { return }
                backgroundAnalysis = nil
                switch result {
                case .success(let output):
                    backgroundSelection.complete(count: 1); backgroundMask = output.mask; backgroundUnavailable = false
                    rerender()
                case .failure:
                    backgroundSelection.fail()
                    if mode == .background {
                        backgroundUnavailable = true; mode = .manual; manualDraws = true
                        rerender(); showDetectionFeedback("Background unavailable. Try Manual.")
                    }
                }
            }
        }
    }

    private func runFaces() {
        guard faceAnalysis == nil else { return }
        guard let original else { return }
        faceSelection.begin()
        working = true
        let session = sessionID
        #if DEBUG
        analysisCounts["faces", default: 0] += 1
        #endif
        faceAnalysis = Task.detached(priority: .userInitiated) {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-veil-delay-faces") {
                // Deterministic pending/re-entry UI test; actual Vision still produces the result.
                try? await Task.sleep(for: .seconds(15))
                guard !Task.isCancelled else { return }
            }
            #endif
            let result: Result<[CGRect], Error>
            do { result = .success(try await analyzer.faces(original)) }
            catch { result = .failure(error) }
            await MainActor.run {
                guard sessionID == session else { return }
                faceAnalysis = nil
                switch result {
                case .success(let faces):
                    faceRegions = faces; faceSelection.complete(count: faces.count)
                    rerender(); if mode == .faces { showDetectionFeedback(faceSelection.feedback(for: "faces")) }
                case .failure:
                    faceRegions = []; faceSelection.fail()
                    rerender(); if mode == .faces { showDetectionFeedback(faceSelection.feedback(for: "faces")) }
                }
            }
        }
    }

    private func runPlate() {
        guard plateAnalysis == nil else { return }
        guard let previewSource else { return }
        plateSelection.begin()
        working = true
        let session = sessionID
        #if DEBUG
        analysisCounts["plates", default: 0] += 1
        #endif
        plateAnalysis = Task.detached(priority: .userInitiated) {
            let result: Result<[CGRect], Error>
            do { result = .success(try await analyzer.plates(previewSource)) }
            catch { result = .failure(error) }
            await MainActor.run {
                guard sessionID == session else { return }
                plateAnalysis = nil
                plateSuggestions = (try? result.get()) ?? []
                switch result {
                case .success: plateSelection.complete(count: plateSuggestions.count)
                case .failure: plateSelection.fail()
                }
                rerender(); if mode == .plate { showDetectionFeedback(plateSelection.feedback(for: "plates")) }
            }
        }
    }

    private func adjusted(_ cached: [CGRect], overrides: [Int: CGRect]) -> [CGRect] {
        cached.enumerated().map { overrides[$0.offset] ?? $0.element }
    }
    private var adjustedFaceRegions: [CGRect] { adjusted(faceRegions, overrides: detectionAdjustments[.faces] ?? [:]) }
    private var adjustedPlateRegions: [CGRect] { adjusted(plateSuggestions, overrides: detectionAdjustments[.plate] ?? [:]) }
    private var currentDocumentRegions: [CGRect] {
        hidesEntireDocument ? adjusted(documentBoundaries, overrides: wholeDocumentAdjustments)
            : adjusted(documentDetails, overrides: detectionAdjustments[.documents] ?? [:])
    }
    private func adjustDetection(_ index: Int, _ rect: CGRect) {
        guard !showingOriginal, !showingFinalPreview, pillar == .redact, let mode else { return }
        let cached: [CGRect]
        switch mode {
        case .faces: cached = adjustedFaceRegions
        case .plate: cached = adjustedPlateRegions
        case .documents: cached = currentDocumentRegions
        default: return
        }
        let clipped = rect.standardized.intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
        guard cached.indices.contains(index), !clipped.isNull, clipped.width > 0, clipped.height > 0,
              clipped != cached[index] else { return }
        pushUndo()
        if mode == .documents && hidesEntireDocument { wholeDocumentAdjustments[index] = clipped }
        else { detectionAdjustments[mode, default: [:]][index] = clipped }
        rerender()
    }

    private func setDocumentCoverage(entire: Bool) {
        guard documentAnalysis == nil, didAnalyzeDocuments else { return }
        pushUndo(); hidesEntireDocument = entire
        documentSelection.complete(count: currentDocumentRegions.count); documentSelection.activate(); rerender()
    }

    private func toggleDocument(_ index: Int) {
        guard currentDocumentRegions.indices.contains(index) else { return }
        pushUndo()
        if selectedDocuments.contains(index) { selectedDocuments.remove(index) } else { selectedDocuments.insert(index) }
        UISelectionFeedbackGenerator().selectionChanged(); rerender()
    }

    private func runDocuments() {
        guard documentAnalysis == nil else { return }
        guard let original else { return }
        documentSelection.begin()
        working = true
        let session = sessionID
        #if DEBUG
        analysisCounts["documents", default: 0] += 1
        #endif
        documentAnalysis = Task.detached(priority: .userInitiated) {
            let result: Result<DocumentDetection.Result, Error>
            do { result = .success(try await analyzer.documents(original)) }
            catch { result = .failure(error) }
            await MainActor.run {
                guard sessionID == session else { return }
                documentAnalysis = nil
                let output = try? result.get()
                documentBoundaries = output?.boundaries ?? []; documentDetails = output?.details ?? []
                hidesEntireDocument = documentDetails.isEmpty
                switch result {
                case .success: documentSelection.complete(count: currentDocumentRegions.count)
                case .failure: documentSelection.fail()
                }
                rerender(); if mode == .documents { showDetectionFeedback(documentSelection.feedback(for: "documents")) }
            }
        }
    }

    private func toggleFace(_ index: Int) {
        guard faceRegions.indices.contains(index) else { return }
        UISelectionFeedbackGenerator().selectionChanged()
        pushUndo()
        if selectedFaces.contains(index) { selectedFaces.remove(index) } else { selectedFaces.insert(index) }
        rerender()
    }

    private func togglePlate(_ index: Int) {
        guard plateSuggestions.indices.contains(index) else { return }
        UISelectionFeedbackGenerator().selectionChanged()
        pushUndo()
        if selectedPlates.contains(index) { selectedPlates.remove(index) } else { selectedPlates.insert(index) }
        rerender()
    }

    private var hasSelectedDetections: Bool {
        mode == .faces ? !selectedFaces.isEmpty : !selectedPlates.isEmpty
    }

    private func toggleAllDetections() {
        pushUndo()
        if mode == .faces { if hasSelectedDetections { faceSelection.clear() } else { faceSelection.activate() } }
        else { if hasSelectedDetections { plateSelection.clear() } else { plateSelection.activate() } }
        rerender()
    }

    private func clearAll() {
        pushUndo()
        switch mode {
        case .background: backgroundSelection.clear()
        case .faces: faceSelection.clear()
        case .plate: plateSelection.clear()
        case .documents: documentSelection.clear()
        case .manual: manualRegions = []; strokes = []; draftStroke = nil
        case .none: return
        }
        rerender()
    }

    private func dismissDetectionFeedback() {
        feedbackDismissal?.cancel(); feedbackDismissal = nil; detectionMessage = nil
    }

    private func showDetectionFeedback(_ message: String?) {
        guard let message else { return }
        dismissDetectionFeedback()
        detectionMessage = message
        UIAccessibility.post(notification: .announcement, argument: message)
        feedbackDismissal = Task { @MainActor in
            do { try await Task.sleep(for: .seconds(UIAccessibility.isVoiceOverRunning ? 10 : 6)) }
            catch { return }
            detectionMessage = nil
        }
    }

    private func replaceManualRegions(_ regions: [BlurRegion]) {
        pushUndo(for: .manual)
        manualRegions = regions
        rerender()
    }

    private func updateStroke(_ stroke: BlurStroke?, committed: Bool) {
        if committed, let stroke {
            pushUndo(for: .manual)
            strokes.append(stroke)
            draftStroke = nil
        } else {
            draftStroke = stroke
        }
        // Coalesce touch samples: one render in flight, then render the latest image-space path.
        if brushRenderInFlight { brushRenderPending = true; return }
        brushRenderInFlight = true
        rerender(isBrushUpdate: true)
    }

    private var renderStrokes: [BlurStroke] { strokes + (draftStroke.map { [$0] } ?? []) }

    /// Detection caches, active selections and editing focus are independent. Both render
    /// destinations consume this exact snapshot; changing tools cannot remove another layer.
    private var renderLayers: [PrivacyRenderLayer] {
        var layers: [PrivacyRenderLayer] = []
        if backgroundSelection.isActive, let backgroundMask {
            layers.append(PrivacyRenderLayer(foregroundMask: backgroundMask,
                settings: layerSettings[.background] ?? PrivacyEffectSettings()))
        }
        let faces = selectedFaces.sorted().compactMap { index -> BlurRegion? in
            guard faceRegions.indices.contains(index) else { return nil }
            return BlurRegion(id: "face-\(index)", rect: adjustedFaceRegions[index], shape: .oval)
        }
        let plates = selectedPlates.sorted().compactMap { index -> BlurRegion? in
            guard plateSuggestions.indices.contains(index) else { return nil }
            return BlurRegion(id: "plate-\(index)", rect: adjustedPlateRegions[index], shape: .roundedRectangle)
        }
        let documents = selectedDocuments.sorted().compactMap { index -> BlurRegion? in
            guard currentDocumentRegions.indices.contains(index) else { return nil }
            return BlurRegion(id: "document-\(index)", rect: currentDocumentRegions[index], shape: .rectangle)
        }
        for (tool, regions) in [(EditorMode.faces, faces), (.plate, plates), (.documents, documents)] {
            layers.append(PrivacyRenderLayer(regions: regions, settings: layerSettings[tool] ?? PrivacyEffectSettings()))
        }
        layers.append(PrivacyRenderLayer(regions: manualRegions, strokes: renderStrokes,
            settings: layerSettings[.manual] ?? PrivacyEffectSettings()))
        return layers.filter { $0.foregroundMask != nil || !$0.regions.isEmpty || !$0.strokes.isEmpty }
    }

    private func rerender(isBrushUpdate: Bool = false) {
        guard let previewSource else { return }
        // Strength changes must not publish an unprocessed Background preview.
        guard mode != .background || backgroundMask != nil || !backgroundSelection.isActive else { return }
        working = true; renderRevision += 1
        let revision = renderRevision, currentMode = mode, currentStrength = strength, isDraft = draftStroke != nil
        let strokes = renderStrokes, layers = renderLayers, watermarkSnapshot = watermark
        if !isBrushUpdate && !brushRenderInFlight && completedRenderLayers == layers && completedWatermark == watermarkSnapshot {
            // Invalidate an obsolete in-flight render if the user restored the displayed state.
            previewRender?.cancel(); working = false
            return
        }
        if !brushRenderInFlight { previewRender?.cancel() }
        let renderer = previewRenderer
        previewRender = Task.detached(priority: .userInitiated) {
            guard !Task.isCancelled else { return }
            guard let source = previewSource.cgImage else { return }
            let output = await renderer.render(source: source, layers: layers, watermark: watermarkSnapshot)
                .map { UIImage(cgImage: $0, scale: previewSource.scale, orientation: .up) }
            guard !Task.isCancelled else { return }
            #if DEBUG
            // Test evidence must not block SwiftUI/AX, and must be ready before publishing
            // processingComplete. Encode once per accepted preview, off the main thread.
            let evidence = !isDraft ? output.flatMap { Self.testEvidence($0, source: previewSource) } : nil
            #endif
            await MainActor.run {
                defer {
                    if isBrushUpdate {
                        brushRenderInFlight = false
                        if brushRenderPending {
                            brushRenderPending = false
                            if mode == .manual {
                                brushRenderInFlight = true
                                rerender(isBrushUpdate: true)
                            }
                        }
                    }
                }
                guard renderRevision == revision else { return }
                working = false
                if let output {
                    completedRenderLayers = layers; completedWatermark = watermarkSnapshot; preview = output
                    #if DEBUG
                    if let evidence {
                        testRenderFingerprint = evidence.fingerprint
                        if watermarkSnapshot == nil || Self.allowsSyntheticWatermarkEvidence {
                        captureTestRender(evidence, names: [
                            "evidence-\(currentMode?.rawValue.lowercased() ?? "none")-\(currentStrength.rawValue.lowercased())-\(strokes.isEmpty ? "regions" : "brush")",
                            "preview-\(currentMode?.rawValue.lowercased() ?? "none")"])
                        }
                    }
                    #endif
                } else {
                    errorMessage = "The edited preview couldn’t be rendered. Try a smaller watermark or reset the edit."
                }
            }
        }
    }

    private func pushUndo(for tool: EditorMode? = nil, global: Bool = false, watermarkEdit: Bool = false) {
        let target = global ? nil : (tool ?? mode ?? .manual)
        // Once a new edit starts, Undo belongs to that category again. An old Reset
        // snapshot must not let Manual undo replace newer automatic selections.
        undoStack.append(EditSnapshot(watermark: watermark, watermarkScope: watermarkEdit, pillar: pillar, mode: target, focus: mode, backgroundActive: backgroundSelection.isActive, regions: manualRegions, strokes: strokes, detectionAdjustments: detectionAdjustments, wholeDocumentAdjustments: wholeDocumentAdjustments, selectedFaces: selectedFaces,
            selectedPlates: selectedPlates, selectedDocuments: selectedDocuments, hidesEntireDocument: hidesEntireDocument,
            settings: layerSettings), for: global ? nil : watermarkEdit ? .watermark : target.map(EditScope.privacy))
    }

    private var canUndo: Bool { pillar != .metadata && undoStack.canUndo(undoScope) }

    private func undo() {
        guard pillar != .metadata, let snapshot = undoStack.pop(for: undoScope) else { return }
        watermarkGestureEditing = false
        if snapshot.watermarkScope { watermark = snapshot.watermark; rerender(); return }
        if snapshot.mode == nil { watermark = snapshot.watermark; pillar = snapshot.pillar }
        // Restore only the edited category. A manual undo never restores older automatic
        // selections (and vice versa). The deliberately separate Reset edits remains global.
        if snapshot.mode == nil || snapshot.mode == .background {
            if snapshot.backgroundActive { backgroundSelection.activate() } else { backgroundSelection.clear() }
        }
        if snapshot.mode == nil || snapshot.mode == .faces {
            faceSelection.restoreSelection(snapshot.selectedFaces)
            detectionAdjustments[.faces] = snapshot.detectionAdjustments[.faces]
        }
        if snapshot.mode == nil || snapshot.mode == .plate {
            plateSelection.restoreSelection(snapshot.selectedPlates)
            detectionAdjustments[.plate] = snapshot.detectionAdjustments[.plate]
        }
        if snapshot.mode == nil || snapshot.mode == .documents {
            documentSelection.restoreSelection(snapshot.selectedDocuments); hidesEntireDocument = snapshot.hidesEntireDocument
            detectionAdjustments[.documents] = snapshot.detectionAdjustments[.documents]
            wholeDocumentAdjustments = snapshot.wholeDocumentAdjustments
        }
        if snapshot.mode == nil || snapshot.mode == .manual {
            manualRegions = snapshot.regions; strokes = snapshot.strokes; draftStroke = nil
        }
        if let tool = snapshot.mode { layerSettings[tool] = snapshot.settings[tool] }
        else { layerSettings = snapshot.settings; mode = snapshot.focus }
        rerender()
    }

    private func resetEdits() {
        guard let previewSource else { return }
        renderRevision += 1; working = false; backgroundUnavailable = false
        completedRenderLayers = nil
        pushUndo(global: true); detectionAdjustments = [:]; wholeDocumentAdjustments = [:]; watermark = nil; completedWatermark = nil; watermarkGestureEditing = false; pillar = .redact; backgroundSelection.clear(); faceSelection.clear(); plateSelection.clear(); documentSelection.clear(); dismissDetectionFeedback(); mode = nil; manualRegions = []; selectedFaces = []; selectedPlates = []
        selectedDocuments = []; showingOriginal = false; showingFinalPreview = false; strokes = []; draftStroke = nil; preview = previewSource; manualDraws = true
        rerender()
    }

    private func clearSession() {
        importTask?.cancel(); importTask = nil; importID = UUID(); importingPhoto = false
        exportingPhoto = false; successMessage = nil
        faceAnalysis?.cancel(); faceAnalysis = nil; documentAnalysis?.cancel(); documentAnalysis = nil
        backgroundAnalysis?.cancel(); backgroundAnalysis = nil; plateAnalysis?.cancel(); plateAnalysis = nil
        previewRender?.cancel(); previewRender = nil; brushRenderInFlight = false; brushRenderPending = false
        sessionID = UUID(); renderRevision += 1
        dismissDetectionFeedback()
        sourceMetadata = nil; metadataPolicy = .keep; watermark = nil; completedWatermark = nil; watermarkGestureEditing = false; pillar = .redact
        completedRenderLayers = nil; original = nil; previewSource = nil; preview = nil; backgroundMask = nil; mode = nil
        detectionAdjustments = [:]; wholeDocumentAdjustments = [:]; faceRegions = []; selectedFaces = []; plateSuggestions = []; selectedPlates = []; manualRegions = []
        strokes = []; draftStroke = nil; showingFinalPreview = false; undoStack = .init(); pickerItem = nil; showingOriginal = false; zoomed = false; working = false
    }

    private enum ExportDestination { case share, gallery, photos }

    private func prepareExport(destination: ExportDestination = .share) {
        guard let original else { errorMessage = "The image couldn’t be prepared."; return }
        guard !working, !detectingRequestedLayers, !exportingPhoto else { return }
        working = true; exportingPhoto = true; successMessage = nil
        #if DEBUG
        let previewSnapshot = preview
        let allowsWatermarkEvidence = Self.allowsSyntheticWatermarkEvidence
        #endif
        let currentMode = mode, layers = renderLayers, strokes = renderStrokes, session = sessionID
        let fixtureName = Self.testFixtureName
        let exportPolicy = metadataPolicy, exportMetadata = sourceMetadata, exportWatermark = watermark
        // Gallery/cloud metadata keeps its existing coarse style tag, not an editable recipe.
        // Select the strongest applied style; the saved pixels always contain every layer.
        let appliedEffects = Set(layers.filter { $0.foregroundMask != nil || !$0.regions.isEmpty || !$0.strokes.isEmpty }.map { $0.settings.effect.rawValue })
        let representativeEffect: PrivacyEffect = appliedEffects.contains(PrivacyEffect.redact.rawValue) ? .redact
            : appliedEffects.contains(PrivacyEffect.pixelate.rawValue) ? .pixelate : .blur
        Task {
            let lease: UUID
            do {
                let granted = try await exportAccess.begin()
                guard sessionID == session else {
                    if let granted { exportAccess.finish(granted, succeeded: false) }; return
                }
                guard let granted else {
                    working = false; exportingPhoto = false; showingPaywall = true; return
                }
                lease = granted
            } catch {
                guard sessionID == session else { return }
                working = false; exportingPhoto = false; errorMessage = VeilExportAccess.message(for: error); return
            }
            var handedToShare = false
            defer {
                if !handedToShare { exportAccess.finish(lease, succeeded: false) }
                if sessionID == session { working = false; exportingPhoto = false }
            }
            do {
                let (photo, url) = try await Task.detached(priority: .userInitiated) {
                    #if DEBUG
                    if (exportWatermark == nil || allowsWatermarkEvidence), let previewSnapshot, let evidence = Self.testEvidence(previewSnapshot, source: original) {
                        await MainActor.run {
                            if sessionID == session {
                                captureTestRender(evidence, names: ["preexport-\(currentMode?.rawValue.lowercased() ?? "none")",
                                    "evidence-preexport-\(currentMode?.rawValue.lowercased() ?? "none")-\(strokes.isEmpty ? "regions" : "brush")"])
                            }
                        }
                    }
                    #endif
                    let rendered: UIImage?
                    if let source = original.cgImage,
                       let output = PrivacyImageRenderer.render(source: source, layers: layers, watermark: exportWatermark) {
                        rendered = UIImage(cgImage: output, scale: 1, orientation: .up)
                    } else {
                        rendered = nil
                    }

                    guard let pixels = rendered?.cgImage else { throw PhotoExportFailure.renderFailed }
                    let photo = try PhotoExport.encode(pixels, policy: exportPolicy, metadata: exportMetadata)
                    let url = destination == .share ? try TemporaryPhoto.create(photo) : nil
                    #if DEBUG
                    if ProcessInfo.processInfo.arguments.contains("-veil-ui-testing"), (exportWatermark == nil || allowsWatermarkEvidence), let rendered {
                        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        let exportPNG = rendered.pngData()
                        try exportPNG?.write(to: directory.appendingPathComponent("export-\(currentMode?.rawValue.lowercased() ?? "none")-\(fixtureName).png"))
                        try exportPNG?.write(to: directory.appendingPathComponent("evidence-export-\(currentMode?.rawValue.lowercased() ?? "none")-\(strokes.isEmpty ? "regions" : "brush")-\(fixtureName).png"))
                        if let exportPNG {
                            let fingerprint = SHA256.hash(data: exportPNG).map { String(format: "%02x", $0) }.joined()
                            await MainActor.run { if sessionID == session { testExportFingerprint = fingerprint } }
                        }
                    }
                    #endif

                    return (photo, url)
                }.value
                guard sessionID == session else {
                    if let url { try? FileManager.default.removeItem(at: url) }; return
                }
                switch destination {
                case .share:
                    guard let url else { throw PhotoExportFailure.renderFailed }
                    shareLease = lease; handedToShare = true; shareItem = PhotoShareItem(url: url)
                case .gallery:
                    try await library.save(photo, effect: representativeEffect.rawValue)
                    if let warning = exportAccess.finish(lease, succeeded: true) { errorMessage = warning }
                    if sessionID == session {
                        successMessage = "In your Private Gallery"
                        UIAccessibility.post(notification: .announcement, argument: "Saved to Private Gallery")
                    }
                case .photos:
                    try await PhotosSaver.save(photo)
                    if let warning = exportAccess.finish(lease, succeeded: true) { errorMessage = warning }
                    if sessionID == session {
                        successMessage = "In Photos"
                        UIAccessibility.post(notification: .announcement, argument: "Saved to Photos")
                    }
                }
            } catch {
                if sessionID == session {
                    errorMessage = destination == .photos ? PhotosSaver.message(for: error) : "The edited image couldn’t be exported."
                }
            }
        }
    }
    private enum PhotoExportFailure: Error { case renderFailed }

    nonisolated private static var testFixtureName: String {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-veil-fixture"), arguments.indices.contains(index + 1) else { return "fixture" }
        return arguments[index + 1]
    }

    #if DEBUG
    private struct TestEvidence {
        let png: Data
        let original: Data?
        let fingerprint: String
    }
    nonisolated private static func testEvidence(_ image: UIImage, source: UIImage) -> TestEvidence? {
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("-veil-ui-testing"), !arguments.contains("-veil-rapid-selection-stress"),
              let data = image.pngData() else { return nil }
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let originalPath = directory.appendingPathComponent("original-\(testFixtureName).png")
        return TestEvidence(png: data, original: FileManager.default.fileExists(atPath: originalPath.path) ? nil : source.pngData(),
            fingerprint: SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined())
    }
    private func captureTestRender(_ evidence: TestEvidence, names: [String]) {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        for name in names { try? evidence.png.write(to: directory.appendingPathComponent("\(name)-\(Self.testFixtureName).png")) }
        if let original = evidence.original { try? original.write(to: directory.appendingPathComponent("original-\(Self.testFixtureName).png")) }
    }
    #endif
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var completion: (Bool) -> Void = { _ in }
    func makeCoordinator() -> ShareExportCompletion { ShareExportCompletion(completion: completion) }
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let coordinator = context.coordinator
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, error in
            // Activity completion is the only success signal available; it is not delivery confirmation.
            let hasError = error != nil
            Task { @MainActor in coordinator.finish(completed: completed, hasError: hasError) }
        }
        return controller
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
