import XCTest
import CoreGraphics
import ImageIO
@testable import ImageGeometry

final class GalleryStoreTests: XCTestCase {
    private func jpeg() throws -> Data {
        let context = try XCTUnwrap(CGContext(data: nil, width: 800, height: 600, bitsPerComponent: 8, bytesPerRow: 3200,
                                  space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.setFillColor(CGColor(gray: 0.4, alpha: 1)); context.fill(CGRect(x: 0, y: 0, width: 800, height: 600))
        let data = NSMutableData()
        let destination = try XCTUnwrap(CGImageDestinationCreateWithData(data, "public.jpeg" as CFString, 1, nil))
        CGImageDestinationAddImage(destination, try XCTUnwrap(context.makeImage()), nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination)); return data as Data
    }
    func testSaveReloadThumbnailAndDeletionWithoutAnAccount() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = try GalleryStore(root: root)
        let data = try jpeg()
        let item = try await store.save(processed: data, effect: "Redact")
        let restored = try GalleryStore(root: root)
        let items = await restored.items(); XCTAssertEqual(items, [item])
        let processed = try await restored.data(for: item.id); XCTAssertEqual(processed, data)
        let thumbnail = try await restored.data(for: item.id, thumbnail: true)
        let source = try XCTUnwrap(CGImageSourceCreateWithData(thumbnail as CFData, nil))
        let image = try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
        XCTAssertLessThanOrEqual(max(image.width, image.height), 384)
        try await restored.delete([item.id])
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent(item.id.uuidString).path))
        let empty = await restored.items(); XCTAssertTrue(empty.isEmpty)
    }
    func testOwnershipAndDeletionTombstonesSurviveRelaunch() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = try GalleryStore(root: root), userA = UUID(), userB = UUID()
        let item = try await store.save(processed: jpeg(), effect: "Blur")
        try await store.bind(item.id, to: userA); try await store.bind(item.id, to: userB)
        let items = await store.items(); XCTAssertEqual(items[0].cloudUserID, userA)
        try await store.delete([item.id])
        let restored = try GalleryStore(root: root)
        let pending = await restored.tombstones(for: userA); XCTAssertEqual(pending, [GalleryDeletion(id: item.id, userID: userA)])
        let other = await restored.tombstones(for: userB); XCTAssertTrue(other.isEmpty)
        try await restored.acknowledge(pending[0]); let done = await restored.tombstones(for: userA); XCTAssertTrue(done.isEmpty)
    }
    func testSyncConsentIsExplicitAndPerAccount() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = try GalleryStore(root: root), a = UUID(), b = UUID()
        let initial = await store.syncEnabled(for: a); XCTAssertFalse(initial)
        try await store.setSync(true, for: a)
        let restored = try GalleryStore(root: root)
        let yes = await restored.syncEnabled(for: a), no = await restored.syncEnabled(for: b)
        XCTAssertTrue(yes); XCTAssertFalse(no)
        try await restored.forgetAccount(a); let disabled = await restored.syncEnabled(for: a); XCTAssertFalse(disabled)
    }
    func testUnknownSchemaAndCorruptionNeverOverwriteHistory() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let file = root.appendingPathComponent("index.json"), original = Data("{\"version\":99,\"items\":[],\"deletions\":[],\"syncUsers\":[]}".utf8)
        try original.write(to: file)
        XCTAssertThrowsError(try GalleryStore(root: root)); XCTAssertEqual(try Data(contentsOf: file), original)
    }
}
