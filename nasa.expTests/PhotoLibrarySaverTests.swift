import ImageIO
import UIKit
import XCTest
@testable import nasa_exp

final class PhotoLibrarySaverTests: XCTestCase {
    func test_jpegData_embedsTitleCaptionAndCreditMetadata() throws {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }

        let data = try PhotoLibrarySaver.jpegData(
            from: image,
            title: "Nebula",
            caption: "Nebula · APOD 13 de marzo de 2026 · Crédito: Jane Doe",
            credit: "Jane Doe"
        )

        let source = try XCTUnwrap(CGImageSourceCreateWithData(data as CFData, nil))
        let properties = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
        let iptc = try XCTUnwrap(properties[kCGImagePropertyIPTCDictionary] as? [CFString: Any])
        let tiff = try XCTUnwrap(properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any])

        XCTAssertEqual(CGImageSourceGetType(source) as String?, "public.jpeg")
        XCTAssertEqual(iptc[kCGImagePropertyIPTCObjectName] as? String, "Nebula")
        XCTAssertEqual(iptc[kCGImagePropertyIPTCCaptionAbstract] as? String, "Nebula · APOD 13 de marzo de 2026 · Crédito: Jane Doe")
        XCTAssertEqual(iptc[kCGImagePropertyIPTCCopyrightNotice] as? String, "Jane Doe")
        XCTAssertEqual(tiff[kCGImagePropertyTIFFCopyright] as? String, "Jane Doe")
    }
}
