#if canImport(UIKit) && !os(watchOS)
import UIKit

/// Derives a brand accent color from a country's flag emoji — the dominant
/// non-white, non-grey color of the flag — split into a light- and dark-mode
/// variant tuned for legibility. Results are cached per emoji. Used when the
/// user picks a favorite team; the resolved RGB is then persisted in
/// `BrandColorStore`, so this runs only at selection time.
public enum FlagPalette {
    // Accessed from the main actor (favorite selection / picker rows); the
    // unchecked mutable static just memoizes deterministic results.
    nonisolated(unsafe) private static var cache: [String: (light: BrandColorStore.RGB, dark: BrandColorStore.RGB)] = [:]

    public static func brandColor(forFlagEmoji emoji: String)
        -> (light: BrandColorStore.RGB, dark: BrandColorStore.RGB)? {
        if let hit = cache[emoji] { return hit }
        guard let base = dominantColor(of: emoji) else { return nil }
        let result = variants(from: base)
        cache[emoji] = result
        return result
    }

    /// Renders the emoji to a small bitmap and returns the most common saturated
    /// color, ignoring the white/black/grey areas that don't read as "the flag's
    /// color" (e.g. Japan's white field is dropped, leaving its red).
    private static func dominantColor(of emoji: String) -> UIColor? {
        let side: CGFloat = 32
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false
        let image = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { _ in
            let font = UIFont.systemFont(ofSize: 30)
            let text = emoji as NSString
            let size = text.size(withAttributes: [.font: font])
            text.draw(
                in: CGRect(x: (side - size.width) / 2, y: (side - size.height) / 2,
                           width: size.width, height: size.height),
                withAttributes: [.font: font]
            )
        }
        guard let cgImage = image.cgImage else { return nil }
        return histogramDominant(cgImage)
    }

    private static func histogramDominant(_ image: CGImage) -> UIColor? {
        let width = image.width, height = image.height
        let bytesPerPixel = 4, bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)
        guard let context = CGContext(
            data: &pixels, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: bytesPerRow, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Bucket saturated pixels into a coarse 8×8×8 cube and accumulate each
        // bucket's colour sum, then take the most populous bucket's average.
        var buckets: [Int: (count: Int, r: Double, g: Double, b: Double)] = [:]
        for i in stride(from: 0, to: pixels.count, by: bytesPerPixel) {
            let alpha = Double(pixels[i + 3]) / 255
            guard alpha > 0.5 else { continue }
            let r = Double(pixels[i]) / 255, g = Double(pixels[i + 1]) / 255, b = Double(pixels[i + 2]) / 255
            let high = max(r, g, b), low = min(r, g, b)
            if low > 0.82 { continue }          // near-white
            if high < 0.15 { continue }         // near-black
            if high - low < 0.12 { continue }   // grey / unsaturated
            let key = (Int(r * 7) << 6) | (Int(g * 7) << 3) | Int(b * 7)
            var bucket = buckets[key] ?? (0, 0, 0, 0)
            bucket.count += 1; bucket.r += r; bucket.g += g; bucket.b += b
            buckets[key] = bucket
        }
        guard let best = buckets.max(by: { $0.value.count < $1.value.count })?.value, best.count > 0
        else { return nil }
        return UIColor(red: best.r / Double(best.count), green: best.g / Double(best.count),
                       blue: best.b / Double(best.count), alpha: 1)
    }

    /// Turns the raw dominant colour into a saturated, legible accent: a slightly
    /// deeper light-mode variant and a brighter dark-mode variant.
    private static func variants(from base: UIColor)
        -> (light: BrandColorStore.RGB, dark: BrandColorStore.RGB) {
        var hue: CGFloat = 0, sat: CGFloat = 0, bri: CGFloat = 0, alpha: CGFloat = 0
        base.getHue(&hue, saturation: &sat, brightness: &bri, alpha: &alpha)
        let saturation = min(1, max(sat, 0.55))
        let light = UIColor(hue: hue, saturation: saturation, brightness: min(bri, 0.78), alpha: 1)
        let dark = UIColor(hue: hue, saturation: max(0.5, saturation * 0.9), brightness: max(bri, 0.82), alpha: 1)
        return (rgb(light), rgb(dark))
    }

    private static func rgb(_ color: UIColor) -> BrandColorStore.RGB {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return BrandColorStore.RGB(red: Double(r), green: Double(g), blue: Double(b))
    }
}
#endif
