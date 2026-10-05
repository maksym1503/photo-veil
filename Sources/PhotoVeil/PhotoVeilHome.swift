import CryptoKit
import PhotosUI
import SwiftUI
import Vision

private struct EditSnapshot {
    let mode: EditorMode?
    let regions: [BlurRegion]
    let strokes: [BlurStroke]
    let selectedFaces: Set<Int>
    let selectedPlates: Set<Int>
    let selectedDocuments: Set<Int>
    let hidesEntireDocument: Bool
    let strength: BlurStrength
    let effect: PrivacyEffect
    let redactionColor: RedactionColor
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

struct PhotoVeilHome: View {
    @EnvironmentObject private var library: VeilLibrary
    @State private var showingGallery = false
    @State private var successMessage: String?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var showingSettings = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var original: UIImage?
    @State private var previewSource: UIImage?
    @State private var preview: UIImage?
    @State private var backgroundMask: CIImage?
    @State private var mode: EditorMode?
    @State private var strength: BlurStrength = .medium
    @State private var effect: PrivacyEffect = .blur
    @State private var redactionColor: RedactionColor = .black
    @State private var manualShape: BlurRegion.Shape = .roundedRectangle
    @State private var faceRegions: [CGRect] = []
    @State private var selectedFaces = Set<Int>()
    @State private var plateSuggestions: [CGRect] = []
    @State private var selectedPlates = Set<Int>()
    @State private var documentBoundaries: [CGRect] = []
    @State private var documentDetails: [CGRect] = []
    @State private var selectedDocuments = Set<Int>()
    @State private var hidesEntireDocument = false
    @State private var didAnalyzeDocuments = false
    @State private var manualRegions: [BlurRegion] = []
    @State private var strokes: [BlurStroke] = []
    @State private var brushRenderInFlight = false
    @State private var brushRenderPending = false
    @State private var draftStroke: BlurStroke?
    @State private var paintsStrokes = false
    @State private var showingFinalPreview = false
    @State private var undoStack: [EditSnapshot] = []
    @State private var working = false
    @State private var showingOriginal = false
    @State private var manualDraws = true
    @State private var zoomed = false
    @State private var errorMessage: String?
    @State private var shareItem: PhotoShareItem?
    @State private var renderRevision = 0
    @State private var didAnalyzePlates = false
    @State private var didAnalyzeFaces = false
    @State private var didAnalyzeBackground = false
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
    #endif

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
                VeilDemonstration().frame(maxWidth: 360).padding(.top, 32)
                VStack(spacing: 10) {
                    Text("Share the moment.\nKeep the details.")
                        .font(.largeTitle.weight(.semibold)).multilineTextAlignment(.center)
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
            .frame(maxWidth: .infinity).padding(.horizontal, 24).padding(.bottom, 32)
        }
    }

    @ToolbarContentBuilder private var navigationControls: some ToolbarContent {
        if original == nil {
            ToolbarItem(placement: .topBarLeading) {
                Button("Private Gallery", systemImage: "photo.stack") { showingGallery = true }
                    .labelStyle(.iconOnly).accessibilityIdentifier("gallery")
            }
            ToolbarItem(placement: .principal) { Text("Veil").font(.headline) }
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
                        .labelStyle(.iconOnly).disabled(undoStack.isEmpty)
                    Menu("More editing actions", systemImage: "ellipsis") {
                        Button("Reset edits", systemImage: "arrow.counterclockwise", role: .destructive) { resetEdits() }
                    }.labelStyle(.iconOnly)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(showingFinalPreview ? "Edit" : "Done") {
                    showingOriginal = false
                    showingFinalPreview.toggle()
                }.id(showingFinalPreview).disabled(working).accessibilityIdentifier("finalPreview")
            }
            if showingFinalPreview {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu("Save photo", systemImage: "square.and.arrow.down") {
                        Button("Save to Veil", systemImage: "photo.stack") { prepareExport(destination: .gallery) }
                            .accessibilityIdentifier("saveToVeil")
                        Button("Save to Photos", systemImage: "photo") { prepareExport(destination: .photos) }
                            .accessibilityIdentifier("saveToPhotos")
                    }.labelStyle(.iconOnly).disabled(working).accessibilityIdentifier("saveMenu")
                    Button("Share", systemImage: "square.and.arrow.up") { prepareExport() }
                        .labelStyle(.iconOnly).modifier(VeilActionStyle(prominent: true))
                        .disabled(working).accessibilityIdentifier("export")
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
                }
                #endif
                if working && draftStroke == nil {
                    ProgressView().controlSize(.regular).padding(13).background(.regularMaterial, in: Circle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity).accessibilityLabel("Processing").allowsHitTesting(false)
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
                if backgroundUnavailable && !showingFinalPreview {
                    Text("No foreground found. Select manually.").font(.caption)
                        .padding(10).modifier(VeilGlassSurface()).padding(8)
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
                HStack(spacing: 0) {
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
                    Button { guard redactionColor != color else { return }; pushUndo(); redactionColor = color; rerender() } label: {
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
                        Label(allDetectionsSelected ? "Clear all" : "Hide all", systemImage: "checkmark.rectangle.stack")
                            .font(.subheadline).lineLimit(1).frame(minHeight: 44)
                    }.buttonStyle(.plain)
                    .accessibilityIdentifier(mode == .faces ? "blurAllFaces" : "blurAllPlates")
                    .accessibilityLabel("\(allDetectionsSelected ? "Clear all" : "Hide all") \(mode == .faces ? "faces" : "plates")")
                } else {
                    Button { select(.manual) } label: { Label("Manual", systemImage: "scribble.variable").font(.subheadline).frame(minHeight: 44) }
                        .buttonStyle(.plain).accessibilityLabel("Select manually")
                }
            } else if mode == .documents {
                Menu {
                    Button("Hide all details") { setDocumentCoverage(entire: false) }
                    Button("Hide entire document") { setDocumentCoverage(entire: true) }
                    Button("Clear selections") { pushUndo(); selectedDocuments = []; rerender() }
                } label: {
                    Label("Coverage", systemImage: "doc.text").font(.subheadline).frame(minHeight: 44)
                }.buttonStyle(.plain).accessibilityIdentifier("documentCoverage")
                .accessibilityValue(didAnalyzeDocuments && documentBoundaries.isEmpty ? "No document found" : hidesEntireDocument ? "Entire document" : "Details")
            } else if mode == .manual {
                Menu {
                    Button("Rectangle") { paintsStrokes = false; manualShape = .roundedRectangle }
                    Button("Ellipse") { paintsStrokes = false; manualShape = .oval }
                    Button("Brush") { paintsStrokes = true }
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
        self.undoStack = []

        #if DEBUG
        analysisCounts = [:]
        #endif
        self.didAnalyzeBackground = false; self.didAnalyzePlates = false; self.didAnalyzeFaces = false
        self.documentBoundaries = []; self.documentDetails = []; self.selectedDocuments = []; self.didAnalyzeDocuments = false; self.hidesEntireDocument = false
        self.strength = .medium; self.effect = .blur; self.redactionColor = .black; self.manualShape = .roundedRectangle
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
        guard arguments.contains("-veil-ui-testing"), original == nil,
              let fixtureURL = Bundle.main.url(forResource: fixtureName, withExtension: "jpg"),
              let fixtureData = try? Data(contentsOf: fixtureURL),
              let fixture = UIImage(data: fixtureData),
              let normalized = BlurRenderer.normalizedImage(fixture),
              let downsampled = BlurRenderer.previewImage(normalized) else { return }
        beginSession(original: normalized, preview: downsampled)
        if let index = arguments.firstIndex(of: "-veil-mode"), arguments.indices.contains(index + 1),
           let requested = EditorMode.allCases.first(where: { $0.rawValue.lowercased() == arguments[index + 1] }) {
            select(requested)
        }
        #endif
    }

    private func select(_ newMode: EditorMode) {
        guard mode != newMode else {
            if newMode == .manual || newMode == .plate { manualDraws = true }
            return
        }
        UISelectionFeedbackGenerator().selectionChanged()
        pushUndo()
        renderRevision += 1
        mode = newMode
        backgroundUnavailable = false
        showingOriginal = false
        if newMode == .manual || newMode == .plate { manualDraws = true }
        switch newMode {
        case .background:
            if backgroundMask != nil { rerender() }
            else if didAnalyzeBackground { backgroundUnavailable = true; mode = .manual; manualDraws = true; rerender() }
            else { runBackground() }
        case .faces:
            if !didAnalyzeFaces { runFaces() } else { rerender() }
        case .plate:
            if !didAnalyzePlates { runPlate() } else { rerender() }
        case .documents:
            if !didAnalyzeDocuments { runDocuments() } else { rerender() }
        case .manual: rerender()
        }
    }

    private func runBackground() {
        guard backgroundAnalysis == nil else { return }
        guard let previewSource else { return }
        working = true
        #if DEBUG
        analysisCounts["background", default: 0] += 1
        #endif
        let currentStrength = strength, session = sessionID
        backgroundAnalysis = Task.detached(priority: .userInitiated) {
            let result: Result<(image: UIImage, mask: CIImage), Error>
            do { result = .success(try await BlurRenderer.renderBackground(previewSource, strength: currentStrength)) }
            catch { result = .failure(error) }
            await MainActor.run {
                guard sessionID == session else { return }
                backgroundAnalysis = nil; didAnalyzeBackground = true
                switch result {
                case .success(let output):
                    backgroundMask = output.mask; backgroundUnavailable = false
                    if mode == .background { rerender() }
                case .failure:
                    if mode == .background {
                        backgroundUnavailable = true; mode = .manual; manualDraws = true
                        rerender()
                    }
                }
            }
        }
    }

    private func runFaces() {
        guard faceAnalysis == nil else { return }
        guard let original else { return }
        working = true
        let session = sessionID
        #if DEBUG
        analysisCounts["faces", default: 0] += 1
        #endif
        faceAnalysis = Task.detached(priority: .userInitiated) {
            let result: Result<[CGRect], Error>
            do { result = .success(try await BlurRenderer.detectFaces(in: original)) }
            catch { result = .failure(error) }
            await MainActor.run {
                guard sessionID == session else { return }
                faceAnalysis = nil; didAnalyzeFaces = true
                switch result {
                case .success(let faces):
                    faceRegions = faces; selectedFaces = Set(faces.indices)
                    if mode == .faces { rerender() }
                case .failure:
                    faceRegions = []; selectedFaces = []
                    if mode == .faces { working = false }
                }
            }
        }
    }

    private func runPlate() {
        guard plateAnalysis == nil else { return }
        guard let previewSource else { return }
        working = true
        let session = sessionID
        #if DEBUG
        analysisCounts["plates", default: 0] += 1
        #endif
        plateAnalysis = Task.detached(priority: .userInitiated) {
            let result: Result<[CGRect], Error>
            do { result = .success(try await BlurRenderer.detectPlateSuggestions(in: previewSource)) }
            catch { result = .failure(error) }
            await MainActor.run {
                guard sessionID == session else { return }
                plateAnalysis = nil; didAnalyzePlates = true
                plateSuggestions = (try? result.get()) ?? []
                selectedPlates = Set(plateSuggestions.indices)
                if mode == .plate { rerender() }
            }
        }
    }

    private var currentDocumentRegions: [CGRect] { hidesEntireDocument ? documentBoundaries : documentDetails }

    private func setDocumentCoverage(entire: Bool) {
        pushUndo(); hidesEntireDocument = entire
        selectedDocuments = Set(currentDocumentRegions.indices); rerender()
    }

    private func toggleDocument(_ index: Int) {
        guard currentDocumentRegions.indices.contains(index) else { return }
        pushUndo()
        if selectedDocuments.contains(index) { selectedDocuments.remove(index) } else { selectedDocuments.insert(index) }
        UISelectionFeedbackGenerator().selectionChanged(); rerender()
    }

    private func runDocuments() {
        guard documentAnalysis == nil else { return }
        guard let original, let cg = original.cgImage else { return }
        working = true
        let session = sessionID
        #if DEBUG
        analysisCounts["documents", default: 0] += 1
        #endif
        documentAnalysis = Task.detached(priority: .userInitiated) {
            let analysis = BlurRenderer.previewImage(original, maxDimension: 3200)?.cgImage ?? cg
            let result = try? DocumentDetection.analyze(analysis)
            await MainActor.run {
                guard sessionID == session else { return }
                documentAnalysis = nil; didAnalyzeDocuments = true
                documentBoundaries = result?.boundaries ?? []; documentDetails = result?.details ?? []
                hidesEntireDocument = documentDetails.isEmpty
                selectedDocuments = Set(currentDocumentRegions.indices)
                if mode == .documents { rerender() }
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

    private var allDetectionsSelected: Bool {
        mode == .faces ? selectedFaces.count == faceRegions.count : selectedPlates.count == plateSuggestions.count
    }

    private func toggleAllDetections() {
        pushUndo()
        if mode == .faces { selectedFaces = allDetectionsSelected ? [] : Set(faceRegions.indices) }
        else { selectedPlates = allDetectionsSelected ? [] : Set(plateSuggestions.indices) }
        rerender()
    }

    private func replaceManualRegions(_ regions: [BlurRegion]) {
        pushUndo()
        manualRegions = regions
        rerender()
    }

    private func updateStroke(_ stroke: BlurStroke?, committed: Bool) {
        if committed, let stroke {
            pushUndo()
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

    private var renderStrokes: [BlurStroke] {
        guard mode == .manual || mode == .plate || mode == .faces else { return [] }
        return strokes + (draftStroke.map { [$0] } ?? [])
    }

    private func regionsForCurrentMode() -> [BlurRegion] {
        switch mode {
        case .faces:
            let faces = selectedFaces.sorted().compactMap { index -> BlurRegion? in
                guard faceRegions.indices.contains(index) else { return nil }
                return BlurRegion(id: "face-\(index)", rect: faceRegions[index], shape: .oval)
            }
            return faces + manualRegions
        case .plate:
            let plates = selectedPlates.sorted().compactMap { index -> BlurRegion? in
                guard plateSuggestions.indices.contains(index) else { return nil }
                return BlurRegion(id: "plate-\(index)", rect: plateSuggestions[index], shape: .roundedRectangle)
            }
            return plates + manualRegions
        case .documents:
            return selectedDocuments.sorted().compactMap { index in
                guard currentDocumentRegions.indices.contains(index) else { return nil }
                return BlurRegion(id: "document-\(index)", rect: currentDocumentRegions[index], shape: .rectangle)
            } + manualRegions
        case .manual: return manualRegions
        case .background, .none: return []
        }
    }

    private func rerender(isBrushUpdate: Bool = false) {
        guard let previewSource else { return }
        // Strength changes must not publish an unprocessed Background preview.
        guard mode != .background || backgroundMask != nil else { return }
        working = true; renderRevision += 1
        let revision = renderRevision, currentMode = mode, currentStrength = strength, isDraft = draftStroke != nil
        let strokes = renderStrokes, currentEffect = effect, currentColor = redactionColor
        let regions = regionsForCurrentMode(), mask = currentMode == .background ? backgroundMask : nil
        if !brushRenderInFlight { previewRender?.cancel() }
        previewRender = Task.detached(priority: .userInitiated) {
            guard !Task.isCancelled else { return }
            let output: UIImage?
            if currentMode == .background, let mask {
                output = BlurRenderer.render(previewSource, regions: [], strength: currentStrength, foregroundMask: mask, strokes: strokes, effect: currentEffect, redactionColor: currentColor)
            } else {
                output = BlurRenderer.render(previewSource, regions: regions, strength: currentStrength, strokes: strokes, effect: currentEffect, redactionColor: currentColor)
            }
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
                    preview = output
                    if !isDraft {
                        captureTestRender(output, name: "evidence-\(currentMode?.rawValue.lowercased() ?? "none")-\(currentStrength.rawValue.lowercased())-\(strokes.isEmpty ? "regions" : "brush")")
                        captureTestRender(output, name: "preview-\(currentMode?.rawValue.lowercased() ?? "none")")
                    }
                }
            }
        }
    }

    private func pushUndo() {
        undoStack.append(EditSnapshot(mode: mode, regions: manualRegions, strokes: strokes, selectedFaces: selectedFaces,
                                      selectedPlates: selectedPlates, selectedDocuments: selectedDocuments, hidesEntireDocument: hidesEntireDocument, strength: strength, effect: effect, redactionColor: redactionColor))
        if undoStack.count > 30 { undoStack.removeFirst() }
    }

    private func undo() {
        guard let snapshot = undoStack.popLast() else { return }
        mode = snapshot.mode; manualRegions = snapshot.regions; strokes = snapshot.strokes; draftStroke = nil; selectedFaces = snapshot.selectedFaces
        selectedDocuments = snapshot.selectedDocuments; hidesEntireDocument = snapshot.hidesEntireDocument
        selectedPlates = snapshot.selectedPlates; strength = snapshot.strength; effect = snapshot.effect; redactionColor = snapshot.redactionColor
        rerender()
    }

    private func resetEdits() {
        guard let previewSource else { return }
        renderRevision += 1; working = false; backgroundUnavailable = false
        pushUndo(); mode = nil; manualRegions = []; selectedFaces = []; selectedPlates = []
        selectedDocuments = []; showingOriginal = false; showingFinalPreview = false; strokes = []; draftStroke = nil; preview = previewSource; manualDraws = true
    }

    private func clearSession() {
        faceAnalysis?.cancel(); faceAnalysis = nil; documentAnalysis?.cancel(); documentAnalysis = nil
        backgroundAnalysis?.cancel(); backgroundAnalysis = nil; plateAnalysis?.cancel(); plateAnalysis = nil
        previewRender?.cancel(); previewRender = nil; brushRenderInFlight = false; brushRenderPending = false
        sessionID = UUID(); renderRevision += 1
        original = nil; previewSource = nil; preview = nil; backgroundMask = nil; mode = nil
        faceRegions = []; selectedFaces = []; plateSuggestions = []; selectedPlates = []; manualRegions = []
        strokes = []; draftStroke = nil; showingFinalPreview = false; undoStack = []; pickerItem = nil; showingOriginal = false; zoomed = false; working = false
    }

    private enum ExportDestination { case share, gallery, photos }

    private func prepareExport(destination: ExportDestination = .share) {
        guard let original else { errorMessage = "The image couldn’t be prepared."; return }
        working = true
        if let preview {
            captureTestRender(preview, name: "preexport-\(mode?.rawValue.lowercased() ?? "none")")
            captureTestRender(preview, name: "evidence-preexport-\(mode?.rawValue.lowercased() ?? "none")-\(strokes.isEmpty ? "regions" : "brush")")
        }
        let currentMode = mode, regions = regionsForCurrentMode(), currentStrength = strength, strokes = renderStrokes
        let mask = currentMode == .background ? backgroundMask : nil, session = sessionID
        let currentEffect = effect, currentColor = redactionColor
        Task.detached(priority: .userInitiated) {
            let rendered: UIImage?
            if let source = original.cgImage,
               let output = PrivacyImageRenderer.render(source: source, regions: regions, strength: currentStrength, foregroundMask: mask, strokes: strokes, effect: currentEffect, redactionColor: currentColor) {
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
                    try rendered.pngData()?.write(to: directory.appendingPathComponent("export-\(currentMode?.rawValue.lowercased() ?? "none")-\(Self.testFixtureName).png"))
                    try rendered.pngData()?.write(to: directory.appendingPathComponent("evidence-export-\(currentMode?.rawValue.lowercased() ?? "none")-\(strokes.isEmpty ? "regions" : "brush")-\(Self.testFixtureName).png"))
                }
                #endif
                guard await MainActor.run(body: { sessionID == session }) else {
                    if let url { try? FileManager.default.removeItem(at: url) }; return
                }
                switch destination {
                case .share:
                    await MainActor.run { working = false; shareItem = url.map { PhotoShareItem(url: $0) } }
                case .gallery:
                    try await library.save(data, effect: currentEffect.rawValue)
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

    private static var testFixtureName: String {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-veil-fixture"), arguments.indices.contains(index + 1) else { return "fixture" }
        return arguments[index + 1]
    }

    private func captureTestRender(_ image: UIImage, name: String) {
        #if DEBUG
        guard ProcessInfo.processInfo.arguments.contains("-veil-ui-testing") else { return }
        if let data = image.pngData() { testRenderFingerprint = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() }
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? image.pngData()?.write(to: directory.appendingPathComponent("\(name)-\(Self.testFixtureName).png"))
        try? previewSource?.pngData()?.write(to: directory.appendingPathComponent("original-\(Self.testFixtureName).png"))
        #endif
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
