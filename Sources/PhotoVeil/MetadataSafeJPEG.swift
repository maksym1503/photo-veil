import Foundation
import CoreGraphics
import ImageIO

/// Controls whether supported descriptive metadata from the selected source is
/// included in an exported copy. Existing records without a value mean `.remove`.
enum PhotoMetadataPolicy: String, Codable, CaseIterable, Sendable {
    case remove
    case keep
}

/// Immutable, bounded metadata snapshot from the original selected photo.
/// It contains only allowlisted ImageIO fields and safe descriptive XMP fields,
/// never source pixels, previews, maker notes, or opaque source dictionaries.
struct SourcePhotoMetadata: Sendable {
    fileprivate let propertyList: Data
    fileprivate let xmp: Data?
    var hasSupportedFields: Bool {
        if let xmp { return !xmp.isEmpty }
        guard let decoded = try? PropertyListSerialization.propertyList(from: propertyList, options: [], format: nil),
              let values = decoded as? [String: Any] else { return false }
        return !values.isEmpty
    }

    static func capture(_ source: Data) throws -> Self {
        guard let reader = CGImageSourceCreateWithData(source as CFData, nil),
              CGImageSourceGetStatus(reader) == .statusComplete else { throw PhotoExport.Failure.invalidImage }
        let sourceProperties = CGImageSourceCopyPropertiesAtIndex(reader, 0, nil) as? [CFString: Any] ?? [:]
        let properties = Self.allowlistedProperties(sourceProperties)
        guard PropertyListSerialization.propertyList(properties, isValidFor: .binary),
              let data = try? PropertyListSerialization.data(fromPropertyList: properties, format: .binary, options: 0)
        else { throw PhotoExport.Failure.metadataUnavailable }
        return Self(propertyList: data, xmp: Self.safeXMP(CGImageSourceCopyMetadataAtIndex(reader, 0, nil)))
    }

    private init(propertyList: Data, xmp: Data?) { self.propertyList = propertyList; self.xmp = xmp }

    private static func allowlistedProperties(_ source: [CFString: Any]) -> [String: Any] {
        let groups: [(CFString, [CFString])] = [
            (kCGImagePropertyTIFFDictionary, [kCGImagePropertyTIFFMake, kCGImagePropertyTIFFModel,
                kCGImagePropertyTIFFSoftware, kCGImagePropertyTIFFDateTime, kCGImagePropertyTIFFArtist,
                kCGImagePropertyTIFFCopyright, kCGImagePropertyTIFFImageDescription]),
            (kCGImagePropertyExifDictionary, [kCGImagePropertyExifDateTimeOriginal, kCGImagePropertyExifDateTimeDigitized,
                kCGImagePropertyExifExposureTime, kCGImagePropertyExifFNumber, kCGImagePropertyExifExposureProgram,
                kCGImagePropertyExifISOSpeedRatings, kCGImagePropertyExifShutterSpeedValue,
                kCGImagePropertyExifApertureValue, kCGImagePropertyExifFocalLength, kCGImagePropertyExifLensMake,
                kCGImagePropertyExifLensModel, kCGImagePropertyExifLensSerialNumber,
                kCGImagePropertyExifCameraOwnerName, kCGImagePropertyExifUserComment,
                kCGImagePropertyExifBodySerialNumber, kCGImagePropertyExifFlash]),
            (kCGImagePropertyGPSDictionary, [kCGImagePropertyGPSLatitude, kCGImagePropertyGPSLatitudeRef,
                kCGImagePropertyGPSLongitude, kCGImagePropertyGPSLongitudeRef, kCGImagePropertyGPSAltitude,
                kCGImagePropertyGPSAltitudeRef, kCGImagePropertyGPSTimeStamp, kCGImagePropertyGPSDateStamp,
                kCGImagePropertyGPSImgDirection, kCGImagePropertyGPSImgDirectionRef]),
            (kCGImagePropertyIPTCDictionary, [kCGImagePropertyIPTCCaptionAbstract, kCGImagePropertyIPTCHeadline,
                kCGImagePropertyIPTCByline, kCGImagePropertyIPTCBylineTitle, kCGImagePropertyIPTCCopyrightNotice,
                kCGImagePropertyIPTCKeywords, kCGImagePropertyIPTCObjectName, kCGImagePropertyIPTCCity,
                kCGImagePropertyIPTCSubLocation, kCGImagePropertyIPTCProvinceState, kCGImagePropertyIPTCCountryPrimaryLocationName])
        ]
        var result: [String: Any] = [:]
        for (groupKey, allowedKeys) in groups {
            guard let values = source[groupKey] as? [CFString: Any] else { continue }
            let filtered = Dictionary(uniqueKeysWithValues: allowedKeys.compactMap { key in
                values[key].map { (key as String, $0) }
            })
            if !filtered.isEmpty { result[groupKey as String] = filtered }
        }
        return result
    }

    private static func safeXMP(_ metadata: CGImageMetadata?) -> Data? {
        guard let metadata else { return nil }
        let copy = CGImageMetadataCreateMutable()
        guard CGImageMetadataRegisterNamespaceForPrefix(copy, "http://purl.org/dc/elements/1.1/" as CFString, "dc" as CFString, nil) else { return nil }
        // Retain only simple descriptive Dublin Core strings. Structured source
        // trees and all other namespaces remain excluded.
        var copiedAny = false
        for path in ["dc:title", "dc:description", "dc:creator", "dc:rights"] {
            guard let value = CGImageMetadataCopyTagWithPath(metadata, nil, path as CFString),
                  let copiedValue = CGImageMetadataTagCopyValue(value) as? String else { continue }
            copiedAny = CGImageMetadataSetValueWithPath(copy, nil, path as CFString, copiedValue as CFString) || copiedAny
        }
        guard copiedAny else { return nil }
        return CGImageMetadataCreateXMPData(copy, nil) as Data?
    }

    fileprivate func destinationProperties(width: Int, height: Int) -> [CFString: Any]? {
        guard let decoded = try? PropertyListSerialization.propertyList(from: propertyList, options: [], format: nil),
              var properties = decoded as? [String: Any] else { return nil }
        var tiff = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any] ?? [:]
        tiff[kCGImagePropertyTIFFOrientation as String] = 1
        properties[kCGImagePropertyTIFFDictionary as String] = tiff
        var exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] ?? [:]
        exif[kCGImagePropertyExifPixelXDimension as String] = width
        exif[kCGImagePropertyExifPixelYDimension as String] = height
        properties[kCGImagePropertyExifDictionary as String] = exif
        properties[kCGImagePropertyPixelWidth as String] = width
        properties[kCGImagePropertyPixelHeight as String] = height
        return properties as NSDictionary as? [CFString: Any]
    }
}

/// A JPEG created from upright pixels. The type prevents raw source bytes from
/// crossing photo export boundaries accidentally.
struct PhotoExport: Sendable {
    let data: Data
    let width: Int
    let height: Int
    let metadataPolicy: PhotoMetadataPolicy
    private init(data: Data, width: Int, height: Int, metadataPolicy: PhotoMetadataPolicy) {
        self.data = data; self.width = width; self.height = height; self.metadataPolicy = metadataPolicy
    }
    enum Failure: Error { case invalidImage, encodingFailed, metadataUnavailable }

    static func encode(_ pixels: CGImage, policy: PhotoMetadataPolicy = .remove,
                       metadata: SourcePhotoMetadata? = nil, quality: Double = 0.98) throws -> Self {
        guard policy != .keep || metadata != nil else { throw Failure.metadataUnavailable }
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(data: nil, width: pixels.width, height: pixels.height,
                                      bitsPerComponent: 8, bytesPerRow: 0, space: space,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { throw Failure.invalidImage }
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: pixels.width, height: pixels.height))
        context.draw(pixels, in: CGRect(x: 0, y: 0, width: pixels.width, height: pixels.height))
        guard let image = context.makeImage() else { throw Failure.invalidImage }
        let bytes = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(bytes, "public.jpeg" as CFString, 1, nil) else { throw Failure.encodingFailed }
        let retained = policy == .keep ? metadata : nil
        let properties: [CFString: Any]
        if let retained {
            guard let encodedProperties = retained.destinationProperties(width: image.width, height: image.height) else {
                throw Failure.metadataUnavailable
            }
            properties = encodedProperties
        } else {
            properties = [:]
        }
        let outputProperties = properties.merging([
            kCGImageDestinationLossyCompressionQuality: quality,
            kCGImageDestinationEmbedThumbnail: false
        ]) { _, new in new }
        if let xmp = retained?.xmp {
            guard let sourceMetadata = CGImageMetadataCreateFromXMPData(xmp as CFData) else { throw Failure.metadataUnavailable }
            CGImageDestinationAddImageAndMetadata(destination, image, sourceMetadata, outputProperties as CFDictionary)
        } else {
            CGImageDestinationAddImage(destination, image, outputProperties as CFDictionary)
        }
        guard CGImageDestinationFinalize(destination) else { throw Failure.encodingFailed }
        return Self(data: bytes as Data, width: image.width, height: image.height, metadataPolicy: policy)
    }

    /// Sanitizes gallery imports/downloads and normalizes every EXIF orientation.
    static func processing(_ data: Data, policy: PhotoMetadataPolicy = .remove, quality: Double = 0.98) throws -> Self {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetStatus(source) == .statusComplete,
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int,
              width > 0, height > 0,
              let pixels = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: max(width, height),
                kCGImageSourceShouldCacheImmediately: true
              ] as CFDictionary) else { throw Failure.invalidImage }
        let metadata: SourcePhotoMetadata?
        if policy == .keep {
            metadata = try SourcePhotoMetadata.capture(data)
        } else { metadata = nil }
        return try encode(pixels, policy: policy, metadata: metadata, quality: quality)
    }
}

