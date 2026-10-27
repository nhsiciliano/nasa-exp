// Native macOS export/preview utility. No third-party dependencies.
// Run from the repository root; commands are documented in README.md.
import Foundation
import CoreGraphics
import CoreText
import ImageIO

let directory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let names = ["3-orbita-final", "3-orbita-dark", "3-orbita-tinted"]

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

func canvas(width: Int, height: Int, alpha: Bool = false) throws -> CGContext {
    guard let context = CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue |
            (alpha ? CGImageAlphaInfo.premultipliedLast.rawValue : CGImageAlphaInfo.noneSkipLast.rawValue)
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
// The final icon is square and opaque; dark/tinted preserve transparency.
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

func label(_ text: String, centerX: CGFloat, y: CGFloat = 28, in context: CGContext) {
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
    context.textPosition = CGPoint(x: centerX - width / 2, y: y)
    CTLineDraw(line, context)
}

func preview(name: String) throws -> CGImage {
    let image = try load(directory.appendingPathComponent(name + ".png"))
    let context = try canvas(width: 440, height: 300)
    let isTransparent = name != "3-orbita-final"
    let colors = (isTransparent ? [
        CGColor(gray: 0, alpha: 1), CGColor(gray: 0, alpha: 1)
    ] : [
        CGColor(srgbRed: 0.025, green: 0.045, blue: 0.095, alpha: 1),
        CGColor(srgbRed: 0.07, green: 0.12, blue: 0.20, alpha: 1)
    ]) as CFArray
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
    if name == "3-orbita-final" {
        try save(context, to: directory.appendingPathComponent(name + "-preview.png"))
    } else {
        label(name == "3-orbita-dark" ? "DARK" : "TINTED", centerX: 220, y: 270, in: context)
    }
    return context.makeImage()!
}

func verify(name: String, preview: Bool) throws {
    let url = directory.appendingPathComponent(name + (preview ? "-preview" : "") + ".png")
    let bytes = [UInt8](try Data(contentsOf: url))
    let image = try load(url)
    let expected = preview ? (name == "3-orbita-dark-tinted" ? (880, 300) : (440, 300)) : (1024, 1024)
    let alpha = !preview && name != "3-orbita-final"
    // IHDR color type 2 = RGB; type 6 = RGBA.
    guard bytes.count > 26,
          Array(bytes.prefix(8)) == [137, 80, 78, 71, 13, 10, 26, 10],
          bytes[24] == 8, bytes[25] == (alpha ? 6 : 2),
          image.width == expected.0, image.height == expected.1 else {
        throw ExportError.invalidPNG(url.path)
    }
    if !preview && name == "3-orbita-final" {
        let context = try canvas(width: 1024, height: 1024, alpha: true)
        context.draw(image, in: CGRect(x: 0, y: 0, width: 1024, height: 1024))
        let pixels = context.data!.assumingMemoryBound(to: UInt8.self)
        for index in [0, 1023, 1023 * 1024, 1024 * 1024 - 1] {
            let offset = index * 4
            guard pixels[offset] == 7, pixels[offset + 1] == 13,
                  pixels[offset + 2] == 31, pixels[offset + 3] == 255 else {
                throw ExportError.invalidPNG("Final background differs from #070D1F")
            }
        }
    }
    if alpha {
        let context = try canvas(width: 1024, height: 1024, alpha: true)
        context.draw(image, in: CGRect(x: 0, y: 0, width: 1024, height: 1024))
        let pixels = context.data!.assumingMemoryBound(to: UInt8.self)
        var transparent = 0
        var opaque = 0
        for index in 0..<(1024 * 1024) {
            let offset = index * 4
            if pixels[offset + 3] == 0 { transparent += 1 }
            if pixels[offset + 3] >= 250 { opaque += 1 }
            if name == "3-orbita-tinted" {
                guard pixels[offset] == pixels[offset + 1],
                      pixels[offset + 1] == pixels[offset + 2] else {
                    throw ExportError.invalidPNG("Tinted is not grayscale")
                }
                if pixels[offset + 3] == 255 && pixels[offset] < 190 {
                    throw ExportError.invalidPNG("Tinted has dark foreground pixels")
                }
            }
        }
        guard transparent > 1024 * 1024 / 2, opaque > 1000,
              pixels[3] == 0, pixels[(1024 * 1024 - 1) * 4 + 3] == 0,
              pixels[(512 * 1024 + 512) * 4 + 3] == 0 else {
            throw ExportError.invalidPNG("Missing transparent exterior/interior")
        }
        print("  Alpha: \(transparent) fully transparent pixels; \(opaque) pixels with alpha ≥250; exterior and center clear")
    }
    print("OK \(url.lastPathComponent): \(image.width)×\(image.height), 8-bit \(alpha ? "RGBA with transparency" : "RGB without alpha")")
}

// Resize the generated transparent artwork once, then derive all appearances
// from the same pixels so shape and alignment cannot drift between variants.
func exportAppearances(source: URL) throws {
    let image = try load(source)
    let rect = CGRect(x: 0, y: 0, width: 1024, height: 1024)
    let dark = try canvas(width: 1024, height: 1024, alpha: true)
    dark.clear(rect)
    dark.draw(image, in: rect)
    try save(dark, to: directory.appendingPathComponent("3-orbita-dark.png"))

    let final = try canvas(width: 1024, height: 1024)
    final.setFillColor(CGColor(srgbRed: 7.0 / 255, green: 13.0 / 255, blue: 31.0 / 255, alpha: 1))
    final.fill(rect)
    final.draw(dark.makeImage()!, in: rect)
    try save(final, to: directory.appendingPathComponent("3-orbita-final.png"))

    let tinted = try canvas(width: 1024, height: 1024, alpha: true)
    tinted.clear(rect)
    tinted.draw(dark.makeImage()!, in: rect)
    let pixels = tinted.data!.assumingMemoryBound(to: UInt8.self)
    for index in 0..<(1024 * 1024) {
        let offset = index * 4
        let alpha = Double(pixels[offset + 3]) / 255
        guard alpha > 0 else { continue }
        let red = Double(pixels[offset]) / alpha
        let green = Double(pixels[offset + 1]) / alpha
        let blue = Double(pixels[offset + 2]) / alpha
        let luminance = min(255, 0.2126 * red + 0.7152 * green + 0.0722 * blue)
        // Compress into light gray → white, retaining exact source alpha.
        let value = UInt8(max(0, min(255, ((190 + 65 * luminance / 255) * alpha).rounded())))
        pixels[offset] = value
        pixels[offset + 1] = value
        pixels[offset + 2] = value
    }
    try save(tinted, to: directory.appendingPathComponent("3-orbita-tinted.png"))
}

let arguments = CommandLine.arguments
do {
switch arguments.dropFirst().first {
case "measure" where arguments.count == 3:
    let context = try canvas(width: 1024, height: 1024, alpha: true)
    context.clear(CGRect(x: 0, y: 0, width: 1024, height: 1024))
    context.draw(try load(URL(fileURLWithPath: arguments[2])), in: CGRect(x: 0, y: 0, width: 1024, height: 1024))
    let pixels = context.data!.assumingMemoryBound(to: UInt8.self)
    var clear = 0, solid = 0, maximum = 0
    for index in 0..<(1024 * 1024) {
        let alpha = Int(pixels[index * 4 + 3])
        if alpha == 0 { clear += 1 }
        if alpha == 255 { solid += 1 }
        maximum = max(maximum, alpha)
    }
    print("Alpha: clear=\(clear), solid=\(solid), max=\(maximum), corner=\(pixels[3]), center=\(pixels[(512*1024+512)*4+3])")
    var minX = 1024, maxX = 0, minY = 1024, maxY = 0
    for y in 0..<1024 {
        for x in 0..<1024 {
            let i = (y * 1024 + x) * 4
            let r = Int(pixels[i]), g = Int(pixels[i + 1]), b = Int(pixels[i + 2])
            if r > 180 && g > 140 && r > b + 25 && pixels[i + 3] >= 250 {
                minX = min(minX, x); maxX = max(maxX, x)
                minY = min(minY, y); maxY = max(maxY, y)
            }
        }
    }
    print("Amber bbox: \(minX),\(minY)–\(maxX),\(maxY), span \(maxX-minX+1)×\(maxY-minY+1)")
    for y in [450, 512, 600] {
        var spans: [String] = [], start: Int? = nil
        for x in 0...1024 {
            let i = (y * 1024 + min(x, 1023)) * 4
            let isBlue = x < 1024 && pixels[i + 3] >= 250 && pixels[i + 2] > 100 && pixels[i + 1] > 55 && Int(pixels[i + 2]) > Int(pixels[i]) + 35
            if isBlue && start == nil { start = x }
            if !isBlue, let left = start { spans.append("\(left)–\(x-1) (\(x-left)px)"); start = nil }
        }
        print("Orbit y=\(y): \(spans.joined(separator: ", "))")
    }
case "export" where arguments.count == 3:
    try exportAppearances(source: URL(fileURLWithPath: arguments[2]))
case "preview":
    _ = try preview(name: "3-orbita-final")
    let combined = try canvas(width: 880, height: 300)
    combined.draw(try preview(name: "3-orbita-dark"), in: CGRect(x: 0, y: 0, width: 440, height: 300))
    combined.draw(try preview(name: "3-orbita-tinted"), in: CGRect(x: 440, y: 0, width: 440, height: 300))
    try save(combined, to: directory.appendingPathComponent("3-orbita-dark-tinted-preview.png"))
case "verify":
    for name in names {
        try verify(name: name, preview: false)
    }
    try verify(name: "3-orbita-final", preview: true)
    try verify(name: "3-orbita-dark-tinted", preview: true)
    let dark = try canvas(width: 1024, height: 1024, alpha: true)
    let tinted = try canvas(width: 1024, height: 1024, alpha: true)
    let rect = CGRect(x: 0, y: 0, width: 1024, height: 1024)
    dark.draw(try load(directory.appendingPathComponent("3-orbita-dark.png")), in: rect)
    tinted.draw(try load(directory.appendingPathComponent("3-orbita-tinted.png")), in: rect)
    let darkPixels = dark.data!.assumingMemoryBound(to: UInt8.self)
    let tintedPixels = tinted.data!.assumingMemoryBound(to: UInt8.self)
    for index in 0..<(1024 * 1024) {
        guard darkPixels[index * 4 + 3] == tintedPixels[index * 4 + 3] else {
            throw ExportError.invalidPNG("Dark/tinted alpha mismatch")
        }
    }
    print("OK dark/tinted share identical alpha; tinted is neutral grayscale")
default:
    print("Usage: swift prepare.swift export TRANSPARENT_SOURCE | preview | verify | measure PNG")
}
} catch {
    fputs("Error: \(error)\n", stderr)
    exit(1)
}
