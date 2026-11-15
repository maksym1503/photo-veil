import SwiftUI

struct VeilGallery: View {
    @EnvironmentObject private var account: VeilAccount
    @EnvironmentObject private var library: VeilLibrary
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selected = Set<UUID>()
    @State private var selecting = false
    @State private var confirmsDelete = false
    var body: some View {
        NavigationStack {
            Group {
                if library.isLoading {
                    ProgressView("Opening Private Gallery…").frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if library.store == nil {
                    ScrollView {
                        VStack(spacing: 16) {
                            Image(systemName: "photo.stack")
                                .font(.system(size: 44, weight: .regular))
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                            Text("Private Gallery unavailable").font(.title2.weight(.semibold))
                            Text(library.message ?? "Your existing files were left in place. Try opening the gallery again.")
                                .font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
                            Button("Try again") { Task { await library.open(); await library.reload() } }
                                .buttonStyle(.borderedProminent)
                                .accessibilityIdentifier("retryGalleryOpen")
                        }
                        .frame(maxWidth: 380)
                        .frame(maxWidth: .infinity, minHeight: 320)
                        .padding(28)
                    }
                } else if library.items.isEmpty {
                    ScrollView {
                        VStack(spacing: 18) {
                            ZStack {
                                Circle().fill(Color(uiColor: .secondarySystemBackground))
                                    .frame(width: 108, height: 108)
                                Image(systemName: "photo.stack")
                                    .font(.system(size: 46, weight: .regular))
                                    .foregroundStyle(.tint)
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 25, weight: .semibold))
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .tint)
                                    .background(Circle().fill(Color(uiColor: .systemBackground)).padding(-4))
                                    .offset(x: 36, y: 34)
                            }
                            .accessibilityHidden(true)
                            Text("Private Gallery").font(.title2.weight(.semibold))
                            Text("Your finished photos live here. Choose Save to Veil after editing.")
                                .font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: 360)
                        .frame(maxWidth: .infinity, minHeight: 360)
                        .padding(28)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: dynamicTypeSize.isAccessibilitySize ? [GridItem(.flexible())] : [GridItem(.adaptive(minimum: 145))], spacing: 16) {
                            ForEach(library.items) { item in
                                if selecting {
                                    Button {
                                        withAnimation(reduceMotion ? nil : .snappy(duration: 0.2)) {
                                            if selected.contains(item.id) { selected.remove(item.id) } else { selected.insert(item.id) }
                                        }
                                    } label: {
                                        tile(item).overlay(alignment: .topTrailing) {
                                            Image(systemName: selected.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 20, weight: .medium)).padding(8).background(.regularMaterial, in: Circle())
                                                .scaleEffect(selected.contains(item.id) ? 1 : 0.94)
                                                .animation(reduceMotion ? nil : .spring(response: 0.22, dampingFraction: 0.72), value: selected.contains(item.id))
                                                .accessibilityHidden(true)
                                        }
                                    }.buttonStyle(.plain).accessibilityLabel("Select photo from \(item.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                        .accessibilityAddTraits(selected.contains(item.id) ? .isSelected : [])
                                } else {
                                    NavigationLink { GalleryPhoto(item: item) } label: { tile(item) }.buttonStyle(.plain)
                                }
                            }
                        }.padding(20)
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if selecting {
                    let layout = dynamicTypeSize.isAccessibilitySize
                        ? AnyLayout(VStackLayout(spacing: 4)) : AnyLayout(HStackLayout(spacing: 24))
                    layout {
                        galleryStatus
                        Button(role: .destructive) { confirmsDelete = true } label: {
                            Label("Delete", systemImage: "trash").frame(minHeight: 44)
                        }.buttonStyle(.plain).foregroundStyle(selected.isEmpty ? Color.secondary : Color.red)
                            .disabled(selected.isEmpty)
                            .accessibilityLabel("Delete selected")
                            .accessibilityIdentifier("galleryDeleteSelected")
                    }
                    .frame(maxWidth: .infinity).padding(.horizontal, 24).padding(.vertical, 8)
                    .background(.regularMaterial)
                }
            }
            .navigationTitle("Private Gallery")
            .navigationBarTitleDisplayMode(dynamicTypeSize.isAccessibilitySize ? .inline : .large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Close", systemImage: "xmark") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) { Button(selecting ? "Cancel" : "Select") { selecting.toggle(); selected = [] }
                    .disabled(library.items.isEmpty).accessibilityIdentifier("gallerySelect") }
                if !selecting {
                    if #available(iOS 26.0, *) {
                    ToolbarItem(placement: .bottomBar) { galleryStatus }
                        .sharedBackgroundVisibility(.hidden)
                    } else {
                    ToolbarItem(placement: .bottomBar) { galleryStatus }
                    }
                }
            }
            .sheet(isPresented: $confirmsDelete) {
                GalleryDeleteConfirmation(multiple: true,
                    includesCloud: library.items.contains { selected.contains($0.id) && $0.cloudUserID != nil }) {
                    Task {
                        if await library.delete(selected) { selected = []; selecting = false }
                    }
                }
            }
        }.task { await library.open(); await library.reload() }
        .sensoryFeedback(.selection, trigger: selected)
        .alert("Private Gallery", isPresented: Binding(get: { library.message != nil }, set: { if !$0 { library.message = nil } })) { Button("OK") { library.message = nil } } message: { Text(library.message ?? "") }
    }
    private var galleryStatus: some View {
        Text(selecting ? "\(selected.count) selected" : account.syncEnabled ? account.syncStatus : (library.items.count == 1 ? "1 photo" : "\(library.items.count) photos"))
            .font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: true, vertical: false)
            .accessibilityIdentifier("gallerySelectionStatus")
    }

    private func tile(_ item: GalleryItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            GalleryImage(id: item.id, thumbnail: true).aspectRatio(1, contentMode: .fit).clipped().clipShape(RoundedRectangle(cornerRadius: 18))
            Text(item.createdAt, style: .date).font(.caption).foregroundStyle(.secondary)
        }.accessibilityIdentifier("gallery_\(item.id)")
    }
}

struct GalleryImage: View {
    @EnvironmentObject private var subscriptions: VeilSubscriptionStore
    @EnvironmentObject private var exportAccess: VeilExportAccess
    private var premiumState: PremiumPreviewState {
        .resolve(completed: exportAccess.usage, limit: exportAccess.freeLimit, entitlement: subscriptions.previewEntitlement)
    }
    @EnvironmentObject private var library: VeilLibrary
    let id: UUID
    var thumbnail = false
    var allowsRetry = false
    @State private var image: UIImage?
    @State private var unavailable = false
    @State private var loading = true
    @State private var retryGeneration = 0
    var body: some View {
        Group {
            if let image {
                Image(uiImage: image).resizable().scaledToFit()
                    .accessibilityIdentifier("galleryProcessedPhoto")
                    .overlay {
                        PremiumPreviewLattice(marked: premiumState.marked, checking: premiumState.protectsPhoto)
                            .aspectRatio(image.size, contentMode: .fit).allowsHitTesting(false)
                    }
            }
            else if loading { ProgressView().frame(maxWidth: .infinity, minHeight: 100) }
            else if unavailable {
                VStack(spacing: 8) {
                    Label("Photo unavailable", systemImage: "photo.badge.exclamationmark")
                        .foregroundStyle(.secondary)
                    if allowsRetry {
                        Button("Try again") { retryGeneration += 1 }
                            .accessibilityIdentifier("retryGalleryPhoto")
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 100)
            }
        }
        .task(id: "\(id.uuidString)-\(thumbnail)-\(retryGeneration)") {
            let requestID = id
            let requestGeneration = retryGeneration
            image = nil
            unavailable = false
            loading = true
            defer {
                if !Task.isCancelled, requestID == id, requestGeneration == retryGeneration { loading = false }
            }
            if library.store == nil {
                await library.open()
                await library.reload()
            }
            guard !Task.isCancelled, requestID == id, requestGeneration == retryGeneration,
                  let store = library.store,
                  let data = try? await store.data(for: id, thumbnail: thumbnail),
                  let decoded = await Task.detached(priority: .userInitiated, operation: { UIImage(data: data) }).value else {
                if !Task.isCancelled, requestID == id, requestGeneration == retryGeneration { unavailable = true }
                return
            }
            if !Task.isCancelled, requestID == id, requestGeneration == retryGeneration { image = decoded }
        }
        .accessibilityLabel("Processed photo")
    }
}

private struct GalleryPhoto: View {
    @EnvironmentObject private var library: VeilLibrary
    @EnvironmentObject private var exportAccess: VeilExportAccess
    @EnvironmentObject private var subscriptions: VeilSubscriptionStore
    private var premiumState: PremiumPreviewState {
        .resolve(completed: exportAccess.usage, limit: exportAccess.freeLimit, entitlement: subscriptions.previewEntitlement)
    }
    @State private var showingPaywall = false
    @State private var shareLease: UUID?
    @Environment(\.dismiss) private var dismiss
    let item: GalleryItem
    @State private var shareItem: PhotoShareItem?
    @State private var confirmsDelete = false
    @State private var notice: String?
    @State private var actionInFlight = false
    @State private var preparationLifetime = ExportPreparationLifetime()
    var body: some View {
        ZStack {
            GalleryImage(id: item.id, allowsRetry: true).padding()
            if actionInFlight {
                ProgressView().controlSize(.large).padding(16)
                    .background(.regularMaterial, in: Circle())
                    .accessibilityLabel("Preparing photo")
            }
        }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 4) {
                PremiumPreviewNotice(state: premiumState) { showingPaywall = true }
                Label((item.metadataPolicy ?? .remove) == .remove ? "Exports remove source metadata" : "Exports keep supported metadata", systemImage: (item.metadataPolicy ?? .remove) == .remove ? "location.slash" : "info.circle")
                    .font(.caption).foregroundStyle(.secondary).padding(.vertical, 8)
                    .accessibilityIdentifier("galleryMetadataRemoval")
                }
            }
            .navigationTitle(item.createdAt.formatted(date: .abbreviated, time: .omitted))
            .onDisappear { preparationLifetime.invalidate() }
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button("Save to Photos", systemImage: "square.and.arrow.down") { Task { await saveToPhotos() } }
                        .disabled(actionInFlight || shareItem != nil)
                        .accessibilityIdentifier("gallerySaveToPhotos")
                    Spacer()
                    Button("Share", systemImage: "square.and.arrow.up") { Task { await share() } }
                        .disabled(actionInFlight || shareItem != nil)
                        .accessibilityIdentifier("galleryShare")
                    Spacer()
                    Button("Delete", systemImage: "trash", role: .destructive) { confirmsDelete = true }
                        .disabled(actionInFlight || shareItem != nil)
                }
            }
            .sheet(isPresented: $showingPaywall) { NavigationStack { VeilSubscriptionView() } }
            .sheet(item: $shareItem) { item in
                ShareSheet(items: [item.url]) { completed in
                    if let lease = shareLease {
                        if let warning = exportAccess.finish(lease, succeeded: completed) { notice = warning }
                        shareLease = nil
                    }
                }.onDisappear {
                    try? FileManager.default.removeItem(at: item.url)
                }
            }
            .sheet(isPresented: $confirmsDelete) {
                GalleryDeleteConfirmation(multiple: false, includesCloud: item.cloudUserID != nil) {
                    Task {
                        if await library.delete([item.id]) { dismiss() }
                        else { notice = library.message ?? "This photo couldn’t be deleted. Try again after unlocking this iPhone." }
                    }
                }
            }
            .alert("Private Gallery", isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })) { Button("OK") { notice = nil } } message: { Text(notice ?? "") }
    }
    private func share() async {
        guard !actionInFlight, shareItem == nil else { return }
        let request = preparationLifetime.generation
        actionInFlight = true
        defer { actionInFlight = false }
        do {
            guard let store = library.store else {
                notice = "This photo isn’t available on this iPhone. Return to Private Gallery and try again."
                return
            }
            guard let lease = try await exportAccess.begin() else {
                if preparationLifetime.contains(request) { showingPaywall = true }
                return
            }
            var handedToShare = false
            defer { if !handedToShare { exportAccess.finish(lease, succeeded: false) } }
            guard preparationLifetime.contains(request) else { return }
            let photo = try await store.exportPhoto(for: item.id)
            guard preparationLifetime.contains(request) else { return }
            let url = try TemporaryPhoto.create(photo)
            shareLease = lease; handedToShare = true
            shareItem = PhotoShareItem(url: url)
        } catch {
            if preparationLifetime.contains(request) {
                notice = error is ExportAllowance.Failure ? VeilExportAccess.message(for: error) : "This photo couldn’t be shared."
            }
        }
    }
    private func saveToPhotos() async {
        guard !actionInFlight, shareItem == nil else { return }
        let request = preparationLifetime.generation
        actionInFlight = true
        defer { actionInFlight = false }
        do {
            guard let store = library.store else {
                notice = "This photo isn’t available on this iPhone. Return to Private Gallery and try again."
                return
            }
            guard let lease = try await exportAccess.begin() else {
                if preparationLifetime.contains(request) { showingPaywall = true }
                return
            }
            defer { exportAccess.finish(lease, succeeded: false) }
            guard preparationLifetime.contains(request) else { return }
            let photo = try await store.exportPhoto(for: item.id)
            guard preparationLifetime.contains(request) else { return }
            try await PhotosSaver.save(photo)
            let warning = exportAccess.finish(lease, succeeded: true)
            notice = warning ?? (photo.metadataPolicy == .remove ? "Saved to Photos · source metadata removed" : "Saved to Photos · supported metadata kept")
        } catch { notice = error is ExportAllowance.Failure ? VeilExportAccess.message(for: error) : PhotosSaver.message(for: error) }
    }
}

/// A native sheet avoids confirmation-dialog popover anchoring on iOS 26.
private struct GalleryDeleteConfirmation: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var contentHeight: CGFloat = 190
    let multiple: Bool
    let includesCloud: Bool
    let delete: () -> Void
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text(multiple ? "Delete selected photos?" : "Delete this photo?")
                    .font(.headline).multilineTextAlignment(.center)
                Text(includesCloud
                     ? "Deletes from this iPhone. Synced cloud copies are deleted when sync resumes."
                     : "Removes \(multiple ? "these photos" : "this photo") from this iPhone.")
                    .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                Button(role: .destructive) { dismiss(); delete() } label: {
                    Text(multiple ? "Delete photos" : "Delete photo").frame(maxWidth: .infinity, minHeight: 44)
                }.buttonStyle(.bordered).tint(.red)
                Button(role: .cancel) { dismiss() } label: {
                    Text("Cancel").frame(maxWidth: .infinity, minHeight: 44)
                }.buttonStyle(.plain).foregroundStyle(.tint)
                    .accessibilityIdentifier("galleryDeleteCancel")
            }.padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 8)
                .background {
                    GeometryReader { geometry in
                        Color.clear.preference(key: GalleryConfirmationHeight.self, value: geometry.size.height)
                    }
                }
        }.onPreferenceChange(GalleryConfirmationHeight.self) { contentHeight = $0 }
        .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.height(max(180, contentHeight))])
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier("galleryDeleteConfirmation")
    }
}

private struct GalleryConfirmationHeight: PreferenceKey {
    static var defaultValue: CGFloat = 190
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
