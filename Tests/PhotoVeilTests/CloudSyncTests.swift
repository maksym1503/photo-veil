import XCTest
import CoreGraphics
import ImageIO
@testable import ImageGeometry

private actor CloudMock: VeilCloudGallery {
    var records: [CloudGalleryItem] = []
    var failUpload = true
    var failDelete = false
    var uploadIDs = Set<UUID>()
    var deleted = Set<UUID>()
    let image: Data
    init(image: Data) { self.image = image }
    func list(user: UUID) -> [CloudGalleryItem] { records }
    func setRecords(_ values: [CloudGalleryItem]) { records = values }
    func setFailDelete(_ value: Bool) { failDelete = value }
    func upload(_ item: CloudGalleryItem, processed: Data, thumbnail: Data) throws {
        uploadIDs.insert(item.id) // Stable path even if transfer was interrupted.
        if failUpload { failUpload = false; throw AccountFailure.unavailable }
        records.removeAll { $0.id == item.id }; records.append(item)
    }
    func download(_ item: CloudGalleryItem) -> Data { image }
    func delete(user: UUID, id: UUID) throws {
        if failDelete { throw AccountFailure.unavailable }
        deleted.insert(id); records.removeAll { $0.id == id }
    }
    func uploads() -> Set<UUID> { uploadIDs }
}
final class CloudSyncTests: XCTestCase {
    private func image() throws -> Data {
        let context = try XCTUnwrap(CGContext(data: nil, width: 64, height: 64, bitsPerComponent: 8, bytesPerRow: 256,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.setFillColor(CGColor(gray: 0.2, alpha: 1)); context.fill(CGRect(x: 0, y: 0, width: 64, height: 64))
        let data = NSMutableData()
        let writer = try XCTUnwrap(CGImageDestinationCreateWithData(data, "public.jpeg" as CFString, 1, nil))
        CGImageDestinationAddImage(writer, try XCTUnwrap(context.makeImage()), nil); XCTAssertTrue(CGImageDestinationFinalize(writer)); return data as Data
    }
    func testConsentOfflineRetryAndIdempotentUpload() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = try GalleryStore(root: root), user = UUID(), data = try image(), cloud = CloudMock(image: data)
        let item = try await store.save(processed: data, effect: "Blur")
        do { try await CloudSync.run(store: store, cloud: cloud, user: user); XCTFail() } catch {}
        let initial = await cloud.uploads(); XCTAssertTrue(initial.isEmpty)
        try await store.setSync(true, for: user)
        do { try await CloudSync.run(store: store, cloud: cloud, user: user); XCTFail() } catch {}
        let local = try await store.data(for: item.id); XCTAssertEqual(local, data)
        try await CloudSync.run(store: store, cloud: cloud, user: user)
        try await CloudSync.run(store: store, cloud: cloud, user: user)
        let ids = await cloud.uploads(); XCTAssertEqual(ids, [item.id])
        let saved = await store.items(); XCTAssertTrue(saved[0].uploaded)
        await cloud.setFailDelete(true); try await store.delete([item.id])
        do { try await CloudSync.run(store: store, cloud: cloud, user: user); XCTFail() } catch {}
        let pending = await store.tombstones(for: user); XCTAssertEqual(pending.count, 1)
        await cloud.setFailDelete(false); try await CloudSync.run(store: store, cloud: cloud, user: user)
        let done = await store.tombstones(for: user); XCTAssertTrue(done.isEmpty)
    }
    func testForeignMetadataAndStoragePathsAreRejectedBeforeDownload() throws {
        let a = UUID(), b = UUID(), id = UUID()
        let item = CloudGalleryItem(id: id, userID: a, createdAt: Date(), updatedAt: Date(), width: 64, height: 64, effect: "Redact",
            processedPath: CloudGalleryItem.path(user: b, item: id), thumbnailPath: CloudGalleryItem.path(user: a, item: id, thumbnail: true), deletedAt: nil)
        XCTAssertThrowsError(try item.validate(for: a)); XCTAssertThrowsError(try item.validate(for: b))
    }
    func testRemoteDeletionAndAnotherAccountNeverUploadForeignLocalCopies() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = try GalleryStore(root: root), a = UUID(), b = UUID(), data = try image(), cloud = CloudMock(image: data)
        let item = try await store.save(processed: data, effect: "Pixelate", cloudUserID: a, uploaded: true)
        try await store.setSync(true, for: b); try await CloudSync.run(store: store, cloud: cloud, user: b)
        let uploaded = await cloud.uploads(); XCTAssertTrue(uploaded.isEmpty)
        let record = CloudGalleryItem(id: item.id, userID: a, createdAt: item.createdAt, updatedAt: Date(), width: 64, height: 64, effect: item.effect,
            processedPath: CloudGalleryItem.path(user: a, item: item.id), thumbnailPath: CloudGalleryItem.path(user: a, item: item.id, thumbnail: true), deletedAt: Date())
        await cloud.setRecords([record]); try await store.setSync(true, for: a)
        try await CloudSync.run(store: store, cloud: cloud, user: a)
        let empty = await store.items(); XCTAssertTrue(empty.isEmpty)
    }
    func testExplicitCloudOnlyDeletionKeepsLocalCopyAcrossRelaunchAndSync() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = try GalleryStore(root: root), user = UUID(), data = try image(), cloud = CloudMock(image: data)
        let kept = try await store.save(processed: data, effect: "Blur", cloudUserID: user, uploaded: false)
        let removed = try await store.save(processed: data, effect: "Blur", cloudUserID: user, uploaded: true)
        // A different identity cannot mark this owner's item as retained.
        try await store.retainLocalCopyForCloudDeletion(removed.id, for: UUID())
        try await store.retainLocalCopyForCloudDeletion(kept.id, for: user)
        let records = [kept, removed].map { item in
            CloudGalleryItem(id: item.id, userID: user, createdAt: item.createdAt, updatedAt: Date(), width: 64, height: 64,
                effect: item.effect, processedPath: CloudGalleryItem.path(user: user, item: item.id),
                thumbnailPath: CloudGalleryItem.path(user: user, item: item.id, thumbnail: true), deletedAt: Date())
        }
        await cloud.setRecords(records)
        let reloaded = try GalleryStore(root: root)
        try await reloaded.setSync(true, for: user)
        try await CloudSync.run(store: reloaded, cloud: cloud, user: user)
        let items = await reloaded.items(); XCTAssertEqual(items.map(\.id), [kept.id])
        let saved = try await reloaded.data(for: kept.id); XCTAssertEqual(saved, data)
        let uploads = await cloud.uploads(); XCTAssertTrue(uploads.isEmpty)
    }

}
