import AppKit

/// The menu bar glyph: a fuel pump whose body fills from the bottom with the fuel left. Drawn in code so the
/// level can move; a template image in the normal case so it matches the menu bar, tinted when a limit runs
/// short.
enum FuelGlyph {
    /// - Parameters:
    ///   - fuelLeft: 0 (empty) to 1 (full), or nil for no reading yet (body drawn empty).
    ///   - tint: a color for warnings; nil draws a template image.
    static func image(fuelLeft: Double?, tint: NSColor?, size: CGFloat = 18) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let scale = rect.width / 18
            func point(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
                NSPoint(x: rect.minX + x * scale, y: rect.minY + y * scale)
            }
            let color = tint ?? .black
            color.setStroke()
            color.setFill()

            // The pump body, outlined, with the fuel level filled inside it.
            let body = NSRect(x: rect.minX + 2.8 * scale, y: rect.minY + 3.2 * scale,
                              width: 8.4 * scale, height: 12 * scale)
            let outline = NSBezierPath(roundedRect: body, xRadius: 1.8 * scale, yRadius: 1.8 * scale)
            outline.lineWidth = 1.4 * scale
            outline.stroke()
            if let fuelLeft, fuelLeft > 0 {
                let inner = body.insetBy(dx: 1.5 * scale, dy: 1.5 * scale)
                let level = NSRect(x: inner.minX, y: inner.minY,
                                   width: inner.width, height: inner.height * min(fuelLeft, 1))
                NSBezierPath(roundedRect: level, xRadius: 0.6 * scale, yRadius: 0.6 * scale).fill()
            }

            // The base.
            NSBezierPath(roundedRect: NSRect(x: rect.minX + 1.4 * scale, y: rect.minY + 1.2 * scale,
                                             width: 11.2 * scale, height: 1.5 * scale),
                         xRadius: 0.75 * scale, yRadius: 0.75 * scale).fill()

            // The hose and nozzle.
            let hose = NSBezierPath()
            hose.move(to: point(11.2, 12))
            hose.line(to: point(13.2, 12))
            hose.curve(to: point(14.6, 10.6), controlPoint1: point(14, 12), controlPoint2: point(14.6, 11.4))
            hose.line(to: point(14.6, 6))
            hose.curve(to: point(16.2, 6), controlPoint1: point(14.6, 4.9), controlPoint2: point(16.2, 4.9))
            hose.line(to: point(16.2, 12.4))
            hose.line(to: point(14.6, 14.4))
            hose.lineWidth = 1.3 * scale
            hose.lineCapStyle = .round
            hose.lineJoinStyle = .round
            hose.stroke()
            return true
        }
        image.isTemplate = tint == nil
        image.accessibilityDescription = "Fuel Gauge"
        return image
    }
}
