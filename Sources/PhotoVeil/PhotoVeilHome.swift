import PhotosUI
import SwiftUI
import Vision

private struct EditSnapshot {
    let mode: EditorMode?
    let regions: [BlurRegion]
    let selectedFaces: Set<Int>
    let selectedPlates: Set<Int>
    let strength: BlurStrength
}

enum EditorMode: String, CaseIterable, Identifiable {
    case background = "Background", faces = "Faces", plate = "Plate", manual = "Manual"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .background: "person.crop.rectangle"
        case .faces: "face.smiling"
        case .plate: "rectangle.on.rectangle"
        case .manual: "scribble.variable"
        }
    }
}

struct PhotoVeilHome: View {
    @State private var pickerItem: PhotosPickerItem?
    @State private var original: UIImage?
    @State private var previewSource: UIImage?
    @State private var preview: UIImage?
    @State private var backgroundMask: CIImage?
    @State private var mode: EditorMode?
    @State private var strength: BlurStrength = .medium
    @State private var faceRegions: [CGRect] = []
    @State private var selectedFaces = Set<Int>()
    @State private var plateSuggestions: [CGRect] = []
    @State private var selectedPlates = Set<Int>()
    @State private var manualRegions: [BlurRegion] = []
    @State private var undoStack: [EditSnapshot] = []
    @State private var working = false
    @State private var showingOriginal = false
    @State private var showingShare = false
    @State private var manualDraws = true
    @State private var zoomed = false
    @State private var errorMessage: String?
    @State private var exportURL: URL?
    @State private var renderRevision = 0
    @State private var didAnalyzePlates = false

    var body: some View {
        Group {
            if original == nil { importView } else { editorView }
        }
        .background(Color(uiColor: .systemBackground))
        .onChange(of: pickerItem) { _, item in Task { await load(item) } }
        .onAppear(perform: loadFixtureIfRequested)
        .alert("Couldn’t open that photo", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: { Text(errorMessage ?? "Please choose another image.") }
        .sheet(isPresented: $showingShare) {
            if let exportURL { ShareSheet(items: [exportURL]) }
        }
    }

    private var importView: some View {
        VStack(spacing: 0) {
            Spacer()
            Image(systemName: "eye.slash.circle.fill")
                .font(.system(size: 58, weight: .light)).foregroundStyle(.primary)
                .padding(.bottom, 20)
            Text("Keep private details private.")
                .font(.system(size: 27, weight: .semibold, design: .rounded)).multilineTextAlignment(.center)
            Text("Blur backgrounds, faces and sensitive details.")
                .font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.top, 8)
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Label("Choose a photo", systemImage: "photo")
                    .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 15)
                    .background(Color.primary, in: Capsule())
                    .foregroundStyle(Color(uiColor: .systemBackground))
            }.padding(.top, 30).accessibilityIdentifier("choosePhoto")
            Label("Processed on your iPhone", systemImage: "iphone")
                .font(.footnote).foregroundStyle(.secondary).padding(.top, 17)
            Spacer()
            Spacer().frame(height: 22)
        }
        .padding(.horizontal, 28)
    }

    private var editorView: some View {
        VStack(spacing: 0) {
            editorToolbar
            ZStack(alignment: .topLeading) {
                if let original, let previewSource, let preview {
                    ZoomablePhotoCanvas(
                        original: original,
                        preview: showingOriginal ? previewSource : preview,
                        mode: mode,
                        faces: faceRegions,
                        selectedFaces: selectedFaces,
                        plates: plateSuggestions,
                        selectedPlates: selectedPlates,
                        regions: manualRegions,
                        drawsRegions: manualDraws,
                        onFaces: toggleFace,
                        onPlate: togglePlate,
                        onRegions: replaceManualRegions,
                        onZoomChanged: { zoomed = $0 }
                    )
                    .accessibilityIdentifier("photoCanvas")
                }

                HStack(spacing: 8) {
                    Button { showingOriginal.toggle() } label: {
                        Label(showingOriginal ? "Edited" : "Original", systemImage: showingOriginal ? "slider.horizontal.3" : "eye")
                            .font(.caption.weight(.semibold)).padding(.horizontal, 12).frame(height: 36)
                            .background(.regularMaterial, in: Capsule())
                    }
                    .accessibilityIdentifier("originalToggle")
                    if zoomed {
                        Button { NotificationCenter.default.post(name: .photoVeilFitPhoto, object: nil) } label: {
                            Image(systemName: "arrow.up.left.and.arrow.down.right").font(.caption.weight(.semibold))
                                .frame(width: 36, height: 36).background(.regularMaterial, in: Circle())
                        }
                        .accessibilityLabel("Fit photo")
                        .accessibilityIdentifier("fitPhoto")
                    }
                }
                .padding(12)
                if working {
                    ProgressView().controlSize(.regular).padding(13).background(.regularMaterial, in: Circle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity).accessibilityLabel("Processing")
                } else {
                    Color.clear.frame(width: 1, height: 1)
                        .accessibilityElement()
                        .accessibilityLabel(mode == .background ? (backgroundMask == nil ? "Manual fallback" : "Background ready") : "Processing complete")
                        .accessibilityIdentifier("processingComplete")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .secondarySystemBackground))
            editorControls
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }

    private var editorToolbar: some View {
        HStack(spacing: 10) {
            Button { clearSession() } label: { toolbarCircle("xmark") }
                .accessibilityLabel("Close photo")
            Spacer(minLength: 10)
            Button { undo() } label: { toolbarCircle("arrow.uturn.backward") }
                .disabled(undoStack.isEmpty).opacity(undoStack.isEmpty ? 0.42 : 1).accessibilityLabel("Undo")
            Menu {
                Button("Reset edits", systemImage: "arrow.counterclockwise", role: .destructive) { resetEdits() }
            } label: { toolbarCircle("ellipsis") }
                .accessibilityLabel("More editing actions")
            Button { prepareExport() } label: {
                Image(systemName: "square.and.arrow.up").font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white).frame(width: 44, height: 44)
                    .background(Color.accentColor, in: Circle())
            }
            .disabled(working).accessibilityLabel("Export")
        }
        .padding(.horizontal, 16).padding(.top, 6).padding(.bottom, 8)
        .background(.bar)
    }

    private func toolbarCircle(_ symbol: String) -> some View {
        Image(systemName: symbol).font(.system(size: 16, weight: .medium))
            .frame(width: 44, height: 44).background(.thinMaterial, in: Circle())
            .contentShape(Circle())
    }

    private var editorControls: some View {
        VStack(spacing: 9) {
            if let mode {
                HStack(spacing: 10) {
                    strengthControl
                    Spacer(minLength: 6)
                    if mode == .faces, !faceRegions.isEmpty {
                        Button { toggleAllFaces() } label: {
                            Label(selectedFaces.count == faceRegions.count ? "Clear all" : "Blur all", systemImage: "person.2.fill")
                                .font(.subheadline.weight(.semibold)).padding(.horizontal, 13).frame(height: 40)
                                .background(.thinMaterial, in: Capsule())
                        }
                        .accessibilityIdentifier("blurAllFaces")
                        .accessibilityLabel(selectedFaces.count == faceRegions.count ? "Clear all faces" : "Blur all faces")
                    }
                    if mode == .manual || mode == .plate {
                        Button { manualDraws.toggle() } label: {
                            Image(systemName: manualDraws ? "hand.raised" : "pencil.tip.crop.circle")
                                .font(.system(size: 17, weight: .semibold)).frame(width: 42, height: 42)
                                .background(.thinMaterial, in: Circle())
                        }
                        .accessibilityLabel(manualDraws ? "Move photo" : "Draw blur region")
                        .accessibilityIdentifier("canvasGestureMode")
                    }
                    if mode == .faces, faceRegions.isEmpty {
                        Button { select(.manual) } label: { Image(systemName: "scribble.variable").frame(width: 42, height: 42) }
                            .accessibilityLabel("Select manually")
                    }
                }
            }
            HStack(spacing: 5) {
                ForEach(EditorMode.allCases) { item in
                    Button { select(item) } label: {
                        VStack(spacing: 4) {
                            Image(systemName: item.symbol).font(.system(size: 18, weight: .medium))
                                .symbolEffect(.bounce, value: mode == item)
                            Text(item.rawValue).font(.caption2.weight(.medium)).lineLimit(1)
                        }
                        .foregroundStyle(mode == item ? Color.accentColor : Color.secondary)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(mode == item ? Color.accentColor.opacity(0.11) : .clear, in: Capsule())
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("mode_\(item.rawValue.lowercased())")
                }
            }
            .padding(5)
            .background(.thinMaterial, in: Capsule())
        }
        .padding(.horizontal, 14).padding(.top, 10).padding(.bottom, 28)
        .background(.bar)
    }

    private var strengthControl: some View {
        HStack(spacing: 0) {
            ForEach(BlurStrength.allCases) { option in
                Button(option.rawValue) {
                    guard strength != option else { return }
                    pushUndo(); strength = option; rerender()
                }
                .font(.caption.weight(strength == option ? .semibold : .regular))
                .foregroundStyle(strength == option ? Color.primary : Color.secondary)
                .padding(.horizontal, 11).frame(height: 36)
                .background(strength == option ? Color(uiColor: .tertiarySystemFill) : .clear, in: Capsule())
                .accessibilityIdentifier("strength_\(option.rawValue.lowercased())")
            }
        }
        .padding(3).background(.thinMaterial, in: Capsule())
    }

    @MainActor private func load(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        working = true
        defer { working = false }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data), let normalized = BlurRenderer.normalizedImage(image),
                  let downsampled = BlurRenderer.previewImage(normalized) else { throw BlurError.unavailable }
            beginSession(original: normalized, preview: downsampled)
        } catch { errorMessage = "The photo couldn’t be loaded. Please try another one." }
    }

    @MainActor private func beginSession(original: UIImage, preview: UIImage) {
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
        self.undoStack = []
        self.didAnalyzePlates = false
        self.strength = .medium
        self.showingOriginal = false
        self.manualDraws = true
    }

    @MainActor private func loadFixtureIfRequested() {
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("-veil-ui-testing"), original == nil,
              let fixtureName = arguments.contains("-veil-mode") && arguments.indices.contains(arguments.firstIndex(of: "-veil-mode")! + 1)
                ? (arguments[arguments.firstIndex(of: "-veil-mode")! + 1] == "background" ? "background-person" :
                   (arguments[arguments.firstIndex(of: "-veil-mode")! + 1] == "faces" ? "two-faces" : "two-people-car"))
                : "two-people-car",
              let fixtureURL = Bundle.main.url(forResource: fixtureName, withExtension: "jpg"),
              let fixtureData = try? Data(contentsOf: fixtureURL),
              let fixture = UIImage(data: fixtureData),
              let normalized = BlurRenderer.normalizedImage(fixture),
              let downsampled = BlurRenderer.previewImage(normalized) else { return }
        beginSession(original: normalized, preview: downsampled)
        if arguments.contains("-veil-test-faces") {
            faceRegions = [CGRect(x: 0.17, y: 0.17, width: 0.18, height: 0.13),
                           CGRect(x: 0.64, y: 0.20, width: 0.16, height: 0.12)]
            selectedFaces = Set(faceRegions.indices)
        }
        if let index = arguments.firstIndex(of: "-veil-mode"), arguments.indices.contains(index + 1),
           let requested = EditorMode.allCases.first(where: { $0.rawValue.lowercased() == arguments[index + 1] }) {
            select(requested)
        }
    }

    private func select(_ newMode: EditorMode) {
        guard mode != newMode else {
            if newMode == .manual || newMode == .plate { manualDraws = true }
            return
        }
        pushUndo()
        mode = newMode
        showingOriginal = false
        if newMode == .manual || newMode == .plate { manualDraws = true }
        switch newMode {
        case .background:
            if backgroundMask == nil { runBackground() } else { rerender() }
        case .faces:
            if ProcessInfo.processInfo.arguments.contains("-veil-test-faces"), !faceRegions.isEmpty {
                selectedFaces = Set(faceRegions.indices); rerender()
            } else if faceRegions.isEmpty { runFaces() } else { selectedFaces = Set(faceRegions.indices); rerender() }
        case .plate:
            if !didAnalyzePlates { runPlate() } else { rerender() }
        case .manual: rerender()
        }
    }

    private func runBackground() {
        guard let previewSource else { return }
        working = true; renderRevision += 1
        let revision = renderRevision, currentStrength = strength
        Task.detached(priority: .userInitiated) {
            let result: Result<(image: UIImage, mask: CIImage), Error>
            do { result = .success(try await BlurRenderer.renderBackground(previewSource, strength: currentStrength)) }
            catch { result = .failure(error) }
            await MainActor.run {
                guard renderRevision == revision else { return }
                working = false
                switch result {
                case .success(let output): backgroundMask = output.mask; preview = output.image
                case .failure: mode = .manual
                }
            }
        }
    }

    private func runFaces() {
        guard let previewSource else { return }
        working = true
        Task.detached(priority: .userInitiated) {
            let result: Result<[CGRect], Error>
            do { result = .success(try await BlurRenderer.detectFaces(in: previewSource)) }
            catch { result = .failure(error) }
            await MainActor.run {
                working = false
                switch result {
                case .success(let faces): faceRegions = faces; selectedFaces = Set(faces.indices); rerender()
                case .failure: faceRegions = []; selectedFaces = []
                }
            }
        }
    }

    private func runPlate() {
        guard let previewSource else { return }
        working = true
        Task.detached(priority: .userInitiated) {
            let result: Result<[CGRect], Error>
            do { result = .success(try await BlurRenderer.detectPlateSuggestions(in: previewSource)) }
            catch { result = .failure(error) }
            await MainActor.run {
                working = false; didAnalyzePlates = true
                plateSuggestions = (try? result.get()) ?? []
                rerender()
            }
        }
    }

    private func toggleFace(_ index: Int) {
        guard faceRegions.indices.contains(index) else { return }
        pushUndo()
        if selectedFaces.contains(index) { selectedFaces.remove(index) } else { selectedFaces.insert(index) }
        rerender()
    }

    private func togglePlate(_ index: Int) {
        guard plateSuggestions.indices.contains(index) else { return }
        pushUndo()
        if selectedPlates.contains(index) { selectedPlates.remove(index) } else { selectedPlates.insert(index) }
        rerender()
    }

    private func toggleAllFaces() {
        guard !faceRegions.isEmpty else { return }
        pushUndo()
        selectedFaces = selectedFaces.count == faceRegions.count ? [] : Set(faceRegions.indices)
        rerender()
    }

    private func replaceManualRegions(_ regions: [BlurRegion]) {
        pushUndo()
        manualRegions = regions
        rerender()
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
        case .manual: return manualRegions
        case .background, .none: return []
        }
    }

    private func rerender() {
        guard let previewSource else { return }
        working = true; renderRevision += 1
        let revision = renderRevision, currentMode = mode, currentStrength = strength
        let regions = regionsForCurrentMode(), mask = currentMode == .background ? backgroundMask : nil
        Task.detached(priority: .userInitiated) {
            let output: UIImage?
            if currentMode == .background, let mask {
                output = BlurRenderer.render(previewSource, regions: [], strength: currentStrength, foregroundMask: mask)
            } else {
                output = BlurRenderer.render(previewSource, regions: regions, strength: currentStrength)
            }
            await MainActor.run {
                guard renderRevision == revision else { return }
                working = false
                if let output { preview = output }
            }
        }
    }

    private func pushUndo() {
        undoStack.append(EditSnapshot(mode: mode, regions: manualRegions, selectedFaces: selectedFaces,
                                      selectedPlates: selectedPlates, strength: strength))
        if undoStack.count > 30 { undoStack.removeFirst() }
    }

    private func undo() {
        guard let snapshot = undoStack.popLast() else { return }
        mode = snapshot.mode; manualRegions = snapshot.regions; selectedFaces = snapshot.selectedFaces
        selectedPlates = snapshot.selectedPlates; strength = snapshot.strength
        rerender()
    }

    private func resetEdits() {
        guard let previewSource else { return }
        pushUndo(); mode = nil; manualRegions = []; selectedFaces = []; selectedPlates = []
        showingOriginal = false; preview = previewSource; manualDraws = true
    }

    private func clearSession() {
        original = nil; previewSource = nil; preview = nil; backgroundMask = nil; mode = nil
        faceRegions = []; selectedFaces = []; plateSuggestions = []; selectedPlates = []; manualRegions = []
        undoStack = []; pickerItem = nil; showingOriginal = false; zoomed = false; working = false
    }

    private func prepareExport() {
        guard let original else { errorMessage = "The image couldn’t be prepared."; return }
        working = true
        let currentMode = mode, regions = regionsForCurrentMode(), currentStrength = strength
        Task.detached(priority: .userInitiated) {
            let rendered: UIImage?
            if currentMode == .background {
                rendered = try? await BlurRenderer.renderBackground(original, strength: currentStrength).image
            } else if let source = original.cgImage,
                      let output = PrivacyImageRenderer.render(source: source, regions: regions, strength: currentStrength) {
                rendered = UIImage(cgImage: output, scale: 1, orientation: .up)
            } else {
                rendered = nil
            }
            guard let data = rendered?.jpegData(compressionQuality: 0.98) else {
                await MainActor.run { working = false; errorMessage = "The edited image couldn’t be exported." }
                return
            }
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("Veil-\(UUID().uuidString).jpg")
            do {
                try data.write(to: url, options: .atomic)
                await MainActor.run { working = false; exportURL = url; showingShare = true }
            } catch {
                await MainActor.run { working = false; errorMessage = "The edited image couldn’t be exported." }
            }
        }
    }

}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
