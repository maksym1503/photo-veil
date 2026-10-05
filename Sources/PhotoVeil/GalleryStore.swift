import Foundation
import ImageIO
import CoreGraphics

struct GalleryItem: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let createdAt: Date
    var updatedAt: Date
    let width: Int
    let height: Int
    let effect: String
    let byteCount: Int
    var cloudUserID: UUID?
    var uploaded: Bool
    // Optional for backward-compatible decoding of earlier version-1 local indexes.
    var retainsLocalAfterCloudDeletion: Bool? = nil
}

struct GalleryDeletion: Codable, Equatable, Sendable {
    let id: UUID
    let userID: UUID
}

/// One serialized owner for protected files and versioned metadata. Never receives an original image.
actor GalleryStore {
    struct Index: Codable {
        var version = 1
        var items: [GalleryItem] = []
        var deletions: [GalleryDeletion] = []
        var syncUsers: [UUID] = []
    }
    enum StoreError: Error { case unsupportedVersion, invalidImage, missingItem }
    let root: URL
    private var index: Index

    init(root: URL) throws {
        self.root = root
        try Self.directory(root)
        let file = root.appendingPathComponent("index.json")
        if FileManager.default.fileExists(atPath: file.path) {
            index = try JSONDecoder().decode(Index.self, from: Data(contentsOf: file))
            guard index.version == 1 else { throw StoreError.unsupportedVersion }
        } else { index = Index() }
        // Crash recovery: clean files whose metadata was never committed or already deleted.
        let retained = Set(index.items.map { $0.id.uuidString })
        for url in try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
        where url.lastPathComponent != "index.json" && !retained.contains(url.lastPathComponent) {
            try FileManager.default.removeItem(at: url)
        }
    }

    static func defaultRoot() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Veil/History", isDirectory: true)
    }
    func items() -> [GalleryItem] { index.items.sorted { $0.createdAt > $1.createdAt } }
    func tombstones(for user: UUID) -> [GalleryDeletion] { index.deletions.filter { $0.userID == user } }
    func syncEnabled(for user: UUID) -> Bool { index.syncUsers.contains(user) }
    func setSync(_ enabled: Bool, for user: UUID) throws {
        var next = index
        next.syncUsers.removeAll { $0 == user }
        if enabled { next.syncUsers.append(user) }
        try persist(next)
    }

    @discardableResult func save(processed data: Data, effect: String, id: UUID = UUID(), createdAt: Date = Date(),
                                cloudUserID: UUID? = nil, uploaded: Bool = false) throws -> GalleryItem {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
              let thumb = CGImageSourceCreateThumbnailAtIndex(source, 0, [kCGImageSourceCreateThumbnailFromImageAlways: true,
                  kCGImageSourceThumbnailMaxPixelSize: 384, kCGImageSourceCreateThumbnailWithTransform: true] as CFDictionary)
        else { throw StoreError.invalidImage }
        let thumbData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(thumbData, "public.jpeg" as CFString, 1, nil) else { throw StoreError.invalidImage }
        CGImageDestinationAddImage(destination, thumb, [kCGImageDestinationLossyCompressionQuality: 0.8] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw StoreError.invalidImage }
        if let existing = index.items.first(where: { $0.id == id }) { return existing }
        let folder = root.appendingPathComponent(id.uuidString, isDirectory: true)
        try Self.directory(folder)
        do {
            try Self.write(data, to: folder.appendingPathComponent("processed.jpg"))
            try Self.write(thumbData as Data, to: folder.appendingPathComponent("thumbnail.jpg"))
            let item = GalleryItem(id: id, createdAt: createdAt, updatedAt: createdAt, width: image.width, height: image.height,
                                   effect: effect, byteCount: data.count + thumbData.length, cloudUserID: cloudUserID, uploaded: uploaded)
            var next = index; next.items.append(item)
            try persist(next)
            return item
        } catch { try? FileManager.default.removeItem(at: folder); throw error }
    }

    func data(for id: UUID, thumbnail: Bool = false) throws -> Data {
        guard index.items.contains(where: { $0.id == id }) else { throw StoreError.missingItem }
        return try Data(contentsOf: root.appendingPathComponent(id.uuidString).appendingPathComponent(thumbnail ? "thumbnail.jpg" : "processed.jpg"))
    }
    func delete(_ ids: Set<UUID>, propagate: Bool = true) throws {
        var next = index
        for item in next.items where ids.contains(item.id) {
            if propagate, let owner = item.cloudUserID {
                let tombstone = GalleryDeletion(id: item.id, userID: owner)
                if !next.deletions.contains(tombstone) { next.deletions.append(tombstone) }
            }
        }
        next.items.removeAll { ids.contains($0.id) }; try persist(next)
        for id in ids {
            let folder = root.appendingPathComponent(id.uuidString)
            if FileManager.default.fileExists(atPath: folder.path) { try FileManager.default.removeItem(at: folder) }
        }
    }
    func bind(_ id: UUID, to user: UUID) throws {
        var next = index
        guard let i = next.items.firstIndex(where: { $0.id == id }), next.items[i].cloudUserID == nil || next.items[i].cloudUserID == user else { return }
        next.items[i].cloudUserID = user; try persist(next)
    }
    func retainLocalCopyForCloudDeletion(_ id: UUID, for user: UUID) throws {
        var next = index
        guard let i = next.items.firstIndex(where: { $0.id == id && $0.cloudUserID == user }) else { return }
        next.items[i].retainsLocalAfterCloudDeletion = true
        try persist(next)
    }
    func markUploaded(_ id: UUID, for user: UUID) throws {
        var next = index
        guard let i = next.items.firstIndex(where: { $0.id == id }), next.items[i].cloudUserID == user else { return }
        next.items[i].uploaded = true; try persist(next)
    }
    func acknowledge(_ deletion: GalleryDeletion) throws {
        var next = index; next.deletions.removeAll { $0 == deletion }; try persist(next)
    }
    func forgetAccount(_ user: UUID) throws {
        var next = index
        next.syncUsers.removeAll { $0 == user }; next.deletions.removeAll { $0.userID == user }
        // Keep the local copies owned by the deleted identity; never silently upload them to another account.
        try persist(next)
    }
    private func persist(_ next: Index) throws {
        try Self.write(JSONEncoder().encode(next), to: root.appendingPathComponent("index.json")); index = next
    }
    private static func directory(_ url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        #if os(iOS)
        try FileManager.default.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: url.path)
        #endif
        var value = url; var values = URLResourceValues(); values.isExcludedFromBackup = true
        try value.setResourceValues(values)
    }
    private static func write(_ data: Data, to url: URL) throws {
        #if os(iOS)
        try data.write(to: url, options: [.atomic, .completeFileProtection])
        #else
        try data.write(to: url, options: .atomic)
        #endif
    }
}
