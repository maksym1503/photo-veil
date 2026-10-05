import SwiftUI

@MainActor final class VeilLibrary: ObservableObject {
    @Published private(set) var items: [GalleryItem] = []
    @Published var message: String?
    let store: GalleryStore?
    init() {
        do { store = try GalleryStore(root: GalleryStore.defaultRoot()) }
        catch { store = nil; message = "Private Gallery couldn’t be opened. Your existing files were left in place." }
    }
    func reload() async { if let store { items = await store.items() } }
    func save(_ data: Data, effect: String) async throws {
        guard let store else { throw GalleryStore.StoreError.missingItem }
        try await store.save(processed: data, effect: effect); await reload()
    }
    func delete(_ ids: Set<UUID>, localOnly: Bool = false) async {
        do { try await store?.delete(ids, propagate: !localOnly); await reload() }
        catch { message = "Some gallery files couldn’t be deleted. Try again after unlocking this iPhone." }
    }
}
