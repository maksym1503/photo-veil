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
    static func save(_ data: Data) async throws { try await PhotoSavePolicy.save(data, using: SystemPhotoSaveAccess()) }
    static func message(for error: Error) -> String {
        switch error {
        case PhotoSaveError.denied: "Photos saving is disabled. You can allow it in iPhone Settings, or use Share or Save to Veil."
        case PhotoSaveError.restricted: "This iPhone restricts saving to Photos. Share and Save to Veil remain available."
        default: "The photo couldn’t be saved. Try again, or use Share or Save to Veil."
        }
    }
}

enum TemporaryPhoto {
    static var folder: URL { FileManager.default.temporaryDirectory.appendingPathComponent("VeilExports", isDirectory: true) }
    static func create(_ data: Data) throws -> URL {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true,
                                                attributes: [.protectionKey: FileProtectionType.complete])
        let url = folder.appendingPathComponent("Veil-\(UUID().uuidString).jpg")
        try data.write(to: url, options: [.atomic, .completeFileProtection]); return url
    }
    static func clearPreviousSession() { try? FileManager.default.removeItem(at: folder) }
}
