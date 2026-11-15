import XCTest
import CoreGraphics
import ImageIO
@testable import ImageGeometry

final class ReleaseReadinessTests: XCTestCase {
    private let privateMarker = "VEIL_SYNTHETIC_PRIVATE_684731"
    private func taggedPhoto(orientation: Int = 1) throws -> Data {
        let context = try XCTUnwrap(CGContext(data: nil, width: 160, height: 80, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue))
        for (rect, color) in [(CGRect(x: 0,y: 0,width: 80,height: 40), CGColor(red: 1,green: 0,blue: 0,alpha: 1)),
            (CGRect(x: 80,y: 0,width: 80,height: 40), CGColor(red: 0,green: 1,blue: 0,alpha: 1)),
            (CGRect(x: 0,y: 40,width: 80,height: 40), CGColor(red: 0,green: 0,blue: 1,alpha: 1)),
            (CGRect(x: 80,y: 40,width: 80,height: 40), CGColor(red: 1,green: 1,blue: 0,alpha: 1))] {
            context.setFillColor(color); context.fill(rect)
        }
        let metadata = CGImageMetadataCreateMutable()
        XCTAssertTrue(CGImageMetadataRegisterNamespaceForPrefix(metadata, "http://purl.org/dc/elements/1.1/" as CFString, "dc" as CFString, nil))
        XCTAssertTrue(CGImageMetadataSetValueWithPath(metadata, nil, "dc:description" as CFString, privateMarker as CFString))
        XCTAssertTrue(CGImageMetadataRegisterNamespaceForPrefix(metadata, "http://ns.adobe.com/xap/1.0/" as CFString, "xmp" as CFString, nil))
        XCTAssertTrue(CGImageMetadataSetValueWithPath(metadata, nil, "xmp:CreatorTool" as CFString, privateMarker as CFString))
        let bytes = NSMutableData()
        let destination = try XCTUnwrap(CGImageDestinationCreateWithData(bytes, "public.jpeg" as CFString, 1, nil))
        let properties: [CFString: Any] = [kCGImagePropertyOrientation: orientation,
            kCGImagePropertyGPSDictionary: [kCGImagePropertyGPSLatitude: 51.25, kCGImagePropertyGPSLatitudeRef: "N", kCGImagePropertyGPSLongitude: 21.5, kCGImagePropertyGPSLongitudeRef: "E"],
            kCGImagePropertyTIFFDictionary: [kCGImagePropertyTIFFMake: privateMarker, kCGImagePropertyTIFFModel: privateMarker, kCGImagePropertyTIFFArtist: privateMarker],
            kCGImagePropertyExifDictionary: [kCGImagePropertyExifDateTimeOriginal: "2020:01:02 03:04:05", kCGImagePropertyExifUserComment: privateMarker,
                kCGImagePropertyExifBodySerialNumber: privateMarker, kCGImagePropertyExifLensMake: privateMarker,
                kCGImagePropertyExifLensSerialNumber: privateMarker, kCGImagePropertyExifCameraOwnerName: privateMarker],
            kCGImagePropertyIPTCDictionary: [kCGImagePropertyIPTCCaptionAbstract: privateMarker],
            kCGImageDestinationEmbedThumbnail: true]
        CGImageDestinationAddImageAndMetadata(destination, try XCTUnwrap(context.makeImage()), metadata, properties as CFDictionary)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        var data = bytes as Data
        // A JPEG COM segment independently checks comments that ImageIO may not expose.
        let comment = Data(privateMarker.utf8), length = comment.count + 2
        data.insert(contentsOf: [0xFF,0xFE,UInt8(length >> 8),UInt8(length & 255)] + Array(comment), at: 2)
        // A deterministic JFXX RGB embedded preview, independent of codec choices.
        let preview: [UInt8] = [74,70,88,88,0,0x13,1,1,255,0,0]
        data.insert(contentsOf: [0xFF,0xE0,0,UInt8(preview.count+2)] + preview, at: 2)
        return data
    }
    private func hasEmbeddedPreview(_ data: Data) throws -> Bool {
        let bytes = [UInt8](data)
        func require(_ valid: Bool) throws { if !valid { throw PhotoExport.Failure.invalidImage } }
        try require(bytes.count >= 4 && bytes[0] == 255 && bytes[1] == 216)
        var cursor = 2, found = false
        while cursor < bytes.count {
            try require(bytes[cursor] == 255); cursor += 1
            while cursor < bytes.count && bytes[cursor] == 255 { cursor += 1 }
            try require(cursor < bytes.count)
            let marker = bytes[cursor]; cursor += 1
            if marker == 0xDA || marker == 0xD9 { return found }
            try require(cursor+2 <= bytes.count)
            let length = Int(bytes[cursor])*256+Int(bytes[cursor+1])
            try require(length >= 2 && cursor+length <= bytes.count)
            let payload = Array(bytes[(cursor+2)..<(cursor+length)]); cursor += length
            if marker == 0xE0 && payload.starts(with: Array("JFIF\0".utf8)) {
                try require(payload.count >= 14)
                let width = Int(payload[12]), height = Int(payload[13])
                try require(payload.count >= 14+3*width*height)
                found = found || (width > 0 && height > 0)
            }
            if marker == 0xE0 && payload.starts(with: Array("JFXX\0".utf8)) {
                try require(payload.count >= 6); found = true
            }
            if marker == 0xE1 && payload.starts(with: Array("Exif\0\0".utf8)) {
                let tiff = Array(payload.dropFirst(6))
                try require(tiff.count >= 8)
                let little = tiff.starts(with: [73,73])
                try require(little || tiff.starts(with: [77,77]))
                func number(_ offset: Int,_ count: Int) throws -> Int {
                    try require(offset >= 0 && offset+count <= tiff.count)
                    let values = little ? Array(tiff[offset..<(offset+count)].reversed()) : Array(tiff[offset..<(offset+count)])
                    return values.reduce(0) { $0*256+Int($1) }
                }
                try require(try number(2,2) == 42)
                let ifd = try number(4,4), count = try number(ifd,2)
                let next = try number(ifd+2+12*count,4)
                if next != 0 {
                    let entries = try number(next,2)
                    try require(next+2+12*entries+4 <= tiff.count); found = true
                }
            }
        }
        throw PhotoExport.Failure.invalidImage
    }
    private func assertClean(_ data: Data, file: StaticString = #filePath, line: UInt = #line) throws {
        XCTAssertNil(data.range(of: Data(privateMarker.utf8)), file: file, line: line)
        let source = try XCTUnwrap(CGImageSourceCreateWithData(data as CFData, nil))
        let properties = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
        for key in [kCGImagePropertyGPSDictionary, kCGImagePropertyIPTCDictionary, kCGImagePropertyTIFFDictionary, kCGImagePropertyExifAuxDictionary] {
            XCTAssertNil(properties[key], "Unexpected source properties: \(key)", file: file, line: line)
        }
        // ImageIO generates structural EXIF for standard sRGB and pixel dimensions.
        // These are not source capture/device/descriptive tags.
        let exif = properties[kCGImagePropertyExifDictionary] as? [String: Any] ?? [:]
        let structural = Set(["ColorSpace", "PixelXDimension", "PixelYDimension"])
        XCTAssertTrue(Set(exif.keys).isSubset(of: structural), file: file, line: line)
        if let metadata = CGImageSourceCopyMetadataAtIndex(source, 0, nil) {
            let tags = CGImageMetadataCopyTags(metadata) as? [CGImageMetadataTag] ?? []
            for tag in tags {
                let name = try XCTUnwrap(CGImageMetadataTagCopyName(tag))
                XCTAssertTrue(structural.contains(name as String), "Unexpected metadata tag", file: file, line: line)
            }
        }
        XCTAssertEqual(CGImageSourceGetCount(source), 1, file: file, line: line)
        XCTAssertFalse(try hasEmbeddedPreview(data), "Embedded preview must not survive", file: file, line: line)
    }
    private func corners(_ data: Data) throws -> [Int] {
        let source = try XCTUnwrap(CGImageSourceCreateWithData(data as CFData, nil))
        let image = try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
        let context = try XCTUnwrap(CGContext(data: nil, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: image.width * 4,
            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue))
        context.draw(image, in: CGRect(x: 0,y: 0,width: image.width,height: image.height))
        let bytes = try XCTUnwrap(context.data).assumingMemoryBound(to: UInt8.self)
        return [(1,1),(3,1),(1,3),(3,3)].map { x,y in
            let i = ((image.height*y/4)*image.width + image.width*x/4)*4
            // Distinguishable red/green/blue/yellow quadrants tolerate JPEG compression.
            return (bytes[i] > 128 ? 4 : 0) + (bytes[i+1] > 128 ? 2 : 0) + (bytes[i+2] > 128 ? 1 : 0)
        }
    }
    func testKeepPolicyBytesReachPhotosAndTemporaryShareDestinations() async throws {
        let photo = try PhotoExport.processing(taggedPhoto(), policy: .keep)
        let access = MetadataDestinationCapture()
        try await PhotoSavePolicy.save(photo.data, using: access)
        let storage = TemporaryExportStorage(root: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString), sessionID: UUID())
        defer { try? FileManager.default.removeItem(at: storage.root) }
        let url = try storage.create(photo.data)
        try assertRetainedMetadata(try Data(contentsOf: url))
        let writes = await access.writes
        XCTAssertEqual(writes, [photo.data])
        try assertRetainedMetadata(writes[0])
    }

    func testSourceMetadataRemovedFromPixelOnlyJPEG() throws {
        let source = try taggedPhoto(), original = source
        let reader = try XCTUnwrap(CGImageSourceCreateWithData(source as CFData, nil))
        let properties = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(reader, 0, nil) as? [CFString: Any])
        XCTAssertNotNil(properties[kCGImagePropertyGPSDictionary]); XCTAssertNotNil(properties[kCGImagePropertyExifDictionary])
        XCTAssertNotNil(properties[kCGImagePropertyIPTCDictionary]); XCTAssertNotNil(CGImageSourceCopyMetadataAtIndex(reader, 0, nil))
        XCTAssertEqual((properties[kCGImagePropertyTIFFDictionary] as? [String:Any])?[kCGImagePropertyTIFFMake as String] as? String,privateMarker)
        XCTAssertEqual((properties[kCGImagePropertyExifDictionary] as? [String:Any])?[kCGImagePropertyExifDateTimeOriginal as String] as? String,"2020:01:02 03:04:05")
        let tags = CGImageMetadataCopyTags(try XCTUnwrap(CGImageSourceCopyMetadataAtIndex(reader,0,nil))) as? [CGImageMetadataTag] ?? []
        XCTAssertTrue(tags.contains { CGImageMetadataTagCopyName($0).map { $0 as String } == "description" }, "Fixture must carry XMP description")
        XCTAssertNotNil(source.range(of: Data(privateMarker.utf8)))
        XCTAssertTrue(try hasEmbeddedPreview(source), "Fixture must include embedded preview")
        let photo = try PhotoExport.processing(source)
        try assertClean(photo.data); XCTAssertEqual(photo.width,160); XCTAssertEqual(photo.height,80)
        XCTAssertEqual(try corners(photo.data), try corners(source)); XCTAssertEqual(source, original)
        XCTAssertFalse(try SourcePhotoMetadata.capture(photo.data).hasSupportedFields)
    }
    private func assertRetainedMetadata(_ data: Data, file: StaticString = #filePath, line: UInt = #line) throws {
        let source = try XCTUnwrap(CGImageSourceCreateWithData(data as CFData, nil), file: file, line: line)
        let props = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any], file: file, line: line)
        let tiff = props[kCGImagePropertyTIFFDictionary] as? [CFString: Any] ?? [:]
        let exif = props[kCGImagePropertyExifDictionary] as? [CFString: Any] ?? [:]
        let gps = props[kCGImagePropertyGPSDictionary] as? [CFString: Any] ?? [:]
        let iptc = props[kCGImagePropertyIPTCDictionary] as? [CFString: Any] ?? [:]
        XCTAssertEqual(tiff[kCGImagePropertyTIFFMake] as? String, privateMarker, file: file, line: line)
        XCTAssertEqual(exif[kCGImagePropertyExifDateTimeOriginal] as? String, "2020:01:02 03:04:05", file: file, line: line)
        XCTAssertEqual(gps[kCGImagePropertyGPSLatitude] as? Double, 51.25, file: file, line: line)
        XCTAssertEqual(iptc[kCGImagePropertyIPTCCaptionAbstract] as? String, privateMarker, file: file, line: line)
        XCTAssertEqual(exif[kCGImagePropertyExifUserComment] as? String, privateMarker, file: file, line: line)
        XCTAssertEqual(exif[kCGImagePropertyExifBodySerialNumber] as? String, privateMarker, file: file, line: line)
        XCTAssertEqual(exif[kCGImagePropertyExifLensMake] as? String, privateMarker, file: file, line: line)
        XCTAssertEqual(exif[kCGImagePropertyExifLensSerialNumber] as? String, privateMarker, file: file, line: line)
        XCTAssertEqual(exif[kCGImagePropertyExifCameraOwnerName] as? String, privateMarker, file: file, line: line)
        XCTAssertEqual(tiff[kCGImagePropertyTIFFOrientation] as? Int, 1, file: file, line: line)
        XCTAssertEqual(exif[kCGImagePropertyExifPixelXDimension] as? Int, props[kCGImagePropertyPixelWidth] as? Int, file: file, line: line)
        XCTAssertEqual(exif[kCGImagePropertyExifPixelYDimension] as? Int, props[kCGImagePropertyPixelHeight] as? Int, file: file, line: line)
        let metadata = try XCTUnwrap(CGImageSourceCopyMetadataAtIndex(source, 0, nil), file: file, line: line)
        let tags = CGImageMetadataCopyTags(metadata) as? [CGImageMetadataTag] ?? []
        XCTAssertTrue(tags.contains { CGImageMetadataTagCopyName($0).map { $0 as String } == "description" }, file: file, line: line)
        XCTAssertFalse(tags.contains { CGImageMetadataTagCopyName($0).map { $0 as String } == "CreatorTool" }, file: file, line: line)
        XCTAssertFalse(try hasEmbeddedPreview(data), file: file, line: line)
    }

    func testPhotoExportKeepRetainsAllowlistedFieldsAndRemoveRemainsDefault() throws {
        let source = try taggedPhoto(orientation: 6)
        let original = source
        let keep = try PhotoExport.processing(source, policy: .keep)
        XCTAssertEqual(keep.metadataPolicy, .keep)
        XCTAssertEqual(keep.width, 80); XCTAssertEqual(keep.height, 160)
        try assertRetainedMetadata(keep.data)
        XCTAssertEqual(try corners(keep.data), [2, 0, 3, 1].map { try! corners(source)[$0] })
        let remove = try PhotoExport.processing(source)
        XCTAssertEqual(remove.metadataPolicy, .remove)
        try assertClean(remove.data)
        XCTAssertEqual(source, original, "Neither policy mutates source bytes")
    }

    func testMetadataRemovalNormalizesAllEightOrientations() throws {
        let base = try corners(taggedPhoto())
        let mappings = [[0,1,2,3],[1,0,3,2],[3,2,1,0],[2,3,0,1],[0,2,1,3],[2,0,3,1],[3,1,2,0],[1,3,0,2]]
        for orientation in 1...8 {
            let source = try taggedPhoto(orientation: orientation)
            let remove = try PhotoExport.processing(source, policy: .remove)
            let keep = try PhotoExport.processing(source, policy: .keep)
            for photo in [remove, keep] {
                XCTAssertEqual(photo.width,orientation > 4 ? 80 : 160); XCTAssertEqual(photo.height,orientation > 4 ? 160 : 80)
                XCTAssertEqual(try corners(photo.data), mappings[orientation-1].map { base[$0] }, "EXIF orientation \(orientation)")
                if photo.metadataPolicy == .keep { try assertRetainedMetadata(photo.data) } else { try assertClean(photo.data) }
            }
        }
    }
    func testGallerySanitizesImportsAndLegacyExportsWithoutRewritingHistory() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = try GalleryStore(root: root), tagged = try taggedPhoto(orientation: 6)
        let item = try await store.save(processed: tagged, effect: "Redact")
        XCTAssertEqual(item.width,80); XCTAssertEqual(item.height,160)
        let saved = try await store.data(for: item.id), thumb = try await store.data(for: item.id,thumbnail: true)
        try assertClean(saved); try assertClean(thumb)
        // Simulate a version-1 legacy file. New exports clean it without a migration.
        let file = root.appendingPathComponent(item.id.uuidString).appendingPathComponent("processed.jpg")
        try tagged.write(to: file)
        let reopened = try GalleryStore(root: root)
        let exported = try await reopened.exportPhoto(for: item.id)
        try assertClean(exported.data); XCTAssertEqual(try Data(contentsOf: file),tagged)
    }
    func testGalleryPersistsKeepPolicyAcrossRelaunchExportsAndThumbnail() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = try GalleryStore(root: root)
        let item = try await store.save(processed: taggedPhoto(orientation: 6), effect: "Blur", metadataPolicy: .keep)
        XCTAssertEqual(item.metadataPolicy, .keep)
        try assertRetainedMetadata(try await store.data(for: item.id))
        try assertRetainedMetadata(try await store.data(for: item.id, thumbnail: true))
        let reopened = try GalleryStore(root: root)
        let reopenedItems = await reopened.items()
        XCTAssertEqual(reopenedItems.first?.effectiveMetadataPolicy, .keep)
        try assertRetainedMetadata(try await reopened.exportPhoto(for: item.id).data)
        try assertRetainedMetadata(try await reopened.exportPhoto(for: item.id, thumbnail: true).data)
        // New remove-policy records remain pixel-only on re-export.
        let removeItem = try await reopened.save(processed: taggedPhoto(), effect: "Blur")
        XCTAssertEqual(removeItem.metadataPolicy, .remove)
        XCTAssertEqual(removeItem.effectiveMetadataPolicy, .remove)
        try assertClean(try await reopened.exportPhoto(for: removeItem.id).data)

        // Opening an earlier index with no policy treats it as `.remove`.
        let indexURL = root.appendingPathComponent("index.json")
        var indexJSON = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: indexURL)) as? [String: Any])
        var rows = try XCTUnwrap(indexJSON["items"] as? [[String: Any]])
        let rowIndex = try XCTUnwrap(rows.firstIndex { ($0["id"] as? String)?.lowercased() == item.id.uuidString.lowercased() })
        rows[rowIndex].removeValue(forKey: "metadataPolicy")
        indexJSON["items"] = rows
        try JSONSerialization.data(withJSONObject: indexJSON).write(to: indexURL)
        let oldIndex = try GalleryStore(root: root)
        let legacyRows = await oldIndex.items()
        let legacyItem = try XCTUnwrap(legacyRows.first { $0.id == item.id })
        XCTAssertNil(legacyItem.metadataPolicy)
        XCTAssertEqual(legacyItem.effectiveMetadataPolicy, .remove)
        let originalStored = try await oldIndex.data(for: item.id)
        try assertClean(try await oldIndex.exportPhoto(for: item.id).data)
        let afterExport = try await oldIndex.data(for: item.id)
        XCTAssertEqual(afterExport, originalStored)
    }

    func testCloudPolicyRoundTripLegacyDefaultAndDownloadPropagation() async throws {
        let user = UUID(), id = UUID(), now = Date()
        let keep = CloudGalleryItem(id: id, userID: user, createdAt: now, updatedAt: now, width: 80, height: 160,
            effect: "Blur", processedPath: CloudGalleryItem.path(user: user, item: id),
            thumbnailPath: CloudGalleryItem.path(user: user, item: id, thumbnail: true), deletedAt: nil, metadataPolicy: .keep)
        let encoded = try JSONEncoder().encode(keep)
        XCTAssertEqual(try JSONDecoder().decode(CloudGalleryItem.self, from: encoded).effectiveMetadataPolicy, .keep)
        let legacyObject = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(keep)) as? [String: Any])
        var unknownObject = legacyObject; unknownObject["metadata_policy"] = "preserve-everything"
        XCTAssertThrowsError(try JSONDecoder().decode(CloudGalleryItem.self, from: JSONSerialization.data(withJSONObject: unknownObject)))
        var withoutPolicy = legacyObject; withoutPolicy.removeValue(forKey: "metadata_policy")
        let legacy = try JSONDecoder().decode(CloudGalleryItem.self, from: JSONSerialization.data(withJSONObject: withoutPolicy))
        XCTAssertNil(legacy.metadataPolicy)
        XCTAssertEqual(legacy.effectiveMetadataPolicy, .remove)

        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = try GalleryStore(root: root), cloud = MetadataCloudCapture()
        await cloud.configure(download: try taggedPhoto(), records: [keep])
        try await store.setSync(true, for: user)
        try await CloudSync.run(store: store, cloud: cloud, user: user)
        let downloadedItems = await store.items()
        let downloaded = try XCTUnwrap(downloadedItems.first)
        XCTAssertEqual(downloaded.effectiveMetadataPolicy, .keep)
        try assertRetainedMetadata(try await store.data(for: downloaded.id))

        let uploadRoot = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: uploadRoot) }
        let uploadStore = try GalleryStore(root: uploadRoot), uploadCloud = MetadataCloudCapture()
        let local = try await uploadStore.save(processed: taggedPhoto(), effect: "Blur", metadataPolicy: .keep)
        try await uploadStore.setSync(true, for: user)
        try await CloudSync.run(store: uploadStore, cloud: uploadCloud, user: user)
        let uploadedRecords = await uploadCloud.capturedRecords()
        XCTAssertEqual(uploadedRecords.first?.effectiveMetadataPolicy, .keep)
        let uploadedImages = await uploadCloud.images
        XCTAssertEqual(uploadedImages.count, 2)
        try assertRetainedMetadata(uploadedImages[0])
        try assertRetainedMetadata(uploadedImages[1])
        let uploadedLocalItems = await uploadStore.items()
        XCTAssertEqual(uploadedLocalItems.first?.id, local.id)
    }

    func testCloudUploadCleansLegacyImageAndThumbnail() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = try GalleryStore(root: root), tagged = try taggedPhoto(), user = UUID()
        let item = try await store.save(processed: tagged,effect: "Blur")
        for name in ["processed.jpg","thumbnail.jpg"] { try tagged.write(to: root.appendingPathComponent(item.id.uuidString).appendingPathComponent(name)) }
        let cloud = MetadataCloudCapture()
        try await store.setSync(true,for: user); try await CloudSync.run(store: store,cloud: cloud,user: user)
        let uploads = await cloud.images
        XCTAssertEqual(uploads.count,2); for data in uploads { try assertClean(data) }
        let local = try await store.data(for: item.id); XCTAssertEqual(local,tagged)
    }
    func testMetadataRemovalFailsClosedOnInvalidPhoto() async throws {
        let valid = try taggedPhoto()
        let reader = try XCTUnwrap(CGImageSourceCreateWithData(valid as CFData, nil))
        let pixels = try XCTUnwrap(CGImageSourceCreateImageAtIndex(reader, 0, nil))
        XCTAssertThrowsError(try PhotoExport.encode(pixels, policy: .keep, metadata: nil))
        let clean = try PhotoExport.encode(pixels)
        let empty = try SourcePhotoMetadata.capture(clean.data)
        XCTAssertFalse(empty.hasSupportedFields)
        let emptyKeep = try PhotoExport.encode(pixels, policy: .keep, metadata: empty)
        XCTAssertEqual(emptyKeep.metadataPolicy, .keep)
        XCTAssertFalse(try SourcePhotoMetadata.capture(emptyKeep.data).hasSupportedFields)
        XCTAssertThrowsError(try PhotoExport.processing(Data([1,2,3])))
        XCTAssertThrowsError(try PhotoExport.processing(Data([1,2,3]), policy: .keep))
        XCTAssertThrowsError(try hasEmbeddedPreview(Data([255,216,255,225,255,255])))
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = try GalleryStore(root: root), user = UUID(), cloud = MetadataCloudCapture()
        do { try await store.save(processed: Data([1,2,3]),effect: "Blur"); XCTFail("Invalid input must not save") } catch {}
        let items = await store.items(); XCTAssertTrue(items.isEmpty)
        let item = try await store.save(processed: taggedPhoto(),effect: "Blur")
        try Data([1,2,3]).write(to: root.appendingPathComponent(item.id.uuidString).appendingPathComponent("processed.jpg"))
        try await store.setSync(true,for: user)
        do { try await CloudSync.run(store: store,cloud: cloud,user: user); XCTFail("Corrupt legacy bytes must not upload") } catch {}
        let uploads = await cloud.images; XCTAssertTrue(uploads.isEmpty)
    }

    func testCommerceRequiresExplicitValidConfiguration() throws {
        func parse(_ values: [String: Any]) throws -> CommerceConfiguration? {
            CommerceConfiguration.parse(try PropertyListSerialization.data(fromPropertyList: values, format: .xml, options: 0))
        }
        let valid: [String: Any] = ["PurchasesEnabled": true, "MonthlyProductID": "test.veil.monthly", "FreePhotoLimit": 1]
        XCTAssertNil(CommerceConfiguration.load(bundle: Bundle(for: Self.self)))
        XCTAssertNil(CommerceConfiguration.parse(Data("invalid".utf8)))
        XCTAssertEqual(try parse(valid)?.freePhotoLimit, 1)
        for field in valid.keys {
            var missing = valid; missing.removeValue(forKey: field)
            XCTAssertNil(try parse(missing))
        }
        for change: [String: Any] in [["PurchasesEnabled": 1], ["FreePhotoLimit": true], ["PurchasesEnabled": false], ["MonthlyProductID": " "], ["MonthlyProductID": "test id"], ["FreePhotoLimit": 0], ["FreePhotoLimit": -1], ["FreePhotoLimit": 11]] {
            XCTAssertNil(try parse(valid.merging(change) { _, new in new }))
        }
    }
    func testProposedAllowanceDoesNotDependOnGalleryOrRepeatDestinations() {
        XCTAssertEqual(ProposedPhotoAllowance.access(limit: 1, completedSessions: 0, alreadyExportedSession: false, subscribed: false), .freePhoto)
        XCTAssertEqual(ProposedPhotoAllowance.access(limit: 1, completedSessions: 1, alreadyExportedSession: false, subscribed: false), .subscriptionRequired)
        XCTAssertEqual(ProposedPhotoAllowance.access(limit: 1, completedSessions: 1, alreadyExportedSession: true, subscribed: false), .existingSession)
        XCTAssertEqual(ProposedPhotoAllowance.access(limit: 1, completedSessions: 100, alreadyExportedSession: false, subscribed: true), .subscriber)
    }
    func testPriorSessionCleanupCannotDeleteCurrentShare() throws {
        let temporary = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: temporary) }
        let root = temporary.appendingPathComponent("VeilExports")
        let old = TemporaryExportStorage(root: root, sessionID: UUID())
        let active = TemporaryExportStorage(root: root, sessionID: UUID())
        let oldFile = try old.create(Data([1]))
        let currentFile = try active.create(Data([2]))
        let legacyFile = temporary.appendingPathComponent("Veil-legacy.jpg")
        let unrelated = temporary.appendingPathComponent("other.jpg")
        try Data([3]).write(to: legacyFile); try Data([4]).write(to: unrelated)
        active.clearPreviousSessions()
        XCTAssertFalse(FileManager.default.fileExists(atPath: oldFile.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: legacyFile.path))
        XCTAssertEqual(try Data(contentsOf: currentFile), Data([2]))
        XCTAssertEqual(try Data(contentsOf: unrelated), Data([4]))
        // A second cleanup and an export created after cleanup are also safe.
        let nextFile = try active.create(Data([5]))
        active.clearPreviousSessions()
        XCTAssertEqual(try Data(contentsOf: currentFile), Data([2]))
        XCTAssertEqual(try Data(contentsOf: nextFile), Data([5]))
    }
    func testFailedSyncConsentRemainsOffUntilExplicitSuccessfulEnable() {
        let user = UUID()
        var gate = SyncConsentGate()
        XCTAssertTrue(gate.permitsRestoration(for: user))
        let off = gate.begin(user: user, enabled: false)
        XCTAssertFalse(gate.permitsRestoration(for: user))
        XCTAssertEqual(gate.complete(off, succeeded: false, currentUser: user), false)
        XCTAssertFalse(gate.permitsRestoration(for: user))
        gate.invalidate()
        XCTAssertFalse(gate.permitsRestoration(for: user))
        let failedEnable = gate.begin(user: user, enabled: true)
        XCTAssertEqual(gate.complete(failedEnable, succeeded: false, currentUser: user), false)
        XCTAssertFalse(gate.permitsRestoration(for: user))
        let enable = gate.begin(user: user, enabled: true)
        XCTAssertEqual(gate.complete(enable, succeeded: true, currentUser: user), true)
        XCTAssertTrue(gate.permitsRestoration(for: user))
    }
    func testObsoleteConsentAndOtherIdentityCannotEnableSynchronization() {
        let user = UUID(), other = UUID()
        var gate = SyncConsentGate()
        let enable = gate.begin(user: user, enabled: true)
        let off = gate.begin(user: user, enabled: false)
        XCTAssertNil(gate.complete(enable, succeeded: true, currentUser: user))
        XCTAssertFalse(gate.permitsRestoration(for: user))
        XCTAssertEqual(gate.complete(off, succeeded: true, currentUser: user), false)
        let wrongIdentity = gate.begin(user: user, enabled: true)
        XCTAssertNil(gate.complete(wrongIdentity, succeeded: true, currentUser: other))
        XCTAssertFalse(gate.permitsRestoration(for: user))
        XCTAssertTrue(gate.permitsRestoration(for: other))
        gate.invalidate()
        XCTAssertNil(gate.complete(wrongIdentity, succeeded: true, currentUser: user))
    }

    @MainActor func testSuspendedRestoreCannotReplaceNewerSignInOrSignOut() async throws {
        for signOut in [false, true] {
            let auth = SuspendedRestoreAuthentication()
            let session = AccountSession(auth: auth)
            try await session.google()
            let restore = Task { try await session.restore() }
            await auth.waitForRestore()
            if signOut { try await session.signOut() }
            else { try await session.google() }
            let expected = session.identity
            await auth.finishRestore()
            try await restore.value
            XCTAssertEqual(session.identity, expected)
            if signOut { XCTAssertNil(session.identity) }
            else { XCTAssertEqual(session.identity?.provider, "google") }
        }
    }

}


private actor SuspendedRestoreAuthentication: VeilAuthentication {
    private var continuation: CheckedContinuation<VeilIdentity?, Never>?
    private var started: CheckedContinuation<Void, Never>?
    func restore() async -> VeilIdentity? {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            started?.resume(); started = nil
        }
    }
    func waitForRestore() async {
        if continuation != nil { return }
        await withCheckedContinuation { started = $0 }
    }
    func finishRestore() {
        continuation?.resume(returning: VeilIdentity(id: UUID(), provider: "apple", displayName: nil))
        continuation = nil
    }
    func signInGoogle() -> VeilIdentity { VeilIdentity(id: UUID(), provider: "google", displayName: nil) }
    func signInApple(_ proof: AppleIdentityProof) -> VeilIdentity { VeilIdentity(id: UUID(), provider: "apple", displayName: nil) }
    func signOut() {}
    func deleteAccount() {}
}

private actor MetadataDestinationCapture: PhotoSaveAccess {
    var writes: [Data] = []
    func status() -> PhotoSavePermission { .authorized }
    func requestAddOnly() -> PhotoSavePermission { .authorized }
    func write(_ data: Data) { writes.append(data) }
}

private actor MetadataCloudCapture: VeilCloudGallery {
    var images: [Data] = []
    private var records: [CloudGalleryItem] = []
    private var downloadData: Data?
    func configure(download: Data?, records: [CloudGalleryItem] = []) { downloadData = download; self.records = records }
    func list(user: UUID) -> [CloudGalleryItem] { records }
    func upload(_ item: CloudGalleryItem, processed: Data, thumbnail: Data) { images += [processed,thumbnail]; records.append(item) }
    func download(_ item: CloudGalleryItem) throws -> Data {
        guard let downloadData else { throw AccountFailure.unavailable }
        return downloadData
    }
    func delete(user: UUID,id: UUID) {}
    func capturedRecords() -> [CloudGalleryItem] { records }
}
