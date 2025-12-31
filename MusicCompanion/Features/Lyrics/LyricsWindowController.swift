import AppKit
import Combine
import SwiftUI

@MainActor
final class LyricsWindowController {
    private var window: NSPanel?
    private var viewModel: LyricsViewModel?
    private var windowDelegate: WindowDelegate?
    private var cancellables = Set<AnyCancellable>()

    private let windowWidth: CGFloat = 320
    private let windowHeight: CGFloat = 500

    init() {
        setupWindow()
        subscribeToSettings()
    }

    // MARK: - Setup

    private func setupWindow() {
        viewModel = LyricsViewModel()

        guard let viewModel else { return }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight),
            styleMask: [.titled, .closable, .resizable, .utilityWindow, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.title = "Lyrics"
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.backgroundColor = .clear

        // Set minimum size
        panel.minSize = NSSize(width: 280, height: 300)

        // Position in bottom right of screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.maxX - windowWidth - 20
            let y = screenFrame.minY + 20
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        let hostingView = NSHostingView(rootView: LyricsView(viewModel: viewModel))
        panel.contentView = hostingView

        // Handle window close - store delegate as strong reference
        let delegate = WindowDelegate { [weak self] in
            self?.handleWindowClose()
        }
        self.windowDelegate = delegate
        panel.delegate = delegate

        self.window = panel
    }

    private func subscribeToSettings() {
        AppState.shared.$showLyrics
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
        AppState.shared.showLyrics = false
    }

    // MARK: - Public Methods

    func show() {
        window?.orderFront(nil)
        AppState.shared.showLyrics = true
    }

    func hide() {
        window?.orderOut(nil)
        AppState.shared.showLyrics = false
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

private class WindowDelegate: NSObject, NSWindowDelegate {
    private let onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}
