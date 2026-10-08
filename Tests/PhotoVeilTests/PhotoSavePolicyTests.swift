import XCTest
@testable import ImageGeometry

private actor PhotoAccessMock: PhotoSaveAccess {
    var permission: PhotoSavePermission
    let answer: PhotoSavePermission
    var requests = 0
    var writes = 0
    init(_ status: PhotoSavePermission, answer: PhotoSavePermission = .authorized) { permission = status; self.answer = answer }
    func status() -> PhotoSavePermission { permission }
    func requestAddOnly() -> PhotoSavePermission { requests += 1; permission = answer; return permission }
    func write(_ data: Data) { writes += 1 }
    func counts() -> [Int] { [requests, writes] }
}
final class PhotoSavePolicyTests: XCTestCase {
    func testRequestOnlyOnSaveAndOnlyOnce() async throws {
        let access = PhotoAccessMock(.notDetermined)
        let before = await access.counts(); XCTAssertEqual(before, [0, 0])
        try await PhotoSavePolicy.save(Data(), using: access); try await PhotoSavePolicy.save(Data(), using: access)
        let after = await access.counts(); XCTAssertEqual(after, [1, 2])
    }
    func testEveryPermissionState() async throws {
        for status in [PhotoSavePermission.authorized, .limited, .denied, .restricted, .unknown] {
            let access = PhotoAccessMock(status)
            do {
                try await PhotoSavePolicy.save(Data(), using: access)
                XCTAssertTrue(status == .authorized || status == .limited)
            } catch { XCTAssertTrue(status == .denied || status == .restricted || status == .unknown) }
            let counts = await access.counts(); XCTAssertEqual(counts[0], 0)
        }
        let denied = PhotoAccessMock(.notDetermined, answer: .denied)
        for _ in 0..<2 { do { try await PhotoSavePolicy.save(Data(), using: denied); XCTFail() } catch {} }
        let counts = await denied.counts(); XCTAssertEqual(counts, [1, 0])
    }
}
