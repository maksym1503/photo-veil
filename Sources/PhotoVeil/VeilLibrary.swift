import SwiftUI

@MainActor final class VeilLibrary: ObservableObject {
    @Published private(set) var items: [GalleryItem] = []
    @Published var message: String?
    var didChange: (() -> Void)?
    private(set) var store: GalleryStore?
    private var opening: Task<GalleryStore, Error>?
    func open() async {
        guard store == nil else { return }
        if opening == nil {
            opening = Task.detached(priority: .utility) {
                var root = GalleryStore.defaultRoot()
                #if DEBUG
                let arguments = ProcessInfo.processInfo.arguments
                if arguments.contains("-veil-ui-testing") {
                    root = root.deletingLastPathComponent().appendingPathComponent("UITestHistory")
                    if let i = arguments.firstIndex(of: "-veil-test-storage-id"), arguments.indices.contains(i + 1),
                       let id = UUID(uuidString: arguments[i + 1]) {
                        root = root.appendingPathComponent(id.uuidString)
                    }
                    if arguments.contains("-veil-reset-history") { try? FileManager.default.removeItem(at: root) }
                }
                #endif
                return try GalleryStore(root: root)
            }
        }
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
