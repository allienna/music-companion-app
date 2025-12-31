import AppKit
import Combine
import SwiftUI

@MainActor
final class NotchPlayerController {
    private var playerWindow: NSWindow?
    private var hoverWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()

    private var isExpanded = false
    private var hideTimer: Timer?
    private var viewModel: NotchPlayerViewModel?

    // Notch dimensions (MacBook Pro 14"/16")
    private let notchWidth: CGFloat = 200
    private let notchHeight: CGFloat = 38

    // Expanded player dimensions
    private let expandedWidth: CGFloat = 420
    private let expandedHeight: CGFloat = 180

    init() {
        setupViewModel()
        setupHoverWindow()
        setupPlayerWindow()
        subscribeToSettings()
    }

    deinit {
        hideTimer?.invalidate()
    }

    // MARK: - Setup

    private func setupViewModel() {
        viewModel = NotchPlayerViewModel()
    }

    private func setupHoverWindow() {
        guard let screen = NSScreen.main else { return }

        let screenFrame = screen.frame

        // Invisible hover detection area at top center
        let hoverWidth: CGFloat = notchWidth + 100
        let hoverHeight: CGFloat = notchHeight + 10
        let hoverFrame = NSRect(
            x: screenFrame.midX - hoverWidth / 2,
            y: screenFrame.maxY - hoverHeight,
            width: hoverWidth,
            height: hoverHeight
        )

        hoverWindow = NSWindow(
            contentRect: hoverFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        guard let hoverWindow else { return }

        hoverWindow.isOpaque = false
        hoverWindow.backgroundColor = .clear
        hoverWindow.level = .screenSaver
        hoverWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        hoverWindow.hasShadow = false
        hoverWindow.isMovable = false
        hoverWindow.ignoresMouseEvents = false

        let hoverView = NotchHoverView { [weak self] isHovering in
            if isHovering {
                self?.expand()
            }
        }
        hoverWindow.contentView = hoverView
    }

    private func setupPlayerWindow() {
        guard let screen = NSScreen.main, let viewModel else { return }

        let screenFrame = screen.frame

        // Position at top center, accounting for notch
        let playerFrame = NSRect(
            x: screenFrame.midX - expandedWidth / 2,
            y: screenFrame.maxY - notchHeight - expandedHeight,
            width: expandedWidth,
            height: expandedHeight + notchHeight
        )

        playerWindow = NSWindow(
            contentRect: playerFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        guard let playerWindow else { return }

        playerWindow.isOpaque = false
        playerWindow.backgroundColor = .clear
        playerWindow.level = .statusBar
        playerWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        playerWindow.hasShadow = false
        playerWindow.isMovable = false
        playerWindow.ignoresMouseEvents = false
        playerWindow.alphaValue = 0

        let trackingView = NotchPlayerTrackingView(
            onMouseEntered: { [weak self] in
                self?.cancelHideTimer()
            },
            onMouseExited: { [weak self] in
                self?.scheduleCollapse()
            }
        )

        let hostingView = NSHostingView(rootView: NotchPlayerView(viewModel: viewModel, isExpanded: true))
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        trackingView.addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: trackingView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: trackingView.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: trackingView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: trackingView.trailingAnchor),
        ])

        playerWindow.contentView = trackingView
    }

    private func subscribeToSettings() {
        AppState.shared.$showNotchPlayer
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateVisibility()
            }
            .store(in: &cancellables)
    }

    private func updateVisibility() {
        let shouldShow = AppState.shared.showNotchPlayer && hasNotch()

        if shouldShow {
            hoverWindow?.orderFront(nil)
        } else {
            hoverWindow?.orderOut(nil)
            playerWindow?.orderOut(nil)
            isExpanded = false
        }
    }

    private func hasNotch() -> Bool {
        guard let screen = NSScreen.main else { return false }
        if #available(macOS 12.0, *) {
            return screen.safeAreaInsets.top > 0
        }
        return false
    }

    // MARK: - Expansion

    private func expand() {
        guard !isExpanded else { return }
        isExpanded = true

        hideTimer?.invalidate()
        hideTimer = nil

        playerWindow?.orderFront(nil)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            playerWindow?.animator().alphaValue = 1
        }
    }

    private func collapse() {
        guard isExpanded else { return }
        isExpanded = false

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            playerWindow?.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            Task { @MainActor in
                self?.playerWindow?.orderOut(nil)
            }
        }
    }

    private func cancelHideTimer() {
        hideTimer?.invalidate()
        hideTimer = nil
    }

    private func scheduleCollapse() {
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.collapse()
            }
        }
    }
}

// MARK: - Hover Detection View

private class NotchHoverView: NSView {
    private var onHover: (Bool) -> Void
    private var trackingArea: NSTrackingArea?

    init(onHover: @escaping (Bool) -> Void) {
        self.onHover = onHover
        super.init(frame: .zero)
        setupTracking()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupTracking() {
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea!)
    }

    override func mouseEntered(with event: NSEvent) {
        onHover(true)
    }

    override func mouseExited(with event: NSEvent) {
        // Let the player window handle collapse
    }

    override var isFlipped: Bool { true }
}

// MARK: - Player Tracking View

private class NotchPlayerTrackingView: NSView {
    private var onMouseEntered: () -> Void
    private var onMouseExited: () -> Void
    private var trackingArea: NSTrackingArea?

    init(onMouseEntered: @escaping () -> Void, onMouseExited: @escaping () -> Void) {
        self.onMouseEntered = onMouseEntered
        self.onMouseExited = onMouseExited
        super.init(frame: .zero)
        setupTracking()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupTracking() {
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea!)
    }

    override func mouseEntered(with event: NSEvent) {
        onMouseEntered()
    }

    override func mouseExited(with event: NSEvent) {
        onMouseExited()
    }
}
