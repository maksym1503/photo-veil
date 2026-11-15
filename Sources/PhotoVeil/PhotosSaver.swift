import Foundation
import Photos

struct SystemPhotoSaveAccess: PhotoSaveAccess {
    func status() async -> PhotoSavePermission { Self.map(PHPhotoLibrary.authorizationStatus(for: .addOnly)) }
    func requestAddOnly() async -> PhotoSavePermission { Self.map(await PHPhotoLibrary.requestAuthorization(for: .addOnly)) }
    func write(_ data: Data) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetCreationRequest.forAsset().addResource(with: .photo, data: data, options: nil)
        }
    }
    private static func map(_ status: PHAuthorizationStatus) -> PhotoSavePermission {
        switch status {
        case .notDetermined: .notDetermined
        case .authorized: .authorized
        case .limited: .limited
        case .denied: .denied
        case .restricted: .restricted
        @unknown default: .unknown
        }
    }
}
enum PhotosSaver {
    static func save(_ photo: PhotoExport) async throws { try await PhotoSavePolicy.save(photo.data, using: SystemPhotoSaveAccess()) }
    static func message(for error: Error) -> String {
        switch error {
        case PhotoSaveError.denied: "Photos saving is disabled. You can allow it in iPhone Settings, or use Share or Save to Veil."
        case PhotoSaveError.restricted: "This iPhone restricts saving to Photos. Share and Save to Veil remain available."
        default: "The photo couldn’t be saved. Try again, or use Share or Save to Veil."
        }
    }
}

enum TemporaryPhoto {
    private static let storage = TemporaryExportStorage(
        root: FileManager.default.temporaryDirectory.appendingPathComponent("VeilExports", isDirectory: true),
        sessionID: UUID())
    static var folder: URL { storage.folder }
    static func create(_ photo: PhotoExport) throws -> URL { try storage.create(photo.data) }
    static func clearPreviousSession() { storage.clearPreviousSessions() }
}

/// One presentation value prevents a sheet from opening before its URL is available.
struct PhotoShareItem: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}
