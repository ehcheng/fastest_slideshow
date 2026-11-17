// Fastest Slideshow: one-file AppKit image viewer. Build with ./build.sh
import AppKit
import ImageIO
import UniformTypeIdentifiers

// MARK: - Files

func isDir(_ u: URL) -> Bool { (try? u.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true }
func isImage(_ u: URL) -> Bool { UTType(filenameExtension: u.pathExtension)?.conforms(to: .image) ?? false }

/// Images directly inside `dir` (no recursion), in Finder name order.
func imagesIn(_ dir: URL) -> [URL] {
    let items = (try? FileManager.default.contentsOfDirectory(
        at: dir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)) ?? []
    return items.filter(isImage).sorted {
        $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
    }
}

/// One folder: its images. One file: its siblings, starting at that file. Several items: exactly those.
func resolve(_ urls: [URL]) -> (files: [URL], start: Int) {
    if urls.count == 1, let u = urls.first {
        if isDir(u) { return (imagesIn(u), 0) }
        let list = imagesIn(u.deletingLastPathComponent())
        let path = u.standardizedFileURL.path
        return (list, list.firstIndex { $0.standardizedFileURL.path == path } ?? 0)
    }
    return (urls.flatMap { isDir($0) ? imagesIn($0) : (isImage($0) ? [$0] : []) }, 0)
}

/// Decode downsampled to screen size with EXIF orientation applied. Far faster than a full decode.
func decode(_ u: URL, maxPixel: Int) -> CGImage? {
    guard let src = CGImageSourceCreateWithURL(u as CFURL, nil) else { return nil }
    let opts: [CFString: Any] = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: maxPixel,
        kCGImageSourceShouldCacheImmediately: true,
    ]
    return CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary)
}

// MARK: - Metadata

let cyan = NSColor(srgbRed: 0.40, green: 0.92, blue: 1.0, alpha: 1)
let dim = NSColor(srgbRed: 0.55, green: 0.74, blue: 0.82, alpha: 1)
let white = NSColor(white: 0.96, alpha: 1)
func mono(_ size: CGFloat, _ weight: NSFont.Weight = .regular) -> NSFont {
    .monospacedSystemFont(ofSize: size, weight: weight)
}

func fmt(_ v: Any) -> String {
    switch v {
    case let a as [Any]: return a.map(fmt).joined(separator: ", ")
    case let d as Data: return "<\(d.count) bytes>"
    case let n as Double where !(v is String): return String(format: "%g", n)
    default:
        let s = "\(v)"
        return s.count > 300 ? s.prefix(300) + "…" : s
    }
}

/// Flatten nested dictionaries into sorted "Parent.Key" rows.
func rows(_ d: [String: Any], _ prefix: String = "") -> [(String, String)] {
    d.keys.sorted().flatMap { k -> [(String, String)] in
        if let sub = d[k] as? [String: Any] { return rows(sub, prefix + k + ".") }
        return [(prefix + k, fmt(d[k]!))]
    }
}

func metadata(_ u: URL, position: String) -> NSAttributedString {
    let out = NSMutableAttributedString()
    let glow = NSShadow()
    glow.shadowColor = cyan.withAlphaComponent(0.7)
    glow.shadowBlurRadius = 6
    let keyColumn: CGFloat = 158
    let rowStyle = NSMutableParagraphStyle()
    rowStyle.tabStops = [NSTextTab(textAlignment: .left, location: keyColumn)]
    rowStyle.headIndent = keyColumn
    rowStyle.paragraphSpacing = 3
    let headStyle = NSMutableParagraphStyle()
    headStyle.paragraphSpacingBefore = 18
    headStyle.paragraphSpacing = 6

    func add(_ s: String, _ attrs: [NSAttributedString.Key: Any]) {
        out.append(NSAttributedString(string: s, attributes: attrs))
    }
    func section(_ title: String, _ items: [(String, String)]) {
        guard !items.isEmpty else { return }
        add("▍" + title.uppercased() + "\n", [
            .font: mono(11, .bold), .foregroundColor: cyan, .kern: 2.5,
            .shadow: glow, .paragraphStyle: headStyle,
        ])
        for (k, v) in items {
            add(k + "\t", [.font: mono(11), .foregroundColor: dim, .paragraphStyle: rowStyle])
            add(v + "\n", [.font: mono(12), .foregroundColor: white, .paragraphStyle: rowStyle])
        }
    }

    let src = CGImageSourceCreateWithURL(u as CFURL, nil)
    let props = src.flatMap { CGImageSourceCopyPropertiesAtIndex($0, 0, nil) as? [String: Any] } ?? [:]
    let exif = props["{Exif}"] as? [String: Any] ?? [:]
    let tiff = props["{TIFF}"] as? [String: Any] ?? [:]
    let rv = try? u.resourceValues(forKeys: [.fileSizeKey, .creationDateKey, .contentModificationDateKey])
    let size = ByteCountFormatter.string(fromByteCount: Int64(rv?.fileSize ?? 0), countStyle: .file)

    // Heads-up summary: name, position, then the exposure numbers people actually look for.
    add(u.lastPathComponent + "\n", [.font: mono(15, .semibold), .foregroundColor: white])
    var line = [position, size]
    if let w = props["PixelWidth"], let h = props["PixelHeight"] { line.insert("\(fmt(w)) × \(fmt(h))", at: 1) }
    add(line.joined(separator: "  ·  ") + "\n", [.font: mono(11), .foregroundColor: dim])
    let camera = [tiff["Model"], exif["LensModel"]].compactMap { $0 as? String }
    if !camera.isEmpty {
        add("\n" + camera.joined(separator: "  ·  ") + "\n", [.font: mono(12), .foregroundColor: white])
    }
    var hud: [String] = []
    if let f = exif["FocalLength"] as? Double { hud.append(String(format: "%gmm", f)) }
    if let n = exif["FNumber"] as? Double { hud.append(String(format: "ƒ/%g", n)) }
    if let t = exif["ExposureTime"] as? Double, t > 0 {
        hud.append(t < 1 ? "1/\(Int((1 / t).rounded()))s" : String(format: "%gs", t))
    }
    if let iso = (exif["ISOSpeedRatings"] as? [Any])?.first { hud.append("ISO \(iso)") }
    if !hud.isEmpty {
        add(hud.joined(separator: "   ") + "\n", [.font: mono(15, .medium), .foregroundColor: cyan, .shadow: glow])
    }

    var file = [("Path", u.path), ("Size", size)]
    if let t = src.flatMap(CGImageSourceGetType) { file.append(("Type", t as String)) }
    if let d = rv?.creationDate { file.append(("Created", d.formatted(date: .abbreviated, time: .standard))) }
    if let d = rv?.contentModificationDate { file.append(("Modified", d.formatted(date: .abbreviated, time: .standard))) }
    section("File", file)
    section("Image", rows(props.filter { !($0.value is [String: Any]) }))
    for k in props.keys.sorted() {
        if let sub = props[k] as? [String: Any] {
            section(k.trimmingCharacters(in: CharacterSet(charactersIn: "{}")), rows(sub))
        }
    }
    return out
}

// MARK: - App

final class Window: NSWindow {  // borderless windows refuse key status by default
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class App: NSObject, NSApplicationDelegate, NSWindowDelegate {
    let window = Window(contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: true)
    let imageView = NSView()
    let sidebar = NSView()
    let scroll = NSTextView.scrollableTextView()
    var files: [URL] = []
    var index = 0
    var fullScreen = true
    var showInfo = false
    var timer: Timer?
    let cache = NSCache<NSURL, CGImage>()
    let decodeQueue = OperationQueue()
    let slideSeconds = 3.0
    let sidebarWidth: CGFloat = 440

    func applicationDidFinishLaunching(_ note: Notification) {
        cache.countLimit = 8
        decodeQueue.maxConcurrentOperationCount = 2
        buildMenu()
        buildWindow()
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [unowned self] in self.key($0) ? nil : $0 }
        // Command line: FastestSlideshow [--info] <file-or-folder>...
        showInfo = CommandLine.arguments.contains("--info")
        let paths = CommandLine.arguments.dropFirst().filter { !$0.hasPrefix("-") && FileManager.default.fileExists(atPath: $0) }
        if !paths.isEmpty { open(paths.map { URL(fileURLWithPath: $0) }) }
        // Finder delivers open-file events around launch; only prompt if none arrived.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { if self.files.isEmpty { self.openPanel() } }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func application(_ application: NSApplication, open urls: [URL]) { open(urls) }

    func buildMenu() {
        let main = NSMenu()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit Fastest Slideshow", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(withTitle: "Open…", action: #selector(openPanel), keyEquivalent: "o")
        fileMenu.addItem(withTitle: "Close", action: #selector(closeImage), keyEquivalent: "w")
        for menu in [appMenu, fileMenu] {
            let item = NSMenuItem()
            item.submenu = menu
            main.addItem(item)
        }
        NSApp.mainMenu = main
    }

    func buildWindow() {
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.backgroundColor = .black
        window.appearance = NSAppearance(named: .darkAqua)

        let layer = CALayer()  // layer-hosting: we own the contents, so kill the implicit crossfade
        layer.contentsGravity = .resizeAspect
        layer.minificationFilter = .trilinear
        layer.actions = ["contents": NSNull(), "bounds": NSNull(), "position": NSNull()]
        imageView.layer = layer
        imageView.wantsLayer = true

        sidebar.wantsLayer = true
        sidebar.layer?.backgroundColor = NSColor(srgbRed: 0.02, green: 0.05, blue: 0.08, alpha: 1).cgColor
        let edge = NSView(frame: NSRect(x: 0, y: 0, width: 2, height: 0))
        edge.wantsLayer = true
        edge.layer?.backgroundColor = cyan.cgColor
        edge.layer?.shadowColor = cyan.cgColor
        edge.layer?.shadowOpacity = 1
        edge.layer?.shadowRadius = 8
        edge.layer?.shadowOffset = .zero
        edge.layer?.masksToBounds = false
        edge.autoresizingMask = .height
        scroll.frame = NSRect(x: 2, y: 0, width: 0, height: 0)
        scroll.autoresizingMask = [.width, .height]
        scroll.drawsBackground = false
        scroll.scrollerStyle = .overlay
        if let text = scroll.documentView as? NSTextView {
            text.isEditable = false
            text.drawsBackground = false
            text.textContainerInset = NSSize(width: 18, height: 20)
        }
        sidebar.addSubview(scroll)
        sidebar.addSubview(edge)
        window.contentView?.addSubview(imageView)
        window.contentView?.addSubview(sidebar)
    }

    // MARK: Open / close

    @objc func openPanel() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.image]
        NSApp.activate(ignoringOtherApps: true)
        if panel.runModal() == .OK { open(panel.urls) }
    }

    func open(_ urls: [URL]) {
        let found = resolve(urls)
        guard !found.files.isEmpty else { NSSound.beep(); return }
        stopPlaying()
        (files, index) = found
        fullScreen = true
        applyMode(on: NSScreen.main)
        NSApp.activate(ignoringOtherApps: true)
        show()
    }

    @objc func closeImage() { window.close() }

    func windowWillClose(_ note: Notification) {
        stopPlaying()
        decodeQueue.cancelAllOperations()
        files = []
        imageView.layer?.contents = nil
        NSApp.presentationOptions = []
    }

    // MARK: Layout

    func applyMode(on screen: NSScreen?) {
        guard let screen = screen ?? NSScreen.main else { return }
        if fullScreen {
            // Borderless window, not a native full-screen Space: instant, no animation.
            window.styleMask = .borderless
            NSApp.presentationOptions = [.hideMenuBar, .hideDock]
            window.setFrame(screen.frame, display: true)
        } else {
            NSApp.presentationOptions = []
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            let v = screen.visibleFrame
            window.setFrame(v.insetBy(dx: v.width * 0.12, dy: v.height * 0.12), display: true)
        }
        window.makeKeyAndOrderFront(nil)
        layout()
    }

    func windowDidResize(_ note: Notification) { layout() }

    func layout() {
        guard let content = window.contentView else { return }
        var area = content.bounds
        if fullScreen { area.size.height -= window.screen?.safeAreaInsets.top ?? 0 }  // stay clear of the notch
        let side = showInfo ? min(sidebarWidth, area.width / 2) : 0
        sidebar.isHidden = !showInfo
        sidebar.frame = NSRect(x: area.maxX - side, y: 0, width: side, height: area.height)
        imageView.frame = NSRect(x: 0, y: 0, width: area.width - side, height: area.height)
    }

    // MARK: Display

    func show() {
        guard files.indices.contains(index) else { return }
        let url = files[index]
        let position = "\(index + 1) / \(files.count)"
        window.title = "\(url.lastPathComponent)  —  \(position)"
        if showInfo, let text = scroll.documentView as? NSTextView {
            text.textStorage?.setAttributedString(metadata(url, position: position))
            text.scrollToBeginningOfDocument(nil)
        }
        NSCursor.setHiddenUntilMouseMoves(true)

        if let hit = cache.object(forKey: url as NSURL) { imageView.layer?.contents = hit }
        // Drop decodes queued for images already skipped past, then load current plus neighbours.
        decodeQueue.cancelAllOperations()
        let maxPixel = Int(NSScreen.screens.map { max($0.frame.width, $0.frame.height) * $0.backingScaleFactor }.max() ?? 4096)
        for i in [index, index + 1, index - 1] where files.indices.contains(i) {
            let u = files[i]
            if cache.object(forKey: u as NSURL) != nil { continue }
            let op = BlockOperation()
            op.addExecutionBlock { [unowned op, unowned self] in
                if op.isCancelled { return }
                let image = decode(u, maxPixel: maxPixel)
                if let image { self.cache.setObject(image, forKey: u as NSURL) }
                DispatchQueue.main.async {
                    if self.files.indices.contains(self.index), self.files[self.index] == u {
                        self.imageView.layer?.contents = image  // nil (black) if undecodable
                    }
                }
            }
            decodeQueue.addOperation(op)
        }
    }

    func step(_ delta: Int) {
        let next = min(max(index + delta, 0), files.count - 1)
        if next != index { index = next; show() }
    }

    func stopPlaying() { timer?.invalidate(); timer = nil }

    func togglePlaying() {
        if timer != nil { return stopPlaying() }
        timer = Timer.scheduledTimer(withTimeInterval: slideSeconds, repeats: true) { [unowned self] _ in
            if self.index >= self.files.count - 1 { self.stopPlaying() } else { self.step(1) }
        }
    }

    /// Returns true if the key was handled.
    func key(_ e: NSEvent) -> Bool {
        guard e.window === window, !files.isEmpty, !e.modifierFlags.contains(.command) else { return false }
        let jump = e.modifierFlags.intersection([.control, .shift]).isEmpty ? 1 : 10
        switch e.keyCode {
        case 123: step(-jump)  // left
        case 124: step(jump)  // right
        case 53: closeImage()  // escape
        case 49: togglePlaying()  // space
        default:
            switch e.charactersIgnoringModifiers?.lowercased() {
            case "j": step(jump)
            case "k": step(-jump)
            case "f": fullScreen.toggle(); applyMode(on: window.screen)
            case "i": showInfo.toggle(); layout(); show()
            default: return false
            }
        }
        return true
    }
}

// MARK: - Entry

// Headless self-check: FastestSlideshow --check <file-or-folder>
if let i = CommandLine.arguments.firstIndex(of: "--check"), CommandLine.arguments.count > i + 1 {
    let found = resolve([URL(fileURLWithPath: CommandLine.arguments[i + 1])])
    precondition(!found.files.isEmpty, "no images found")
    let url = found.files[found.start]
    guard let image = decode(url, maxPixel: 512) else { fatalError("decode failed: \(url.path)") }
    precondition(max(image.width, image.height) <= 512, "downsample ignored")
    print("\(found.files.count) images, start \(found.start), decoded \(image.width)x\(image.height)")
    print(metadata(url, position: "\(found.start + 1) / \(found.files.count)").string)
    exit(0)
}

let delegate = App()
NSApplication.shared.delegate = delegate
NSApplication.shared.run()
