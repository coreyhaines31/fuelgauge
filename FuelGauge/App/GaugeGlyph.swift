import AppKit

/// The menu bar gauge: an arc from E to F with a needle at the fuel left. Drawn in code so the needle can
/// move; a template image in the normal case so it matches the menu bar, tinted when a limit runs short.
enum GaugeGlyph {
    /// - Parameters:
    ///   - fuelLeft: 0 (empty) to 1 (full), or nil for no reading yet (needle hidden).
    ///   - tint: a color for warnings; nil draws a template image.
    static func image(fuelLeft: Double?, tint: NSColor?, size: CGFloat = 18) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let scale = rect.width / 18
            let center = NSPoint(x: rect.midX, y: rect.minY + 7 * scale)
            let radius = 7.5 * scale
            let color = tint ?? .black
            color.setStroke()
            color.setFill()

            let arc = NSBezierPath()
            arc.appendArc(withCenter: center, radius: radius, startAngle: 200, endAngle: -20, clockwise: true)
            arc.lineWidth = 1.7 * scale
            arc.lineCapStyle = .round
            arc.stroke()

            // The E end, a little heavier, so empty reads at a glance.
            let empty = NSBezierPath()
            empty.appendArc(withCenter: center, radius: radius, startAngle: 200, endAngle: 170, clockwise: true)
            empty.lineWidth = 2.6 * scale
            empty.lineCapStyle = .round
            empty.stroke()

            if let fuelLeft {
                let angle = (200 - 220 * min(max(fuelLeft, 0), 1)) * .pi / 180
                let tip = NSPoint(x: center.x + cos(angle) * radius * 0.82, y: center.y + sin(angle) * radius * 0.82)
                let needle = NSBezierPath()
                needle.move(to: center)
                needle.line(to: tip)
                needle.lineWidth = 1.6 * scale
                needle.lineCapStyle = .round
                needle.stroke()
            }
            NSBezierPath(ovalIn: NSRect(x: center.x - 1.9 * scale, y: center.y - 1.9 * scale,
                                        width: 3.8 * scale, height: 3.8 * scale)).fill()
            return true
        }
        image.isTemplate = tint == nil
        image.accessibilityDescription = "Fuel Gauge"
        return image
    }
}
