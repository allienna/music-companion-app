import AppKit
import Combine
import SwiftUI

final class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: Any?
    private var cancellables = Set<AnyCancellable>()

    // Fixed width mode
    private var useFixedWidth: Bool = false
    private var fixedWidth: CGFloat = 200

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

    private func setupFixedWidthView() {
        guard let statusItem else { return }

        // Use fixed length with standard button
        statusItem.length = fixedWidth + 30

        if let button = statusItem.button {
            button.imagePosition = .imageLeading
            button.image = defaultIcon
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    private func setupVariableWidthView() {
        guard let statusItem else { return }

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
        let shouldUseFixedWidth = settings.useFixedWidth
        fixedWidth = settings.fixedWidth

        if shouldUseFixedWidth != useFixedWidth {
            useFixedWidth = shouldUseFixedWidth

            if useFixedWidth {
                setupFixedWidthView()
            } else {
                setupVariableWidthView()
            }

            // Re-apply current track
            updateStatusItemTitle(with: AppState.shared.currentTrack)
        } else if useFixedWidth {
            // Update width if changed
            statusItem?.length = fixedWidth + 30
        }
    }

    private func updateStatusItemTitle(with track: Track?) {
        guard let button = statusItem?.button else { return }

        // Create artwork image for menu bar (18x18 with rounded corners)
        let artworkImage = createMenuBarArtwork(from: track?.artworkData)
        button.image = artworkImage ?? defaultIcon

        if let track {
            button.title = " \(track.title) — \(track.artist)"
        } else {
            button.title = ""
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
        print("🟢 togglePopover called! isShown: \(popover?.isShown ?? false)")
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
