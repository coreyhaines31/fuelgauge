import AppKit

/// The menu bar glyph: the Brushed fuel meter, its needle showing the fuel left. Drawn in code so the needle can
/// move; the geometry matches `glyphs/fuel` from mac-app-kit (`Scripts/glyphs/glyphs.mjs`, `meter(1.75, 3.5, 14.5,
/// 11, value, [-48, -26])`). A template image in the normal case so it matches the menu bar, tinted when a limit
/// runs short.
enum FuelGlyph {
    /// Half the needle's sweep, in degrees either side of straight up.
    private static let sweep = 48.0

    /// - Parameters:
    ///   - fuelLeft: 0 (empty) to 1 (full), or nil for no reading yet (needle rests at E).
    ///   - tint: a color for warnings; nil draws a template image.
    static func image(fuelLeft: Double?, tint: NSColor?, size: CGFloat = 18) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size), flipped: true) { rect in
            let scale = rect.width / 18
            let color = tint ?? .black
            color.setStroke()
            color.setFill()

            // Design units are the 18 pt SVG's, y down.
            func point(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
                NSPoint(x: rect.minX + x * scale, y: rect.minY + y * scale)
            }
            // The needle turns about a pivot near the bottom of the case; 0 degrees is straight up, turning clockwise.
            let pivot = point(9, 12.9), radius: CGFloat = 7.4
            func polar(_ length: CGFloat, _ degrees: Double) -> NSPoint {
                let angle = (degrees - 90) * .pi / 180
                return NSPoint(x: pivot.x + length * scale * CGFloat(cos(angle)),
                               y: pivot.y + length * scale * CGFloat(sin(angle)))
            }
            func arc(from start: Double, to end: Double, width: CGFloat) {
                let path = NSBezierPath()
                path.appendArc(withCenter: pivot, radius: radius * scale,
                               startAngle: start - 90, endAngle: end - 90, clockwise: false)
                path.lineWidth = width * scale
                path.stroke()
            }

            // The case.
            let frame = NSRect(x: rect.minX + 1.75 * scale, y: rect.minY + 3.5 * scale,
                               width: 14.5 * scale, height: 11 * scale)
            let body = NSBezierPath(roundedRect: frame, xRadius: 1.8 * scale, yRadius: 1.8 * scale)
            body.lineWidth = 1.5 * scale
            body.stroke()

            // The scale and the heavier empty zone at its left end.
            arc(from: -sweep, to: sweep, width: 1)
            arc(from: -sweep, to: -26, width: 2.4)

            // The needle and its pivot.
            let value = min(max(fuelLeft ?? 0, 0), 1)
            let needle = NSBezierPath()
            needle.move(to: pivot)
            needle.line(to: polar(radius + 0.4, -sweep + value * 2 * sweep))
            needle.lineWidth = 1.4 * scale
            needle.lineCapStyle = .round
            needle.stroke()
            let dot = 1.19 * scale
            NSBezierPath(ovalIn: NSRect(x: pivot.x - dot, y: pivot.y - dot, width: dot * 2, height: dot * 2)).fill()
            return true
        }
        image.isTemplate = tint == nil
        image.accessibilityDescription = "Fuel Gauge"
        return image
    }
}
