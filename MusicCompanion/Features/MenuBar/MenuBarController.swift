import AppKit
import Combine
import SwiftUI

final class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: Any?
    private var cancellables = Set<AnyCancellable>()

    // Marquee components
    private var statusItemView: MenuBarStatusItemView?
    private var useMarquee: Bool = false
    private var marqueeWidth: CGFloat = 200

    // Default icon for when no artwork is available
    private let defaultIcon = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Music Companion")

    override init() {
        super.init()
        setupStatusItem()
        setupPopover()
        setupEventMonitor()
        subscribeToTrackUpdates()
        subscribeToSettings()
    }

    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    // MARK: - Setup

    private func setupStatusItem() {
        // Start with variable length, will switch to fixed if marquee is enabled
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else { return }

        button.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Music Companion")
        button.action = #selector(togglePopover)
        button.target = self
    }

    private func setupMarqueeView() {
        guard let statusItem else { return }

        // Remove existing view if any
        statusItemView?.removeFromSuperview()

        // Create custom view for marquee mode
        statusItemView = MenuBarStatusItemView(
            maxWidth: marqueeWidth,
            target: self,
            action: #selector(togglePopover)
        )

        // Set fixed length and custom view
        statusItem.length = marqueeWidth + 30 // Extra space for icon and padding
        statusItem.button?.subviews.forEach { $0.removeFromSuperview() }

        if let button = statusItem.button, let view = statusItemView {
            view.frame = button.bounds
            view.autoresizingMask = [.width, .height]
            button.addSubview(view)
            button.title = ""
            button.image = nil
        }
    }

    private func setupStandardView() {
        guard let statusItem else { return }

        // Remove marquee view if present
        statusItemView?.removeFromSuperview()
        statusItemView = nil

        // Reset to variable length with standard button
        statusItem.length = NSStatusItem.variableLength

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Music Companion")
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 280, height: 360)
        popover?.behavior = .transient
        popover?.animates = true
        popover?.contentViewController = NSHostingController(rootView: MenuBarPopoverView())
    }

    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if self?.popover?.isShown == true {
                self?.closePopover()
            }
        }
    }

    private func subscribeToTrackUpdates() {
        Task { @MainActor in
            AppState.shared.$currentTrack
                .receive(on: DispatchQueue.main)
                .sink { [weak self] track in
                    self?.updateStatusItemTitle(with: track)
                }
                .store(in: &cancellables)
        }
    }

    private func subscribeToSettings() {
        Task { @MainActor in
            AppState.shared.$menuBarSettings
                .receive(on: DispatchQueue.main)
                .sink { [weak self] settings in
                    self?.updateMenuBarMode(settings: settings)
                }
                .store(in: &cancellables)
        }
    }

    @MainActor
    private func updateMenuBarMode(settings: MenuBarSettings) {
        let shouldUseMarquee = settings.useFixedWidth
        marqueeWidth = settings.fixedWidth

        if shouldUseMarquee != useMarquee {
            useMarquee = shouldUseMarquee

            if useMarquee {
                setupMarqueeView()
            } else {
                setupStandardView()
            }

            // Re-apply current track
            updateStatusItemTitle(with: AppState.shared.currentTrack)
        } else if useMarquee {
            // Update width if changed
            statusItemView?.updateMaxWidth(marqueeWidth)
            statusItem?.length = marqueeWidth + 30
        }
    }

    private func updateStatusItemTitle(with track: Track?) {
        // Create artwork image for menu bar (18x18 with rounded corners)
        let artworkImage = createMenuBarArtwork(from: track?.artworkData)

        if useMarquee {
            if let track {
                statusItemView?.updateContent(title: track.title, artist: track.artist, artwork: artworkImage)
            } else {
                statusItemView?.updateContent(title: nil, artist: nil, artwork: nil)
            }
        } else {
            guard let button = statusItem?.button else { return }

            button.image = artworkImage ?? defaultIcon
            if let track {
                button.title = " \(track.title) — \(track.artist)"
            } else {
                button.title = ""
            }
        }
    }

    private func createMenuBarArtwork(from data: Data?) -> NSImage? {
        guard let data, let originalImage = NSImage(data: data) else { return nil }

        let size: CGFloat = 18
        let cornerRadius: CGFloat = 4

        let newImage = NSImage(size: NSSize(width: size, height: size))
        newImage.lockFocus()

        let rect = NSRect(x: 0, y: 0, width: size, height: size)
        let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
        path.addClip()

        originalImage.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)

        newImage.unlockFocus()
        newImage.isTemplate = false

        return newImage
    }

    // MARK: - Actions

    @objc private func togglePopover() {
        if popover?.isShown == true {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem?.button else { return }
        popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover?.contentViewController?.view.window?.makeKey()
    }

    private func closePopover() {
        popover?.performClose(nil)
    }
}

// MARK: - Menu Bar Status Item View

/// Custom view for the menu bar status item that supports marquee scrolling and theme changes
final class MenuBarStatusItemView: NSView {
    private let iconView: NSImageView = {
        let imageView = NSImageView()
        imageView.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Music Companion")
        imageView.contentTintColor = .labelColor
        imageView.symbolConfiguration = .init(pointSize: 13, weight: .medium)
        imageView.wantsLayer = true
        imageView.layer?.cornerRadius = 4
        imageView.layer?.masksToBounds = true
        return imageView
    }()

    private let defaultIcon = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Music Companion")
    private var hasArtwork = false

    private let marqueeView: MarqueeView
    private weak var target: AnyObject?
    private var action: Selector?
    private var isHighlighted = false

    init(maxWidth: CGFloat, target: AnyObject?, action: Selector?) {
        self.marqueeView = MarqueeView.forMenuBar(maxWidth: maxWidth)
        self.target = target
        self.action = action
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        wantsLayer = true

        addSubview(iconView)
        addSubview(marqueeView)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        marqueeView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 16),
            iconView.heightAnchor.constraint(equalToConstant: 16),

            marqueeView.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 6),
            marqueeView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            marqueeView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        updateColors()
    }

    // MARK: - Theme Support

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateColors()
    }

    private func updateColors() {
        // Only tint the icon when using default icon (no artwork)
        if !hasArtwork {
            iconView.contentTintColor = isHighlighted ? .selectedMenuItemTextColor : .labelColor
        }
    }

    // MARK: - Content

    func updateContent(title: String?, artist: String?, artwork: NSImage?) {
        if let title, let artist {
            marqueeView.text = "\(title) — \(artist)"
        } else if let title {
            marqueeView.text = title
        } else {
            marqueeView.text = ""
        }

        // Update artwork
        if let artwork {
            hasArtwork = true
            iconView.image = artwork
            iconView.contentTintColor = nil // Don't tint artwork
        } else {
            hasArtwork = false
            iconView.image = defaultIcon
            updateColors()
        }
    }

    func updateMaxWidth(_ width: CGFloat) {
        marqueeView.maxWidth = width
    }

    // MARK: - Mouse Handling

    override func mouseDown(with event: NSEvent) {
        isHighlighted = true
        updateColors()

        if let target, let action {
            NSApp.sendAction(action, to: target, from: self)
        }

        // Reset highlight after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.isHighlighted = false
            self?.updateColors()
        }
    }

    override func mouseEntered(with event: NSEvent) {
        // Could add hover effect here if desired
    }

    override func mouseExited(with event: NSEvent) {
        isHighlighted = false
        updateColors()
    }
}
