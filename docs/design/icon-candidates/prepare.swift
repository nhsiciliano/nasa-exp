// Native macOS export/preview utility. No third-party dependencies.
// Run from the repository root; commands are documented in README.md.
import Foundation
import CoreGraphics
import CoreText
import ImageIO

let directory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let names = ["1-horizonte", "2-ocular", "3-orbita"]

enum ExportError: Error {
    case invalidImage(String)
    case contextCreation
    case writeFailed(String)
    case invalidPNG(String)
}

func load(_ url: URL) throws -> CGImage {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        throw ExportError.invalidImage(url.path)
    }
    return image
}

func canvas(width: Int, height: Int) throws -> CGContext {
    guard let context = CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    ) else {
        throw ExportError.contextCreation
    }
    context.interpolationQuality = .high
    return context
}

func save(_ context: CGContext, to url: URL) throws {
    guard let image = context.makeImage(),
          let destination = CGImageDestinationCreateWithURL(
              url as CFURL, "public.png" as CFString, 1, nil
          ) else {
        throw ExportError.writeFailed(url.path)
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw ExportError.writeFailed(url.path)
    }
}

// A superellipse approximates the iOS home screen mask for preview only.
// Production icons remain square, opaque and unmasked.
func mask(in rect: CGRect) -> CGPath {
    let path = CGMutablePath()
    for step in 0...360 {
        let angle = Double(step) * .pi / 180
        let cosine = cos(angle)
        let sine = sin(angle)
        let x = copysign(pow(abs(cosine), 0.4), cosine)
        let y = copysign(pow(abs(sine), 0.4), sine)
        let point = CGPoint(
            x: rect.midX + x * rect.width / 2,
            y: rect.midY + y * rect.height / 2
        )
        if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
    }
    path.closeSubpath()
    return path
}

func label(_ text: String, centerX: CGFloat, in context: CGContext) {
    let attributes: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key(kCTFontAttributeName as String):
            CTFontCreateWithName("HelveticaNeue" as CFString, 12, nil),
        NSAttributedString.Key(kCTForegroundColorAttributeName as String):
            CGColor(srgbRed: 0.66, green: 0.72, blue: 0.81, alpha: 1)
    ]
    let line = CTLineCreateWithAttributedString(
        NSAttributedString(string: text, attributes: attributes)
    )
    let width = CTLineGetTypographicBounds(line, nil, nil, nil)
    context.textPosition = CGPoint(x: centerX - width / 2, y: 28)
    CTLineDraw(line, context)
}

func preview(name: String) throws {
    let image = try load(directory.appendingPathComponent(name + ".png"))
    let context = try canvas(width: 440, height: 300)
    let colors = [
        CGColor(srgbRed: 0.025, green: 0.045, blue: 0.095, alpha: 1),
        CGColor(srgbRed: 0.07, green: 0.12, blue: 0.20, alpha: 1)
    ] as CFArray
    let gradient = CGGradient(
        colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
        colors: colors, locations: [0, 1]
    )!
    context.drawLinearGradient(
        gradient, start: CGPoint(x: 0, y: 300),
        end: CGPoint(x: 440, y: 0), options: []
    )
    for (x, y, size) in [(60, 120, 60), (200, 60, 180)] {
        let rect = CGRect(x: x, y: y, width: size, height: size)
        context.saveGState()
        context.addPath(mask(in: rect))
        context.clip()
        context.draw(image, in: rect)
        context.restoreGState()
        label("\(size) × \(size) px", centerX: rect.midX, in: context)
    }
    try save(context, to: directory.appendingPathComponent(name + "-preview.png"))
}

func verify(name: String, preview: Bool) throws {
    let url = directory.appendingPathComponent(name + (preview ? "-preview" : "") + ".png")
    let bytes = [UInt8](try Data(contentsOf: url))
    let image = try load(url)
    let expected = preview ? (440, 300) : (1024, 1024)
    // PNG IHDR color type 2 = truecolor RGB with no alpha channel.
    guard bytes.count > 26,
          Array(bytes.prefix(8)) == [137, 80, 78, 71, 13, 10, 26, 10],
          bytes[24] == 8, bytes[25] == 2,
          image.width == expected.0, image.height == expected.1 else {
        throw ExportError.invalidPNG(url.path)
    }
    print("OK \(url.lastPathComponent): \(image.width)×\(image.height), 8-bit RGB, no alpha")
}

let arguments = CommandLine.arguments
switch arguments.dropFirst().first {
case "export" where arguments.count == 4:
    let image = try load(URL(fileURLWithPath: arguments[2]))
    let context = try canvas(width: 1024, height: 1024)
    context.setFillColor(CGColor(srgbRed: 7 / 255, green: 13 / 255, blue: 31 / 255, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: 1024, height: 1024))
    context.draw(image, in: CGRect(x: 0, y: 0, width: 1024, height: 1024))
    try save(context, to: URL(fileURLWithPath: arguments[3]))
case "preview":
    for name in names { try preview(name: name) }
case "verify":
    for name in names {
        try verify(name: name, preview: false)
        try verify(name: name, preview: true)
    }
default:
    print("Usage: swift prepare.swift export SOURCE DESTINATION | preview | verify")
}
