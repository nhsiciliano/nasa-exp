import CoreGraphics
import Foundation
import ImageIO

/// Decodes images straight at the size they are displayed instead of decoding the full resolution
/// first. Widget extensions run with a tight memory budget, and WidgetKit refuses to render images
/// much larger than the widget itself.
nonisolated enum ImageDownsampler {
    /// Decodes `data` and center-crops it so it exactly covers `targetPixelSize` (aspect fill).
    /// Never upscales: smaller images keep their resolution and are only cropped to the aspect ratio.
    static func downsample(_ data: Data, filling targetPixelSize: CGSize) -> CGImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions),
              let imageSize = pixelSize(of: source) else {
            return nil
        }

        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize(forImageSize: imageSize, filling: targetPixelSize)
        ] as CFDictionary

        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else {
            return nil
        }

        let cropRect = centeredCropRect(
            in: CGSize(width: thumbnail.width, height: thumbnail.height),
            aspectRatioOf: targetPixelSize
        )
        return thumbnail.cropping(to: cropRect) ?? thumbnail
    }

    /// Longest side, in pixels, at which an image of `imageSize` still covers `targetSize`.
    static func maxPixelSize(forImageSize imageSize: CGSize, filling targetSize: CGSize) -> Int {
        guard imageSize.width > 0, imageSize.height > 0 else {
            return 0
        }

        let fillScale = max(targetSize.width / imageSize.width, targetSize.height / imageSize.height)
        let scale = min(fillScale, 1)
        return Int((max(imageSize.width, imageSize.height) * scale).rounded(.up))
    }

    /// Largest rect centered in `size` that has the aspect ratio of `target`.
    static func centeredCropRect(in size: CGSize, aspectRatioOf target: CGSize) -> CGRect {
        guard size.width > 0, size.height > 0, target.width > 0, target.height > 0 else {
            return CGRect(origin: .zero, size: size)
        }

        let targetRatio = target.width / target.height
        var cropSize = size
        if size.width / size.height > targetRatio {
            cropSize.width = (size.height * targetRatio).rounded()
        } else {
            cropSize.height = (size.width / targetRatio).rounded()
        }

        return CGRect(
            x: ((size.width - cropSize.width) / 2).rounded(.down),
            y: ((size.height - cropSize.height) / 2).rounded(.down),
            width: cropSize.width,
            height: cropSize.height
        )
    }

    private static func pixelSize(of source: CGImageSource) -> CGSize? {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.doubleValue,
              let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.doubleValue else {
            return nil
        }

        // EXIF orientations 5...8 rotate the image by 90 degrees, which swaps its displayed sides.
        let orientation = (properties[kCGImagePropertyOrientation] as? NSNumber)?.intValue ?? 1
        return (5...8).contains(orientation)
            ? CGSize(width: height, height: width)
            : CGSize(width: width, height: height)
    }
}
