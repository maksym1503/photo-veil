import PhotosUI
import SwiftUI
import Vision
import Photos

private enum EditorMode: String, CaseIterable, Identifiable {
    case background = "Background", faces = "Faces", plate = "Plate", manual = "Manual"
    var id: String { rawValue }
    var symbol: String { switch self { case .background: "person.fill"; case .faces: "face.smiling"; case .plate: "rectangle.on.rectangle"; case .manual: "scribble.variable" } }
}

private struct EditSnapshot { let regions: [CGRect]; let selectedFaces: Set<Int>; let mode: EditorMode }

struct PhotoVeilHome: View {
    @State private var pickerItem: PhotosPickerItem?
    @State private var original: UIImage?
    @State private var preview: UIImage?
    @State private var backgroundMask: CIImage?
    @State private var mode: EditorMode?
    @State private var strength: BlurStrength = .medium
    @State private var faceRegions: [CGRect] = []
    @State private var selectedFaces = Set<Int>()
    @State private var plateSuggestions: [CGRect] = []
    @State private var regions: [CGRect] = []
    @State private var undoStack: [EditSnapshot] = []
    @State private var working = false
    @State private var errorMessage: String?
    @State private var showingShare = false
    @State private var showingOriginal = false
    @State private var exportURL: URL?
    @State private var dragStart: CGPoint?
    @State private var pendingRegion: CGRect?

    var body: some View {
        Group {
            if original == nil { importView } else { editorView }
        }
        .background(Color(uiColor: .systemBackground))
        .preferredColorScheme(nil)
        .onChange(of: pickerItem) { _, item in Task { await load(item) } }
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
                .font(.system(size: 62, weight: .light)).foregroundStyle(.primary)
                .padding(.bottom, 22)
            Text("Keep private details private.")
                .font(.system(size: 28, weight: .semibold, design: .rounded)).multilineTextAlignment(.center)
            Text("Blur backgrounds, faces and sensitive details.")
                .font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.top, 9)
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Label("Choose a photo", systemImage: "photo")
                    .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(Color.primary, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(Color(uiColor: .systemBackground))
            }.padding(.top, 34).accessibilityIdentifier("choosePhoto")
            Text("Processed on your iPhone")
                .font(.footnote).foregroundStyle(.secondary).padding(.top, 18)
            Spacer()
            Spacer().frame(height: 24)
        }
        .padding(.horizontal, 28)
    }

    private var editorView: some View {
        VStack(spacing: 0) {
            HStack {
                Button { clearSession() } label: { Image(systemName: "xmark").font(.headline).frame(width: 44, height: 44).background(.ultraThinMaterial, in: Circle()) }
                    .accessibilityLabel("Close photo")
                Spacer()
                Button { undo() } label: { Image(systemName: "arrow.uturn.backward").font(.headline).frame(width: 44, height: 44).background(.ultraThinMaterial, in: Circle()) }
                    .disabled(undoStack.isEmpty).opacity(undoStack.isEmpty ? 0.45 : 1).accessibilityLabel("Undo")
                Button { resetEdits() } label: { Text("Reset").font(.subheadline.weight(.semibold)).padding(.horizontal, 15).frame(height: 44).background(.ultraThinMaterial, in: Capsule()) }
                    .padding(.leading, 8).accessibilityIdentifier("reset")
                Button { prepareExport() } label: { Image(systemName: "square.and.arrow.up").font(.headline).frame(width: 44, height: 44).background(Color.primary, in: Circle()).foregroundStyle(Color(uiColor: .systemBackground)) }
                    .padding(.leading, 8).accessibilityLabel("Export")
            }.padding(.horizontal, 16).padding(.top, 8)

            GeometryReader { proxy in
                let mapper = ImageGeometryMapper(imageSize: original?.size ?? .zero, container: CGRect(origin: .zero, size: proxy.size))
                ZStack {
                    if let displayed = showingOriginal ? original : preview {
                        Image(uiImage: displayed).resizable().aspectRatio(contentMode: .fit).frame(width: proxy.size.width, height: proxy.size.height)
                            .accessibilityIdentifier("photoPreview")
                        if !showingOriginal { regionOverlays(mapper: mapper) }
                    }
                    if working { ProgressView().padding(18).background(.ultraThinMaterial, in: Capsule()).accessibilityLabel("Processing") }
                }
                .contentShape(Rectangle())
                .gesture(manualGesture(mapper: mapper))
                .onLongPressGesture(minimumDuration: 0.35, maximumDistance: 30, pressing: { pressing in showingOriginal = pressing }, perform: {})
                .overlay(alignment: .topLeading) {
                    if mode == .manual, let rect = pendingRegion { RoundedRectangle(cornerRadius: 14).stroke(Color.yellow, lineWidth: 2).frame(width: rect.width * mapper.displayedRect.width, height: rect.height * mapper.displayedRect.height).position(x: mapper.viewRect(fromNormalized: rect).midX, y: mapper.viewRect(fromNormalized: rect).midY) }
                }
            }
            .padding(.horizontal, 8).padding(.vertical, 8)
            .frame(maxHeight: .infinity)

            VStack(spacing: 12) {
                if let mode {
                    HStack {
                        Text(modeHint).font(.footnote).foregroundStyle(.secondary).lineLimit(2)
                        Spacer(minLength: 8)
                        Menu {
                            ForEach(BlurStrength.allCases) { option in Button(option.rawValue) { strength = option; rerender() } }
                        } label: {
                            Label(strength.rawValue, systemImage: "circle.lefthalf.filled").font(.caption.weight(.semibold)).padding(.horizontal, 12).padding(.vertical, 9).background(Color(uiColor: .secondarySystemBackground), in: Capsule())
                        }.accessibilityIdentifier("blurStrength")
                    }
                    if mode == .faces, !faceRegions.isEmpty {
                        Button(selectedFaces.count == faceRegions.count ? "Leave faces clear" : "Blur all faces") { toggleAllFaces() }
                            .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity).padding(.vertical, 10).background(Color(uiColor: .secondarySystemBackground), in: Capsule())
                            .accessibilityIdentifier("blurAllFaces")
                    }
                }
                HStack(spacing: 6) {
                    ForEach(EditorMode.allCases) { item in
                        Button { select(item) } label: {
                            VStack(spacing: 6) {
                                Image(systemName: item.symbol).font(.system(size: 18, weight: .medium))
                                Text(item.rawValue).font(.caption.weight(.medium)).lineLimit(1).minimumScaleFactor(0.8)
                            }.foregroundStyle(mode == item ? Color.primary : Color.secondary)
                                .frame(maxWidth: .infinity).frame(height: 58)
                                .background(mode == item ? Color(uiColor: .tertiarySystemFill) : .clear, in: RoundedRectangle(cornerRadius: 14))
                        }.accessibilityIdentifier("mode_\(item.rawValue.lowercased())")
                    }
                }.padding(8).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
            }.padding(.horizontal, 14).padding(.bottom, 12)
        }
    }

    @ViewBuilder private func regionOverlays(mapper: ImageGeometryMapper) -> some View {
        if mode == .faces { ForEach(Array(faceRegions.enumerated()), id: \.offset) { index, rect in
            overlay(rect, mapper: mapper, selected: selectedFaces.contains(index), color: .cyan) {
                pushUndo(); if selectedFaces.contains(index) { selectedFaces.remove(index) } else { selectedFaces.insert(index) }; rerender()
            }
        } }
        if mode == .plate {
            ForEach(Array(plateSuggestions.enumerated()), id: \.offset) { _, rect in
                overlay(rect, mapper: mapper, selected: regions.contains(rect), color: .orange) { pushUndo(); regions = regions.contains(rect) ? regions.filter { $0 != rect } : regions + [rect]; rerender() }
            }
        }
        if mode == .manual || mode == .plate {
            ForEach(Array(regions.enumerated()), id: \.offset) { index, rect in
                if !(mode == .faces && faceRegions.contains(rect)) {
                    editableOverlay(rect, index: index, mapper: mapper)
                }
            }
        }
    }

    private func overlay(_ rect: CGRect, mapper: ImageGeometryMapper, selected: Bool, color: Color, action: @escaping () -> Void) -> some View {
        let frame = mapper.viewRect(fromNormalized: rect)
        return Button(action: action) {
            RoundedRectangle(cornerRadius: 14).fill(color.opacity(selected ? 0.38 : 0.12)).overlay(RoundedRectangle(cornerRadius: 14).stroke(color, style: StrokeStyle(lineWidth: selected ? 2.5 : 1.5, dash: selected ? [] : [5, 4])))
                .frame(width: frame.width, height: frame.height).overlay(alignment: .topTrailing) { if selected { Image(systemName: "checkmark.circle.fill").font(.title3).padding(3) } }
        }.buttonStyle(.plain).position(x: frame.midX, y: frame.midY).accessibilityLabel(selected ? "Blurred region" : "Select region to blur")
    }

    private func editableOverlay(_ rect: CGRect, index: Int, mapper: ImageGeometryMapper) -> some View {
        let frame = mapper.viewRect(fromNormalized: rect)
        return RoundedRectangle(cornerRadius: 12).fill(.cyan.opacity(0.28)).overlay(RoundedRectangle(cornerRadius: 12).stroke(.cyan, lineWidth: 2))
            .frame(width: frame.width, height: frame.height).position(x: frame.midX, y: frame.midY)
            .overlay {
                Circle().fill(.white).frame(width: 22, height: 22).overlay(Image(systemName: "arrow.up.left.and.arrow.down.right").font(.system(size: 9, weight: .bold)).foregroundStyle(.black)).position(x: frame.maxX, y: frame.maxY)
                    .gesture(DragGesture().onChanged { value in
                        let drag = CGRect(origin: value.startLocation, size: .zero)
                        _ = drag
                    }.onEnded { value in
                        pushUndo(); var resized = rect; resized.size.width = min(1 - resized.minX, max(0.04, rect.width + value.translation.width / mapper.displayedRect.width)); resized.size.height = min(1 - resized.minY, max(0.04, rect.height + value.translation.height / mapper.displayedRect.height)); regions[index] = resized; rerender()
                    })
            }
            .overlay(alignment: .topTrailing) {
                Button { pushUndo(); regions.remove(at: index); rerender() } label: { Image(systemName: "xmark.circle.fill").font(.title3).symbolRenderingMode(.palette).foregroundStyle(.white, .black.opacity(0.65)) }.offset(x: 10, y: -10).accessibilityLabel("Delete blur region")
            }
            .gesture(DragGesture().onEnded { value in pushUndo(); let dx = value.translation.width / mapper.displayedRect.width, dy = value.translation.height / mapper.displayedRect.height; regions[index].origin.x = min(max(0, rect.minX + dx), 1 - rect.width); regions[index].origin.y = min(max(0, rect.minY + dy), 1 - rect.height); rerender() })
    }

    private func manualGesture(mapper: ImageGeometryMapper) -> some Gesture {
        DragGesture(minimumDistance: 4).onChanged { value in
            guard mode == .manual || mode == .plate, !showingOriginal else { return }
            guard let point = mapper.normalizedPoint(fromView: value.startLocation) else { return }
            if dragStart == nil { dragStart = point }
            let start = dragStart ?? point
            let end = mapper.normalizedPoint(fromView: value.location) ?? point
            pendingRegion = CGRect(x: min(start.x, end.x), y: min(start.y, end.y), width: max(abs(start.x - end.x), 0.035), height: max(abs(start.y - end.y), 0.035))
        }.onEnded { _ in
            if let pendingRegion { pushUndo(); regions.append(pendingRegion); rerender() }
            dragStart = nil; pendingRegion = nil
        }
    }

    private var modeHint: String {
        switch mode {
        case .background: "Subject stays clear. Hold photo to compare original."
        case .faces: faceRegions.isEmpty ? "No faces found. Try Manual selection instead." : "Tap any face to toggle blur. Hold photo to compare."
        case .plate: plateSuggestions.isEmpty ? "No likely plates found. Drag over one to select manually." : "Tap a suggested region, or drag to add one."
        case .manual: "Drag across anything you want to hide."
        case nil: "Choose what to hide."
        }
    }

    @MainActor private func load(_ item: PhotosPickerItem?) async {
        guard let item else { return }; working = true
        defer { working = false }
        do {
            guard let data = try await item.loadTransferable(type: Data.self), let image = UIImage(data: data), let normalized = BlurRenderer.normalizedImage(image) else { throw BlurError.unavailable }
            original = normalized; preview = normalized; mode = nil; regions = []; faceRegions = []; selectedFaces = []; undoStack = []
        } catch { errorMessage = "The photo couldn’t be loaded. Please try another one." }
    }

    private func select(_ newMode: EditorMode) {
        if mode == newMode { return }
        pushUndo(); mode = newMode
        switch newMode {
        case .background: runBackground()
        case .faces: runFaces()
        case .plate: runPlate()
        case .manual: rerender()
        }
    }

    private func runBackground() {
        guard let original else { return }; working = true
        Task.detached(priority: .userInitiated) {
            let result: Result<(image: UIImage, mask: CIImage), Error>
            do { result = .success(try await BlurRenderer.renderBackground(original, strength: strength)) } catch { result = .failure(error) }
            await MainActor.run {
                working = false
                switch result { case .success(let output): backgroundMask = output.mask; preview = output.image; case .failure: mode = .manual; errorMessage = "We couldn’t separate a clear subject. Select the area to blur manually." }
            }
        }
    }

    private func runFaces() {
        guard let original else { return }; working = true
        Task.detached(priority: .userInitiated) {
            let result: Result<[CGRect], Error>
            do { result = .success(try await BlurRenderer.detectFaces(in: original)) } catch { result = .failure(error) }
            await MainActor.run {
                working = false
                switch result { case .success(let faces): faceRegions = faces; selectedFaces = Set(faces.indices); rerender(); case .failure: errorMessage = "Face detection didn’t finish. Try Manual selection instead." }
            }
        }
    }

    private func runPlate() {
        guard let original else { return }; working = true
        Task.detached(priority: .userInitiated) {
            let result: Result<[CGRect], Error>
            do { result = .success(try await BlurRenderer.detectPlateSuggestions(in: original)) } catch { result = .failure(error) }
            await MainActor.run { working = false; if case .success(let boxes) = result { plateSuggestions = boxes } else { plateSuggestions = [] }; rerender() }
        }
    }

    private func toggleAllFaces() {
        pushUndo()
        selectedFaces = selectedFaces.count == faceRegions.count ? [] : Set(faceRegions.indices)
        rerender()
    }

    private func rerender() {
        guard let original else { return }
        let chosen: [CGRect]
        switch mode {
        case .faces: chosen = selectedFaces.compactMap { faceRegions.indices.contains($0) ? faceRegions[$0] : nil } + regions
        case .plate, .manual: chosen = regions
        case .background, .none: chosen = regions
        }
        if mode == .background {
            if let mask = backgroundMask {
                let capturedStrength = strength
                working = true
                Task.detached(priority: .userInitiated) {
                    let result = BlurRenderer.render(original, regions: [], strength: capturedStrength, personMask: mask)
                    await MainActor.run { working = false; if let result { preview = result } }
                }
            } else { runBackground() }
            return
        }
        let capturedStrength = strength
        working = true
        Task.detached(priority: .userInitiated) {
            let result = BlurRenderer.render(original, regions: chosen, strength: capturedStrength)
            await MainActor.run { working = false; if let result { preview = result } }
        }
    }

    private func pushUndo() {
        guard let mode else { return }
        undoStack.append(EditSnapshot(regions: regions, selectedFaces: selectedFaces, mode: mode))
        if undoStack.count > 30 { undoStack.removeFirst() }
    }

    private func undo() {
        guard let snapshot = undoStack.popLast() else { return }
        regions = snapshot.regions; selectedFaces = snapshot.selectedFaces; mode = snapshot.mode; rerender()
    }

    private func resetEdits() {
        guard original != nil else { return }; pushUndo(); mode = nil; regions = []; selectedFaces = []; preview = original
    }

    private func clearSession() {
        original = nil; preview = nil; backgroundMask = nil; mode = nil; regions = []; faceRegions = []; plateSuggestions = []; selectedFaces = []; undoStack = []; pickerItem = nil
    }

    private func prepareExport() {
        guard let preview, let data = preview.jpegData(compressionQuality: 0.96) else { errorMessage = "The edited image couldn’t be prepared."; return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("PhotoVeil-\(UUID().uuidString).jpg")
        do { try data.write(to: url, options: .atomic); exportURL = url; showingShare = true }
        catch { errorMessage = "The edited image couldn’t be exported." }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: items, applicationActivities: nil) }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
