import SwiftUI

struct VeilGallery: View {
    @EnvironmentObject private var account: VeilAccount
    @EnvironmentObject private var library: VeilLibrary
    @Environment(\.dismiss) private var dismiss
    @State private var selected = Set<UUID>()
    @State private var selecting = false
    @State private var confirmsDelete = false
    var body: some View {
        NavigationStack {
            Group {
                if library.items.isEmpty {
                    ContentUnavailableView("Private Gallery", systemImage: "photo.stack", description: Text("Save a finished photo to Veil. Stored on this iPhone."))
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 145))], spacing: 16) {
                            ForEach(library.items) { item in
                                if selecting {
                                    Button { if selected.contains(item.id) { selected.remove(item.id) } else { selected.insert(item.id) } } label: {
                                        tile(item).overlay(alignment: .topTrailing) {
                                            Image(systemName: selected.contains(item.id) ? "checkmark.circle.fill" : "circle").padding(8).background(.regularMaterial, in: Circle())
                                        }
                                    }.buttonStyle(.plain).accessibilityLabel("Select photo from \(item.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                } else {
                                    NavigationLink { GalleryPhoto(item: item) } label: { tile(item) }.buttonStyle(.plain)
                                }
                            }
                        }.padding(20)
                    }
                }
            }
            .navigationTitle("Private Gallery")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Close", systemImage: "xmark") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) { Button(selecting ? "Cancel" : "Select") { selecting.toggle(); selected = [] }
                    .disabled(library.items.isEmpty).accessibilityIdentifier("gallerySelect") }
                ToolbarItemGroup(placement: .bottomBar) {
                    Text(selecting ? "\(selected.count) selected" : account.syncEnabled ? account.syncStatus : "Stored on this iPhone")
                        .font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: true, vertical: false)
                        .accessibilityIdentifier("gallerySelectionStatus")
                    Spacer()
                    if selecting {
                        Button("Delete selected", systemImage: "trash", role: .destructive) { confirmsDelete = true }
                            .labelStyle(.iconOnly).tint(.red).disabled(selected.isEmpty)
                            .accessibilityIdentifier("galleryDeleteSelected")
                    }
                }
            }
            .confirmationDialog("Delete selected photos? Synced copies will also be deleted when sync runs.", isPresented: $confirmsDelete, titleVisibility: .visible) {
                Button("Delete photos", role: .destructive) { Task { await library.delete(selected); selected = []; selecting = false } }
            }
        }.task { await library.reload() }
        .alert("Private Gallery", isPresented: Binding(get: { library.message != nil }, set: { if !$0 { library.message = nil } })) { Button("OK") { library.message = nil } } message: { Text(library.message ?? "") }
    }
    private func tile(_ item: GalleryItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            GalleryImage(id: item.id, thumbnail: true).aspectRatio(1, contentMode: .fit).clipped().clipShape(RoundedRectangle(cornerRadius: 18))
            Text(item.createdAt, style: .date).font(.caption).foregroundStyle(.secondary)
        }.accessibilityIdentifier("gallery_\(item.id)")
    }
}

struct GalleryImage: View {
    @EnvironmentObject private var library: VeilLibrary
    let id: UUID
    var thumbnail = false
    @State private var image: UIImage?
    @State private var unavailable = false
    var body: some View {
        Group {
            if let image { Image(uiImage: image).resizable().scaledToFit() }
            else if unavailable { Label("Photo unavailable", systemImage: "photo.badge.exclamationmark").foregroundStyle(.secondary).frame(minHeight: 100) }
            else { ProgressView().frame(maxWidth: .infinity, minHeight: 100) }
        }.task(id: id) {
            guard let data = try? await library.store?.data(for: id, thumbnail: thumbnail) else { unavailable = true; return }
            image = await Task.detached { UIImage(data: data) }.value
        }.accessibilityLabel("Processed photo")
    }
}

private struct GalleryPhoto: View {
    @EnvironmentObject private var library: VeilLibrary
    @Environment(\.dismiss) private var dismiss
    let item: GalleryItem
    @State private var shareItem: PhotoShareItem?
    @State private var confirmsDelete = false
    @State private var notice: String?
    var body: some View {
        GalleryImage(id: item.id).padding().navigationTitle(item.createdAt.formatted(date: .abbreviated, time: .omitted))
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button("Save to Photos", systemImage: "square.and.arrow.down") { Task { await saveToPhotos() } }.accessibilityIdentifier("gallerySaveToPhotos")
                    Spacer()
                    Button("Share", systemImage: "square.and.arrow.up") { Task { await share() } }.accessibilityIdentifier("galleryShare")
                    Spacer()
                    Button("Delete", systemImage: "trash", role: .destructive) { confirmsDelete = true }
                }
            }
            .sheet(item: $shareItem) { item in
                ShareSheet(items: [item.url]).onDisappear { try? FileManager.default.removeItem(at: item.url) }
            }
            .confirmationDialog("Delete this photo? Synced copies will also be deleted when sync runs.", isPresented: $confirmsDelete, titleVisibility: .visible) {
                Button("Delete photo", role: .destructive) { Task { await library.delete([item.id]); dismiss() } }
            }
            .alert("Private Gallery", isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })) { Button("OK") { notice = nil } } message: { Text(notice ?? "") }
    }
    private func share() async {
        do {
            guard let data = try await library.store?.data(for: item.id) else { return }
            shareItem = PhotoShareItem(url: try TemporaryPhoto.create(data))
        } catch { notice = "This photo couldn’t be shared." }
    }
    private func saveToPhotos() async {
        do {
            guard let data = try await library.store?.data(for: item.id) else { return }
            try await PhotosSaver.save(data); notice = "Saved to Photos"
        } catch { notice = PhotosSaver.message(for: error) }
    }
}
