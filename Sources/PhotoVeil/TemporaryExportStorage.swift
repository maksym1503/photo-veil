import Foundation

/// One process owns one directory. Prior-session cleanup never deletes active exports.
struct TemporaryExportStorage: Sendable {
    let root: URL
    let sessionID: UUID
    var folder: URL { root.appendingPathComponent(sessionID.uuidString, isDirectory: true) }

    func create(_ data: Data) throws -> URL {
        #if os(iOS)
        let attributes: [FileAttributeKey: Any] = [.protectionKey: FileProtectionType.complete]
        let options: Data.WritingOptions = [.atomic, .completeFileProtection]
        #else
        let attributes: [FileAttributeKey: Any] = [:]
        let options: Data.WritingOptions = [.atomic]
        #endif
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: attributes)
        let url = folder.appendingPathComponent("Veil-\(UUID().uuidString).jpg")
        try data.write(to: url, options: options)
        return url
    }
    func clearPreviousSessions() {
        let files = (try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? []
        for file in files where file.lastPathComponent != sessionID.uuidString {
            // Only Veil's known session directories and legacy JPEG exports.
            if UUID(uuidString: file.lastPathComponent) != nil || (file.lastPathComponent.hasPrefix("Veil-") && file.pathExtension == "jpg") {
                try? FileManager.default.removeItem(at: file)
            }
        }
        let legacy = root.deletingLastPathComponent()
        for file in (try? FileManager.default.contentsOfDirectory(at: legacy, includingPropertiesForKeys: nil)) ?? []
        where file.lastPathComponent.hasPrefix("Veil-") && file.pathExtension == "jpg" {
            try? FileManager.default.removeItem(at: file)
        }
    }
}
