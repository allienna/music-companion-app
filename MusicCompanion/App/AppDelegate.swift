import AppKit
import Combine
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var notchPlayerController: NotchPlayerController?
    private var lyricsWindowController: LyricsWindowController?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupNotchPlayer()
        setupLyricsWindow()
        setupMusicService()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup resources
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Menu bar apps should not terminate when windows close
        false
    }

    // MARK: - Private

    private func setupMenuBar() {
        menuBarController = MenuBarController()
    }

    private func setupNotchPlayer() {
        // Only create notch player on Macs with a notch
        if hasNotch() {
            Task { @MainActor in
                self.notchPlayerController = NotchPlayerController()
            }
        }
    }

    private func hasNotch() -> Bool {
        guard let screen = NSScreen.main else { return false }
        if #available(macOS 12.0, *) {
            return screen.safeAreaInsets.top > 0
        }
        return false
    }

    private func setupLyricsWindow() {
        Task { @MainActor in
            self.lyricsWindowController = LyricsWindowController()
            // Initialize the lyrics service
            _ = LyricsService.shared
        }
    }

    private func setupMusicService() {
        Task {
            await AppState.shared.musicServiceManager.startMonitoring()
        }
    }
}
