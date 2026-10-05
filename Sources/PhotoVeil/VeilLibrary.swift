import SwiftUI

@MainActor final class VeilLibrary: ObservableObject {
    @Published private(set) var items: [GalleryItem] = []
    @Published var message: String?
    var didChange: (() -> Void)?
    private(set) var store: GalleryStore?
    private var opening: Task<GalleryStore, Error>?
    func open() async {
        guard store == nil else { return }
        if opening == nil { opening = Task.detached(priority: .utility) { try GalleryStore(root: GalleryStore.defaultRoot()) } }
        do { store = try await opening?.value }
        catch { message = "Private Gallery couldn’t be opened. Your existing files were left in place." }
        opening = nil
    }
    func reload() async { if let store { items = await store.items() } }
    func save(_ data: Data, effect: String) async throws {
        guard let store else { throw GalleryStore.StoreError.missingItem }
        try await store.save(processed: data, effect: effect); await reload(); didChange?()
    }
    func delete(_ ids: Set<UUID>, localOnly: Bool = false) async {
        do { try await store?.delete(ids, propagate: !localOnly); await reload(); didChange?() }
        catch { message = "Some gallery files couldn’t be deleted. Try again after unlocking this iPhone." }
    }
}
