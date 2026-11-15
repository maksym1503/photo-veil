import SwiftUI

/// Session-only controls: custom content is committed to pixels, never preferences.
struct WatermarkControls: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let watermark: PhotoWatermark?
    let change: (PhotoWatermark?, Bool) -> Void
    @State private var editingText = false
    @State private var adjusting = false

    var body: some View {
        VStack(spacing: 8) {
            if let watermark {
                let textLayout = dynamicTypeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(spacing: 4)) : AnyLayout(HStackLayout(spacing: 12))
                textLayout {
                    Button { editingText = true } label: {
                        Label("Edit text", systemImage: "text.cursor")
                            .font(.subheadline.weight(.semibold)).fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }.accessibilityIdentifier("watermarkText")
                    Menu {
                        ForEach(WatermarkStyle.allCases) { style in
                            Button { var next = watermark; next.style = style; change(next, true) } label: {
                                Label(style.rawValue, systemImage: watermark.style == style ? "checkmark" : "textformat")
                            }
                        }
                    } label: {
                        Label(watermark.style.rawValue, systemImage: "textformat")
                            .font(.subheadline).fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }.accessibilityLabel("Watermark style").accessibilityValue(watermark.style.rawValue)
                        .accessibilityIdentifier("watermarkStyle")
                }
                HStack(spacing: 0) {
                    Menu {
                        ForEach(Array([( "Center", CGPoint(x: 0.5, y: 0.5)), ("Top", CGPoint(x: 0.5, y: 0.18)), ("Bottom", CGPoint(x: 0.5, y: 0.82))].enumerated()), id: \.offset) { _, placement in
                            Button(placement.0) { var next = watermark; next.center = placement.1; change(next, true) }
                        }
                    } label: { Image(systemName: "viewfinder").frame(maxWidth: .infinity, minHeight: 44) }
                        .accessibilityLabel("Watermark placement").accessibilityIdentifier("watermarkPlacement")
                    Button { var next = watermark; next.repeated.toggle(); change(next, true) } label: {
                        Image(systemName: "square.grid.3x3").frame(maxWidth: .infinity, minHeight: 44)
                    }.foregroundStyle(watermark.repeated ? Color.blue : Color.primary)
                        .accessibilityLabel("Repeat watermark").accessibilityValue(watermark.repeated ? "On" : "Off")
                        .accessibilityAddTraits(watermark.repeated ? .isSelected : [])
                        .accessibilityIdentifier("watermarkRepeat")
                    Button { adjusting = true } label: { Image(systemName: "slider.horizontal.3").frame(maxWidth: .infinity, minHeight: 44) }
                        .accessibilityLabel("Adjust watermark").accessibilityIdentifier("watermarkAdjust")
                    Button(role: .destructive) { change(nil, true) } label: {
                        Image(systemName: "trash").frame(maxWidth: .infinity, minHeight: 44)
                    }.accessibilityLabel("Remove watermark").accessibilityIdentifier("watermarkRemove")
                }.font(.system(size: 18))
                if !dynamicTypeSize.isAccessibilitySize {
                    Text("Drag on the photo to place your mark.")
                        .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
            } else {
                Button { change(PhotoWatermark(), true) } label: {
                    Text("Add watermark").font(.headline).frame(maxWidth: .infinity, minHeight: 44)
                }.modifier(VeilActionStyle(prominent: true)).frame(maxWidth: 280).accessibilityIdentifier("watermarkAdd")
                Text("Mark how your photo may be used.")
                    .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
        }.buttonStyle(.plain).padding(.horizontal, 16).padding(.vertical, 8)
            .sheet(isPresented: $editingText) {
                if let watermark { WatermarkTextEditor(initial: watermark) { change($0, true) } }
            }
            .sheet(isPresented: $adjusting) {
                if let watermark { WatermarkAdjustments(initial: watermark, change: change) }
            }
    }
}

private struct WatermarkTextEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: PhotoWatermark
    @FocusState private var focused: Bool
    let commit: (PhotoWatermark) -> Void
    init(initial: PhotoWatermark, commit: @escaping (PhotoWatermark) -> Void) {
        _draft = State(initialValue: initial); self.commit = commit
    }
    private var validText: Bool { draft.hasValidText && !draft.isBlank }

    var body: some View {
        NavigationStack {
            ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top, spacing: 8) {
                    TextField("Watermark text", text: $draft.text, axis: .vertical)
                        .font(.title3).lineLimit(1...3).focused($focused)
                        .autocorrectionDisabled().textInputAutocapitalization(.sentences)
                        .accessibilityIdentifier("watermarkTextField")
                        .onChange(of: draft.text) { previous, current in
                            if current.utf8.prefix(2_049).count > 2_048 { draft.text = previous }
                        }
                    Button { draft.text = ""; focused = true } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                            .frame(width: 44, height: 44)
                    }.accessibilityLabel("Clear watermark text").accessibilityIdentifier("watermarkClearText")
                }
                Menu("Use a suggestion", systemImage: "sparkles") {
                    ForEach(["For verification only", "For review only", "For rental application only", "For account setup only", "For verification only · \(Date.now.formatted(date: .numeric, time: .omitted))"], id: \.self) { text in
                        Button(text) { draft.text = text }
                    }
                }.frame(minHeight: 44).accessibilityIdentifier("watermarkSuggestions")
                Text("Visible in the saved photo. Avoid names or details you don’t want to share.")
                    .font(.caption).foregroundStyle(.secondary)
                if !validText { Text("Use 1–120 characters on one line.").font(.caption).foregroundStyle(.secondary) }
            }.padding(24)
            }
                .navigationTitle("Watermark text").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Apply") {
                        draft.text = draft.text.trimmingCharacters(in: .whitespacesAndNewlines)
                        commit(draft); dismiss()
                    }.disabled(!validText).accessibilityIdentifier("watermarkApplyText") }
                }
        }.presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
    }
}

private struct WatermarkAdjustments: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: PhotoWatermark
    let change: (PhotoWatermark?, Bool) -> Void
    init(initial: PhotoWatermark, change: @escaping (PhotoWatermark?, Bool) -> Void) {
        _draft = State(initialValue: initial); self.change = change
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    adjustment("Size", value: $draft.size, range: 0.025...0.12, id: "watermarkSize")
                    adjustment("Opacity", value: $draft.opacity, range: 0.15...1, id: "watermarkOpacity")
                    adjustment("Rotation", value: $draft.rotation, range: -90...90, id: "watermarkRotation")
                }.padding(24)
            }.navigationTitle("Adjust watermark").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { change(draft, true); dismiss() }.accessibilityIdentifier("watermarkAdjustDone") } }
        }.presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
            .onChange(of: draft) { _, value in change(value, false) }
            .onDisappear { change(draft, true) }
    }
    private func adjustment(_ title: String, value: Binding<CGFloat>, range: ClosedRange<CGFloat>, id: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.weight(.medium))
            Slider(value: value, in: range, onEditingChanged: { editing in if !editing { change(draft, true) } })
                .accessibilityLabel(title).accessibilityIdentifier(id)
        }
    }
}
