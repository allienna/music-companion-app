import AppKit
import Combine
import SwiftUI

@MainActor
final class MiniPlayerController {
    private var window: NSPanel?
    private var viewModel: MiniPlayerViewModel?
    private var windowDelegate: MiniPlayerWindowDelegate?
    private var cancellables = Set<AnyCancellable>()

    private let windowWidth: CGFloat = 280
    private let windowHeight: CGFloat = 100

    init() {
        setupWindow()
        subscribeToSettings()
    }

    // MARK: - Setup

    private func setupWindow() {
        viewModel = MiniPlayerViewModel()

        guard let viewModel else { return }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.title = "Mini Player"
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false // SwiftUI view has its own shadow

        // Position in bottom right of screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.maxX - windowWidth - 20
            let y = screenFrame.minY + 20
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        let hostingView = NSHostingView(rootView: MiniPlayerView(viewModel: viewModel))
        hostingView.frame = NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight)
        panel.contentView = hostingView

        // Handle window close
        let delegate = MiniPlayerWindowDelegate { [weak self] in
            self?.handleWindowClose()
        }
        self.windowDelegate = delegate
        panel.delegate = delegate

        self.window = panel
    }

    private func subscribeToSettings() {
        AppState.shared.$showMiniPlayer
            .receive(on: DispatchQueue.main)
            .sink { [weak self] show in
                self?.updateVisibility(show)
            }
            .store(in: &cancellables)
    }

    // MARK: - Visibility

    private func updateVisibility(_ show: Bool) {
        if show {
            window?.orderFront(nil)
        } else {
            window?.orderOut(nil)
        }
    }

    private func handleWindowClose() {
        AppState.shared.showMiniPlayer = false
    }

    // MARK: - Public Methods

    func show() {
        window?.orderFront(nil)
        AppState.shared.showMiniPlayer = true
    }

    func hide() {
        window?.orderOut(nil)
        AppState.shared.showMiniPlayer = false
    }

    func toggle() {
        if window?.isVisible == true {
            hide()
        } else {
            show()
        }
    }
}

// MARK: - Window Delegate

private class MiniPlayerWindowDelegate: NSObject, NSWindowDelegate {
    private let onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}
