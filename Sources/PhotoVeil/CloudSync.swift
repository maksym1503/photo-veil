import Foundation

struct CloudGalleryItem: Codable, Equatable, Sendable {
    let id: UUID
    let userID: UUID
    let createdAt: Date
    let updatedAt: Date
    let width: Int
    let height: Int
    let effect: String
    let processedPath: String
    let thumbnailPath: String
    let deletedAt: Date?
    enum CodingKeys: String, CodingKey {
        case id, width, height, effect
        case userID = "user_id", createdAt = "created_at", updatedAt = "updated_at"
        case processedPath = "processed_path", thumbnailPath = "thumbnail_path", deletedAt = "deleted_at"
    }
    static func path(user: UUID, item: UUID, thumbnail: Bool = false) -> String {
        "\(user.uuidString.lowercased())/\(item.uuidString.lowercased())/\(thumbnail ? "thumbnail" : "processed").jpg"
    }
    func validate(for user: UUID) throws {
        guard userID == user, processedPath == Self.path(user: user, item: id),
              thumbnailPath == Self.path(user: user, item: id, thumbnail: true), width > 0, height > 0 else { throw AccountFailure.invalidIdentity }
    }
}
protocol VeilCloudGallery: Sendable {
    func list(user: UUID) async throws -> [CloudGalleryItem]
    func upload(_ item: CloudGalleryItem, processed: Data, thumbnail: Data) async throws
    func download(_ item: CloudGalleryItem) async throws -> Data
    func delete(user: UUID, id: UUID) async throws
}

/// One sync task at a time in the UI coordinator. UUID paths/upserts make interrupted work retryable.
enum CloudSync {
    static func run(store: GalleryStore, cloud: any VeilCloudGallery, user: UUID) async throws {
        func check() async throws {
            try Task.checkCancellation()
            guard await store.syncEnabled(for: user) else { throw CancellationError() }
        }
        try await check()
        for deletion in await store.tombstones(for: user) {
            try await check(); try await cloud.delete(user: user, id: deletion.id)
            try await store.acknowledge(deletion)
        }
        let remote = try await cloud.list(user: user)
        for item in remote {
            try await check(); try item.validate(for: user)
            if item.deletedAt != nil {
                // Apply a remote tombstone only to a local copy bound to this identity.
                let local = await store.items().first { $0.id == item.id && $0.cloudUserID == user }
                if let local, local.retainsLocalAfterCloudDeletion != true { try await store.delete([item.id], propagate: false) }
            }
        }
        let deleted = Set(remote.filter { $0.deletedAt != nil }.map(\.id))
        for item in await store.items() where !item.uploaded && item.retainsLocalAfterCloudDeletion != true && (item.cloudUserID == nil || item.cloudUserID == user) && !deleted.contains(item.id) {
            try await check()
            try await store.bind(item.id, to: user)
            let processed = try await store.data(for: item.id), thumbnail = try await store.data(for: item.id, thumbnail: true)
            let record = CloudGalleryItem(id: item.id, userID: user, createdAt: item.createdAt, updatedAt: item.updatedAt,
                                          width: item.width, height: item.height, effect: item.effect,
                                          processedPath: CloudGalleryItem.path(user: user, item: item.id),
                                          thumbnailPath: CloudGalleryItem.path(user: user, item: item.id, thumbnail: true), deletedAt: nil)
            try await cloud.upload(record, processed: processed, thumbnail: thumbnail)
            try await check(); try await store.markUploaded(item.id, for: user)
        }
        let localIDs = Set(await store.items().map(\.id))
        let pendingIDs = Set(await store.tombstones(for: user).map(\.id))
        for item in remote where item.deletedAt == nil && !localIDs.contains(item.id) && !pendingIDs.contains(item.id) {
            try await check(); let data = try await cloud.download(item); try await check()
            try await store.save(processed: data, effect: item.effect, id: item.id, createdAt: item.createdAt, cloudUserID: user, uploaded: true)
        }
    }
}
