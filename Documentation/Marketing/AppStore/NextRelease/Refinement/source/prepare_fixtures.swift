import Foundation
import ImageIO
import UniformTypeIdentifiers
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let base = root.appendingPathComponent("Documentation/Marketing/AppStore/NextRelease/Refinement/source")
for name in ["cafe", "coast", "card", "night"] {
    let source = CGImageSourceCreateWithURL(base.appendingPathComponent(name + ".png") as CFURL, nil)!
    let image = CGImageSourceCreateImageAtIndex(source, 0, nil)!
    let path = root.appendingPathComponent("Tests/PhotoVeilUITests/Fixtures/marketing-\(name).jpg")
    let dest = CGImageDestinationCreateWithURL(path as CFURL, UTType.jpeg.identifier as CFString, 1, nil)!
    var properties: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: 0.97]
    if name == "coast" {
        // Fictional equator/prime-meridian placeholder; not the photographed place.
        properties[kCGImagePropertyGPSDictionary] = [kCGImagePropertyGPSLatitude: 0.0, kCGImagePropertyGPSLatitudeRef: "N", kCGImagePropertyGPSLongitude: 0.0, kCGImagePropertyGPSLongitudeRef: "E"]
    }
    CGImageDestinationAddImage(dest, image, properties as CFDictionary)
    precondition(CGImageDestinationFinalize(dest))
}
