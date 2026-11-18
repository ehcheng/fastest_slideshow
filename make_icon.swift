// Regenerate AppIcon.icns:  swift make_icon.swift && iconutil -c icns AppIcon.iconset
import AppKit

func render(_ px: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let g = NSGraphicsContext(bitmapImageRep: rep)!.cgContext
    g.scaleBy(x: CGFloat(px) / 1024, y: CGFloat(px) / 1024)  // design on a 1024 canvas
    let cyan = CGColor(srgbRed: 0.40, green: 0.92, blue: 1.0, alpha: 1)

    // Dark rounded body, standard macOS icon proportions.
    g.saveGState()
    g.addPath(CGPath(roundedRect: CGRect(x: 100, y: 100, width: 824, height: 824), cornerWidth: 185, cornerHeight: 185, transform: nil))
    g.clip()
    let colors = [CGColor(srgbRed: 0.05, green: 0.16, blue: 0.24, alpha: 1), CGColor(srgbRed: 0.01, green: 0.04, blue: 0.07, alpha: 1)] as CFArray
    g.drawLinearGradient(CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors, locations: nil)!,
                         start: CGPoint(x: 0, y: 924), end: CGPoint(x: 0, y: 100), options: [])
    g.restoreGState()

    g.setLineCap(.round)
    g.setLineJoin(.round)
    func frame(_ r: CGRect, alpha: CGFloat, glow: CGFloat) {
        g.setShadow(offset: .zero, blur: glow, color: cyan)
        g.setStrokeColor(cyan.copy(alpha: alpha)!)
        g.setLineWidth(30)
        g.addPath(CGPath(roundedRect: r, cornerWidth: 44, cornerHeight: 44, transform: nil))
        g.strokePath()
    }
    // A slide behind a slide, then a fast-forward mark.
    frame(CGRect(x: 300, y: 370, width: 500, height: 370), alpha: 0.35, glow: 0)
    g.setFillColor(CGColor(srgbRed: 0.02, green: 0.07, blue: 0.11, alpha: 1))
    g.fill(CGRect(x: 224, y: 284, width: 500, height: 370))
    frame(CGRect(x: 224, y: 284, width: 500, height: 370), alpha: 1, glow: 36)
    g.setLineWidth(46)
    for x in [384.0, 494.0] {
        g.move(to: CGPoint(x: x, y: 549))
        g.addLine(to: CGPoint(x: x + 80, y: 469))
        g.addLine(to: CGPoint(x: x, y: 389))
    }
    g.strokePath()
    return rep.representation(using: .png, properties: [:])!
}

let dir = URL(fileURLWithPath: "AppIcon.iconset")
try! FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
// Largest variant is 256 px (Retina Dock size). 512 and 1024 px would be 80% of the app's download.
for (name, px) in [("16x16", 16), ("16x16@2x", 32), ("32x32", 32), ("32x32@2x", 64), ("128x128", 128),
                   ("128x128@2x", 256)] {
    try! render(px).write(to: dir.appendingPathComponent("icon_\(name).png"))
}
