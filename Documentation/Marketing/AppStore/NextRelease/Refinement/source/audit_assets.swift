import Foundation
import ImageIO
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let base = root.appendingPathComponent("Documentation/Marketing/AppStore/NextRelease/Refinement")
var results: [[String: Any]] = []
for name in ["01-faces", "02-plates", "03-location", "04-manual", "05-share"] {
    let url = base.appendingPathComponent("editorial-calm/\(name).jpg")
    let source = CGImageSourceCreateWithURL(url as CFURL, nil)!
    let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)! as NSDictionary
    let w = props[kCGImagePropertyPixelWidth] as! Int, h = props[kCGImagePropertyPixelHeight] as! Int
    precondition(w == 1320 && h == 2868)
    precondition(CGImageSourceGetType(source)! as String == "public.jpeg")
    precondition(props[kCGImagePropertyColorModel] as! String == "RGB")
    results.append(["file": name + ".jpg", "width": w, "height": h, "format": "JPEG", "color": "RGB", "alpha": false])
}
let coast = root.appendingPathComponent("Tests/PhotoVeilUITests/Fixtures/marketing-coast.jpg")
let source = CGImageSourceCreateWithURL(coast as CFURL, nil)!
let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)! as NSDictionary
precondition(props[kCGImagePropertyGPSDictionary] != nil)
let report: [String: Any] = ["screenshotCandidates": results, "coastSourceContainsFictionalGPS": true, "gpsValuesLogged": false]
let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
try data.write(to: base.appendingPathComponent("asset-audit.json"))
