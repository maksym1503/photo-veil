import CryptoKit
import PhotosUI
import SwiftUI
import Vision

private struct EditSnapshot {
    let mode: EditorMode?
    let focus: EditorMode?
    let backgroundActive: Bool
    let regions: [BlurRegion]
    let strokes: [BlurStroke]
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
    @State private var showingGallery = false
    @State private var successMessage: String?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var showingSettings = false
    @State private var pickerItem: PhotosPickerItem?
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
    @State private var undoStack = ScopedUndoHistory<EditorMode, EditSnapshot>()
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
        .onChange(of: pickerItem) { _, item in Task { await load(item) } }
        .onAppear(perform: loadFixtureIfRequested)
        .alert("Couldn’t finish that action", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: { Text(errorMessage ?? "Please choose another image.") }
        .sheet(isPresented: $showingSettings) { VeilSettings() }
        .sheet(isPresented: $showingGallery) { VeilGallery() }
        .alert("Saved", isPresented: Binding(get: { successMessage != nil }, set: { if !$0 { successMessage = nil } })) {
            Button("OK") { successMessage = nil }
        } message: { Text(successMessage ?? "") }
        .sheet(item: $shareItem) { item in
            ShareSheet(items: [item.url]).onDisappear { try? FileManager.default.removeItem(at: item.url) }
        }
    }

    private var importView: some View {
        ScrollView {
            VStack(spacing: 24) {
                VeilDemonstration().frame(maxWidth: .infinity)
                VStack(spacing: 10) {
                    Text("Share the moment.\nKeep the details.")
                        .font(.largeTitle.weight(.semibold)).multilineTextAlignment(.center).padding(.horizontal, 24)
                    Text("Choose. Blur. Share.")
                        .font(.body).foregroundStyle(.secondary)
                }
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Label("Choose Photo", systemImage: "photo")
                        .font(.headline).padding(.horizontal, 32).frame(minHeight: 52)
                }
                .modifier(VeilActionStyle(prominent: true))
                .accessibilityIdentifier("choosePhoto")
                Label("Processed on this iPhone", systemImage: "iphone")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity).padding(.bottom, 32)
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
                    showingFinalPreview.toggle()
                }.id(showingFinalPreview).disabled(working || detectingRequestedLayers).accessibilityIdentifier("finalPreview")
            }
            if showingFinalPreview {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu("Save photo", systemImage: "square.and.arrow.down") {
                        Button("Save to Veil", systemImage: "photo.stack") { prepareExport(destination: .gallery) }
                            .accessibilityIdentifier("saveToVeil")
                        Button("Save to Photos", systemImage: "photo") { prepareExport(destination: .photos) }
                            .accessibilityIdentifier("saveToPhotos")
                    }.labelStyle(.iconOnly).disabled(working || detectingRequestedLayers).accessibilityIdentifier("saveMenu")
                    Button("Share", systemImage: "square.and.arrow.up") { prepareExport() }
                        .labelStyle(.iconOnly).modifier(VeilActionStyle(prominent: true))
                        .disabled(working || detectingRequestedLayers).accessibilityIdentifier("export")
                }
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
                        mode: showingOriginal || showingFinalPreview ? nil : mode,
                        faces: faceRegions,
                        selectedFaces: selectedFaces,
                        plates: mode == .documents ? currentDocumentRegions : plateSuggestions,
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
                        onZoomChanged: { zoomed = $0 }
                    )
                    .accessibilityIdentifier("photoCanvas")
                }

                if !showingFinalPreview {
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
                .padding(12)
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
                    ProgressView().controlSize(.regular).padding(13).background(.regularMaterial, in: Circle())
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
                }
            }
            // Retain the control surface's size so Done never changes the photo transform.
            if showingFinalPreview { editorControls.hidden().accessibilityHidden(true) }
            else { editorControls }
        }
    }

    private var usesExpandedControls: Bool { dynamicTypeSize > .large }

    // Keep the same three layout slots for every tool/effect. Only their contents change.
    private var editorControls: some View {
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
                                    .font(.system(size: 19, weight: .medium)).frame(width: 26, height: 24)
                                Text(item.label).font(.caption2.weight(.medium)).lineLimit(1)
                                    .frame(maxWidth: .infinity).frame(height: 16)
                            }
                            .foregroundStyle(mode == item ? Color.primary : Color.secondary)
                            .frame(maxWidth: .infinity).frame(height: 56)
                            .background(mode == item ? Color(uiColor: .tertiarySystemFill) : .clear, in: RoundedRectangle(cornerRadius: 20))
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

    @MainActor private func load(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        working = true
        defer { working = false }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let pair = await Task.detached(priority: .userInitiated, operation: { () -> (UIImage, UIImage)? in
                      guard let image = UIImage(data: data), let normalized = BlurRenderer.normalizedImage(image),
                            let downsampled = BlurRenderer.previewImage(normalized) else { return nil }
                      return (normalized, downsampled)
                  }).value else { throw BlurError.unavailable }
            beginSession(original: pair.0, preview: pair.1)
        } catch { errorMessage = "The photo couldn’t be loaded. Please try another one." }
    }

    @MainActor private func beginSession(original: UIImage, preview: UIImage) {
        faceAnalysis?.cancel(); faceAnalysis = nil; documentAnalysis?.cancel(); documentAnalysis = nil
        backgroundAnalysis?.cancel(); backgroundAnalysis = nil; plateAnalysis?.cancel(); plateAnalysis = nil
        previewRender?.cancel(); previewRender = nil; brushRenderInFlight = false; brushRenderPending = false
        sessionID = UUID(); renderRevision += 1; backgroundUnavailable = false
        self.original = original
        self.previewSource = preview
        self.preview = preview
        self.mode = nil
        self.backgroundMask = nil
        self.faceRegions = []
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
              let downsampled = BlurRenderer.previewImage(normalized) else { return }
        beginSession(original: normalized, preview: downsampled)
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

    private var currentDocumentRegions: [CGRect] { hidesEntireDocument ? documentBoundaries : documentDetails }

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
            return BlurRegion(id: "face-\(index)", rect: faceRegions[index], shape: .oval)
        }
        let plates = selectedPlates.sorted().compactMap { index -> BlurRegion? in
            guard plateSuggestions.indices.contains(index) else { return nil }
            return BlurRegion(id: "plate-\(index)", rect: plateSuggestions[index], shape: .roundedRectangle)
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
        let strokes = renderStrokes, layers = renderLayers
        if !isBrushUpdate && !brushRenderInFlight && completedRenderLayers == layers {
            // Invalidate an obsolete in-flight render if the user restored the displayed state.
            previewRender?.cancel(); working = false
            return
        }
        if !brushRenderInFlight { previewRender?.cancel() }
        let renderer = previewRenderer
        previewRender = Task.detached(priority: .userInitiated) {
            guard !Task.isCancelled else { return }
            guard let source = previewSource.cgImage else { return }
            let output = await renderer.render(source: source, layers: layers)
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
                    completedRenderLayers = layers; preview = output
                    #if DEBUG
                    if let evidence {
                        testRenderFingerprint = evidence.fingerprint
                        captureTestRender(evidence, names: [
                            "evidence-\(currentMode?.rawValue.lowercased() ?? "none")-\(currentStrength.rawValue.lowercased())-\(strokes.isEmpty ? "regions" : "brush")",
                            "preview-\(currentMode?.rawValue.lowercased() ?? "none")"])
                    }
                    #endif
                }
            }
        }
    }

    private func pushUndo(for tool: EditorMode? = nil, global: Bool = false) {
        let target = global ? nil : (tool ?? mode ?? .manual)
        // Once a new edit starts, Undo belongs to that category again. An old Reset
        // snapshot must not let Manual undo replace newer automatic selections.
        undoStack.append(EditSnapshot(mode: target, focus: mode, backgroundActive: backgroundSelection.isActive, regions: manualRegions, strokes: strokes, selectedFaces: selectedFaces,
            selectedPlates: selectedPlates, selectedDocuments: selectedDocuments, hidesEntireDocument: hidesEntireDocument,
            settings: layerSettings), for: target)
    }

    private var canUndo: Bool { undoStack.canUndo(mode) }

    private func undo() {
        guard let snapshot = undoStack.pop(for: mode) else { return }
        // Restore only the edited category. A manual undo never restores older automatic
        // selections (and vice versa). The deliberately separate Reset edits remains global.
        if snapshot.mode == nil || snapshot.mode == .background {
            if snapshot.backgroundActive { backgroundSelection.activate() } else { backgroundSelection.clear() }
        }
        if snapshot.mode == nil || snapshot.mode == .faces { faceSelection.restoreSelection(snapshot.selectedFaces) }
        if snapshot.mode == nil || snapshot.mode == .plate { plateSelection.restoreSelection(snapshot.selectedPlates) }
        if snapshot.mode == nil || snapshot.mode == .documents {
            documentSelection.restoreSelection(snapshot.selectedDocuments); hidesEntireDocument = snapshot.hidesEntireDocument
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
        pushUndo(global: true); backgroundSelection.clear(); faceSelection.clear(); plateSelection.clear(); documentSelection.clear(); dismissDetectionFeedback(); mode = nil; manualRegions = []; selectedFaces = []; selectedPlates = []
        selectedDocuments = []; showingOriginal = false; showingFinalPreview = false; strokes = []; draftStroke = nil; preview = previewSource; manualDraws = true
    }

    private func clearSession() {
        faceAnalysis?.cancel(); faceAnalysis = nil; documentAnalysis?.cancel(); documentAnalysis = nil
        backgroundAnalysis?.cancel(); backgroundAnalysis = nil; plateAnalysis?.cancel(); plateAnalysis = nil
        previewRender?.cancel(); previewRender = nil; brushRenderInFlight = false; brushRenderPending = false
        sessionID = UUID(); renderRevision += 1
        dismissDetectionFeedback()
        completedRenderLayers = nil; original = nil; previewSource = nil; preview = nil; backgroundMask = nil; mode = nil
        faceRegions = []; selectedFaces = []; plateSuggestions = []; selectedPlates = []; manualRegions = []
        strokes = []; draftStroke = nil; showingFinalPreview = false; undoStack = .init(); pickerItem = nil; showingOriginal = false; zoomed = false; working = false
    }

    private enum ExportDestination { case share, gallery, photos }

    private func prepareExport(destination: ExportDestination = .share) {
        guard let original else { errorMessage = "The image couldn’t be prepared."; return }
        working = true
        #if DEBUG
        let previewSnapshot = preview
        #endif
        let currentMode = mode, layers = renderLayers, strokes = renderStrokes, session = sessionID
        let fixtureName = Self.testFixtureName
        // Gallery/cloud metadata keeps its existing coarse style tag, not an editable recipe.
        // Select the strongest applied style; the saved pixels always contain every layer.
        let appliedEffects = Set(layers.filter { $0.foregroundMask != nil || !$0.regions.isEmpty || !$0.strokes.isEmpty }.map { $0.settings.effect.rawValue })
        let representativeEffect: PrivacyEffect = appliedEffects.contains(PrivacyEffect.redact.rawValue) ? .redact
            : appliedEffects.contains(PrivacyEffect.pixelate.rawValue) ? .pixelate : .blur
        Task.detached(priority: .userInitiated) {
            #if DEBUG
            if let previewSnapshot, let evidence = Self.testEvidence(previewSnapshot, source: original) {
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
               let output = PrivacyImageRenderer.render(source: source, layers: layers) {
                rendered = UIImage(cgImage: output, scale: 1, orientation: .up)
            } else {
                rendered = nil
            }
            guard let data = rendered?.jpegData(compressionQuality: 0.98) else {
                await MainActor.run { working = false; errorMessage = "The edited image couldn’t be exported." }
                return
            }
            do {
                let url = destination == .share ? try TemporaryPhoto.create(data) : nil
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("-veil-ui-testing"), let rendered {
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
                guard await MainActor.run(body: { sessionID == session }) else {
                    if let url { try? FileManager.default.removeItem(at: url) }; return
                }
                switch destination {
                case .share:
                    await MainActor.run { working = false; shareItem = url.map { PhotoShareItem(url: $0) } }
                case .gallery:
                    try await library.save(data, effect: representativeEffect.rawValue)
                    await MainActor.run { working = false; successMessage = "Saved to Private Gallery on this iPhone" }
                case .photos:
                    do {
                        try await PhotosSaver.save(data)
                        await MainActor.run { working = false; successMessage = "Saved to Photos" }
                    } catch {
                        await MainActor.run { working = false; errorMessage = PhotosSaver.message(for: error) }
                    }
                }
            } catch {
                await MainActor.run { working = false; errorMessage = "The edited image couldn’t be exported." }
            }
        }
    }

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
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
